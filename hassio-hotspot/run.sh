#!/bin/bash

# SIGTERM-handler this funciton will be executed when the container receives the SIGTERM signal (when stopping)
reset_interfaces(){
    ifdown $INTERFACE
    sleep 1
    ip link set $INTERFACE down
    ip addr flush dev $INTERFACE
}

term_handler(){
    echo "Resseting interfaces"
    reset_interfaces
    echo "Stopping..."
    exit 0
}

# Setup signal handlers
trap 'term_handler' SIGTERM

echo "Starting..."

CONFIG_PATH=/data/options.json

SSID=$(jq --raw-output ".ssid" $CONFIG_PATH)
WPA_PASSPHRASE=$(jq --raw-output ".wpa_passphrase" $CONFIG_PATH)
CHANNEL=$(jq --raw-output ".channel" $CONFIG_PATH)
ADDRESS=$(jq --raw-output ".address" $CONFIG_PATH)
NETMASK=$(jq --raw-output ".netmask" $CONFIG_PATH)
BROADCAST=$(jq --raw-output ".broadcast" $CONFIG_PATH)
INTERFACE=$(jq --raw-output ".interface" $CONFIG_PATH)
INTERNET_IF=$(jq --raw-output ".internet_interface" $CONFIG_PATH)
ALLOW_INTERNET=$(jq --raw-output ".allow_internet" $CONFIG_PATH)
HIDE_SSID=$(jq --raw-output ".hide_ssid" $CONFIG_PATH)

DHCP_SERVER=$(jq --raw-output ".dhcp_enable" $CONFIG_PATH)
DHCP_START=$(jq --raw-output ".dhcp_start" $CONFIG_PATH)
DHCP_END=$(jq --raw-output ".dhcp_end" $CONFIG_PATH)
DHCP_DNS=$(jq --raw-output ".dhcp_dns" $CONFIG_PATH)
DHCP_SUBNET=$(jq --raw-output ".dhcp_subnet" $CONFIG_PATH)
DHCP_ROUTER=$(jq --raw-output ".dhcp_router" $CONFIG_PATH)

DHCPV6_SERVER=$(jq --raw-output ".dhcpv6_enable" $CONFIG_PATH)
DHCPV6_PREFIX=$(jq --raw-output ".dhcpv6_prefix" $CONFIG_PATH)
DHCPV6_START=$(jq --raw-output ".dhcpv6_start" $CONFIG_PATH)
DHCPV6_END=$(jq --raw-output ".dhcpv6_end" $CONFIG_PATH)
DHCPV6_DNS=$(jq --raw-output ".dhcpv6_dns" $CONFIG_PATH)

LEASE_TIME=$(jq --raw-output ".lease_time" $CONFIG_PATH)
STATIC_LEASES=$(jq -r '.static_leases[] | "\(.mac),\(.ip),\(.name)"' $CONFIG_PATH)
STATIC_LEASES_V6=$(jq -r '.static_leases_v6[] | "\(.mac),\(.ipv6),\(.name)"' $CONFIG_PATH)

# Enforces required env variables
required_vars=(SSID WPA_PASSPHRASE CHANNEL ADDRESS NETMASK BROADCAST)
for required_var in "${required_vars[@]}"; do
    if [[ -z ${!required_var} ]]; then
        echo >&2 "Error: $required_var env variable not set."
        exit 1
    fi
done


INTERFACES_AVAILABLE="$(ifconfig -a | grep '^wl' | cut -d ':' -f '1')"
UNKNOWN=true

if [[ -z ${INTERFACE} ]]; then
    echo >&2 "Network interface not set. Please set one of the available:"
    echo >&2 "${INTERFACES_AVAILABLE}"
    exit 1
fi

for OPTION in ${INTERFACES_AVAILABLE}; do
    if [[ ${INTERFACE} == ${OPTION} ]]; then
        UNKNOWN=false
    fi
done

if [[ ${UNKNOWN} == true ]]; then
    echo >&2 "Unknown network interface ${INTERFACE}. Please set one of the available:"
    echo >&2 "${INTERFACES_AVAILABLE}"
    exit 1
fi

echo "Set nmcli managed no"
nmcli dev set ${INTERFACE} managed no

echo "Network interface set to ${INTERFACE}"

# Configure iptables to enable/disable internet
RULE_3="POSTROUTING -o ${INTERNET_IF} -j MASQUERADE"
RULE_4="FORWARD -i ${INTERNET_IF} -o ${INTERFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT"
RULE_5="FORWARD -i ${INTERFACE} -o ${INTERNET_IF} -j ACCEPT"

# IPv6 rules
RULE_6="FORWARD -i ${INTERNET_IF} -o ${INTERFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT"
RULE_7="FORWARD -i ${INTERFACE} -o ${INTERNET_IF} -j ACCEPT"

echo "Deleting iptables"
iptables -v -t nat -D $(echo ${RULE_3}) 2>/dev/null || true
iptables -v -D $(echo ${RULE_4}) 2>/dev/null || true
iptables -v -D $(echo ${RULE_5}) 2>/dev/null || true

echo "Deleting ip6tables"
ip6tables -v -D $(echo ${RULE_6}) 2>/dev/null || true
ip6tables -v -D $(echo ${RULE_7}) 2>/dev/null || true

if test ${ALLOW_INTERNET} = true; then
    echo "Configuring iptables for NAT"
    iptables -v -t nat -A $(echo ${RULE_3})
    iptables -v -A $(echo ${RULE_4})
    iptables -v -A $(echo ${RULE_5})
    
    echo "Configuring ip6tables for IPv6 forwarding"
    ip6tables -v -A $(echo ${RULE_6})
    ip6tables -v -A $(echo ${RULE_7})
fi


# Setup hostapd.conf
HCONFIG="/hostapd.conf"

echo "Setup hostapd ..."
echo "ssid=${SSID}" >> ${HCONFIG}
echo "wpa_passphrase=${WPA_PASSPHRASE}" >> ${HCONFIG}
echo "channel=${CHANNEL}" >> ${HCONFIG}
echo "interface=${INTERFACE}" >> ${HCONFIG}
echo "" >> ${HCONFIG}

if test ${HIDE_SSID} = true; then
    echo "Hidding SSID"
    echo "ignore_broadcast_ssid=1" >> ${HCONFIG}
fi

# Setup interface
IFFILE="/etc/network/interfaces"

echo "Setup interface ..."
echo "" > ${IFFILE}
echo "iface ${INTERFACE} inet static" >> ${IFFILE}
echo "  address ${ADDRESS}" >> ${IFFILE}
echo "  netmask ${NETMASK}" >> ${IFFILE}
echo "  broadcast ${BROADCAST}" >> ${IFFILE}
echo "" >> ${IFFILE}

# Add IPv6 configuration if DHCPv6 is enabled
if test ${DHCPV6_SERVER} = true; then
    # Extract the network portion of the IPv6 prefix for interface address
    IPV6_NETWORK=$(echo ${DHCPV6_PREFIX} | cut -d':' -f1-4)
    IPV6_INTERFACE_ADDR="${IPV6_NETWORK}::1"
    
    echo "iface ${INTERFACE} inet6 static" >> ${IFFILE}
    echo "  address ${IPV6_INTERFACE_ADDR}" >> ${IFFILE}
    echo "  netmask 64" >> ${IFFILE}
    echo "" >> ${IFFILE}
    
    echo "Enabling IPv6 forwarding for ${INTERFACE}..."
    # Enable IPv6 forwarding for the interface
    sysctl -w net.ipv6.conf.${INTERFACE}.forwarding=1
    # Enable global IPv6 forwarding 
    sysctl -w net.ipv6.conf.all.forwarding=1
    # Keep Router Advertisements working even with forwarding enabled
    sysctl -w net.ipv6.conf.${INTERFACE}.accept_ra=2
    sysctl -w net.ipv6.conf.all.accept_ra=2
    # Enable neighbor discovery proxy for link-local
    sysctl -w net.ipv6.conf.${INTERFACE}.proxy_ndp=1
fi

echo "Resseting interfaces"
reset_interfaces
ifup ${INTERFACE}
sleep 1

# Setup dnsmasq for DHCP (IPv4 and IPv6)
if test ${DHCP_SERVER} = true || test ${DHCPV6_SERVER} = true; then
    DNSMASQ_CONFIG="/etc/dnsmasq.conf"
    
    echo "Setup dnsmasq ..."
    echo "# Basic configuration" > ${DNSMASQ_CONFIG}
    echo "interface=${INTERFACE}" >> ${DNSMASQ_CONFIG}
    echo "bind-interfaces" >> ${DNSMASQ_CONFIG}
    echo "except-interface=lo" >> ${DNSMASQ_CONFIG}
    echo "" >> ${DNSMASQ_CONFIG}
    
    # IPv4 DHCP configuration
    if test ${DHCP_SERVER} = true; then
        echo "# IPv4 DHCP configuration" >> ${DNSMASQ_CONFIG}
        echo "dhcp-range=${DHCP_START},${DHCP_END},${DHCP_SUBNET},${LEASE_TIME}s" >> ${DNSMASQ_CONFIG}
        echo "dhcp-option=option:router,${DHCP_ROUTER}" >> ${DNSMASQ_CONFIG}
        echo "dhcp-option=option:dns-server,${DHCP_DNS}" >> ${DNSMASQ_CONFIG}
        echo "" >> ${DNSMASQ_CONFIG}
        
        # Add static leases
        while IFS=, read -r mac ip name; do
            if [ ! -z "$mac" ] && [ ! -z "$ip" ]; then
                echo "dhcp-host=${mac},${ip}  # ${name}" >> ${DNSMASQ_CONFIG}
            fi
        done <<< "${STATIC_LEASES}"
        echo "" >> ${DNSMASQ_CONFIG}
    fi
    
    # IPv6 DHCP configuration
    if test ${DHCPV6_SERVER} = true; then
        echo "# IPv6 DHCP configuration" >> ${DNSMASQ_CONFIG}
        echo "enable-ra" >> ${DNSMASQ_CONFIG}
        echo "ra-names,ra-stateful" >> ${DNSMASQ_CONFIG}
        echo "dhcp-range=${DHCPV6_START},${DHCPV6_END},64,${LEASE_TIME}s" >> ${DNSMASQ_CONFIG}
        echo "dhcp-option=option6:dns-server,[${DHCPV6_DNS}]" >> ${DNSMASQ_CONFIG}
        echo "" >> ${DNSMASQ_CONFIG}
        
        # Add IPv6 static leases
        while IFS=, read -r mac ipv6 name; do
            if [ ! -z "$mac" ] && [ ! -z "$ipv6" ]; then
                echo "dhcp-host=${mac},[${ipv6}]  # ${name}" >> ${DNSMASQ_CONFIG}
            fi
        done <<< "${STATIC_LEASES_V6}"
        echo "" >> ${DNSMASQ_CONFIG}
    fi
    
    echo "Starting dnsmasq..."
    dnsmasq --conf-file=${DNSMASQ_CONFIG} --no-daemon &
fi

sleep 1

echo "Starting HostAP daemon ..."
hostapd ${HCONFIG} &

while true; do 
    echo "Interface stats:"
    ifconfig | grep ${INTERFACE} -A6
    sleep 3600
done
