# Hassio Hotspot with DHCPv6 Support

**Transform your Home Assistant into a dual-stack WiFi access point with DHCPv4 and DHCPv6 support**

This add-on enables a wireless access point using USB WiFi dongles or onboard WiFi for your IoT devices on Home Assistant. It features a complete dual-stack DHCP server supporting both IPv4 and IPv6, making it perfect for modern IoT infrastructure requiring IPv6 connectivity.

## 🚀 Key Features

- **Dual-Stack DHCP**: Full IPv4 and IPv6 DHCP server with `dnsmasq`
- **USB WiFi Support**: Compatible with Ralink, Atheros, and other USB dongles
- **Static Leases**: Support for both IPv4 and IPv6 static IP assignments
- **Internet Sharing**: Optional internet access for connected devices
- **Network Isolation**: Separate network infrastructure (192.168.99.x) for IoT devices
- **Modern IPv6**: Ready for IoT devices requiring IPv6 connectivity

## 📦 Installation

### From GitHub Repository

1. In Home Assistant, go to **Supervisor** → **Add-on Store**
2. Click the **⋮** menu → **Repositories**
3. Add this repository URL:
   ```
   https://github.com/bylli79/hassio-addons
   ```
4. Find **"Hassio Hotspot"** in the store and click **Install**

### Local Installation

1. Copy the `hassio-hotspot` folder to `/config/addons/`
2. Restart Home Assistant
3. The add-on will appear under **Local add-ons**

## ⚙️ Configuration

### Basic Configuration

```json
{
    "ssid": "HomeAssistant-AP",
    "wpa_passphrase": "your-secure-password",
    "channel": "6",
    "address": "192.168.99.1",
    "netmask": "255.255.255.0",
    "broadcast": "192.168.99.254",
    "interface": "wlan1",
    "internet_interface": "eth0",
    "allow_internet": true,
    "dhcp_enable": true,
    "dhcp_start": "192.168.99.100",
    "dhcp_end": "192.168.99.200",
    "dhcp_dns": "1.1.1.1",
    "dhcp_subnet": "255.255.255.0",
    "dhcp_router": "192.168.99.1",
    "dhcpv6_enable": true,
    "dhcpv6_prefix": "fd00:192:168:99::/64",
    "dhcpv6_start": "fd00:192:168:99::100",
    "dhcpv6_end": "fd00:192:168:99::200",
    "dhcpv6_dns": "2001:4860:4860::8888",
    "hide_ssid": false,
    "lease_time": 864000,
    "static_leases": [
        {
            "mac": "00:11:22:33:44:55",
            "ip": "192.168.99.10",
            "name": "Smart Light"
        }
    ],
    "static_leases_v6": [
        {
            "mac": "00:11:22:33:44:55",
            "ipv6": "fd00:192:168:99::10",
            "name": "Smart Light IPv6"
        }
    ]
}
```

## 📡 Network Configuration

### IPv4 Network (192.168.99.x)
- **Gateway**: 192.168.99.1 (Your Home Assistant device)
- **DHCP Range**: 192.168.99.100 - 192.168.99.200
- **Static IPs**: Use 192.168.99.2 - 192.168.99.99 for static devices

### IPv6 Network (fd00:192:168:99::/64)
- **Gateway**: fd00:192:168:99::1
- **DHCP Range**: fd00:192:168:99::100 - fd00:192:168:99::200
- **Static IPs**: Use fd00:192:168:99::2 - fd00:192:168:99::99 for static devices

## 🔧 Configuration Options

### WiFi Settings
- **`ssid`**: Your WiFi network name
- **`wpa_passphrase`**: WiFi password (WPA2)
- **`channel`**: WiFi channel (0 = auto, or 1-11 for 2.4GHz)
- **`hide_ssid`**: Hide network name (true/false)
- **`interface`**: WiFi interface to use (leave blank to see available options in logs)

### IPv4 DHCP Settings
- **`dhcp_enable`**: Enable IPv4 DHCP server
- **`dhcp_start`**: Start of DHCP IP range
- **`dhcp_end`**: End of DHCP IP range
- **`dhcp_dns`**: DNS server for IPv4 clients
- **`dhcp_router`**: Gateway IP (usually the same as `address`)

### IPv6 DHCP Settings
- **`dhcpv6_enable`**: Enable IPv6 DHCP server
- **`dhcpv6_prefix`**: IPv6 network prefix (recommend fd00::/64 range)
- **`dhcpv6_start`**: Start of DHCPv6 range
- **`dhcpv6_end`**: End of DHCPv6 range
- **`dhcpv6_dns`**: DNS server for IPv6 clients

### Network Settings
- **`address`**: IP address of the access point
- **`netmask`**: Network subnet mask
- **`broadcast`**: Broadcast address
- **`internet_interface`**: Interface providing internet (usually eth0)
- **`allow_internet`**: Share internet connection with clients

### Advanced Settings
- **`lease_time`**: DHCP lease duration in seconds (default: 10 days)

## 📍 Static IP Assignments

### IPv4 Static Leases
Reserve specific IPv4 addresses for devices:

```json
"static_leases": [
    {
        "mac": "aa:bb:cc:dd:ee:ff",
        "ip": "192.168.99.10",
        "name": "Security Camera"
    },
    {
        "mac": "11:22:33:44:55:66",
        "ip": "192.168.99.11",
        "name": "Smart Thermostat"
    }
]
```

### IPv6 Static Leases
Reserve specific IPv6 addresses for devices:

```json
"static_leases_v6": [
    {
        "mac": "aa:bb:cc:dd:ee:ff",
        "ipv6": "fd00:192:168:99::10",
        "name": "Security Camera IPv6"
    },
    {
        "mac": "11:22:33:44:55:66",
        "ipv6": "fd00:192:168:99::11",
        "name": "Smart Thermostat IPv6"
    }
]
```

**Important**: Place static IPs outside the DHCP ranges to avoid conflicts.

## 🚦 Setup Steps

1. **Find WiFi Interface**:
   - Leave `interface` blank initially
   - Check add-on logs to see available interfaces
   - Common names: `wlan0`, `wlan1`, `wlx001122334455`

2. **Configure Network**:
   - Set your desired SSID and password
   - Choose a free WiFi channel (1, 6, or 11 for 2.4GHz)
   - Enable IPv4 and/or IPv6 as needed

3. **Test Connectivity**:
   - Start the add-on
   - Connect a device to test IPv4 connectivity
   - Use `ping6` to test IPv6 connectivity

4. **Configure Static Leases** (optional):
   - Find device MAC addresses
   - Assign static IPs outside DHCP ranges
   - Test that devices get the correct IPs

## 🔍 Troubleshooting

### Common Issues

**No WiFi interfaces found**:
- Check that WiFi dongle is connected
- Verify dongle compatibility with hostapd
- Some dongles need additional drivers

**IPv6 not working**:
- Verify kernel IPv6 support: `cat /proc/net/if_inet6`
- Check that `dhcpv6_enable` is true
- Test with: `ping6 fd00:192:168:99::1`

**DHCP conflicts**:
- Ensure static IPs are outside DHCP ranges
- Check for duplicate MAC addresses
- Monitor dnsmasq logs for conflicts

### Useful Commands

```bash
# View add-on logs
ha addons logs hassio-hotspot

# Check WiFi interfaces
iwconfig

# Test IPv4 connectivity
ping 192.168.99.1

# Test IPv6 connectivity
ping6 fd00:192:168:99::1
```

## 🔗 Technical Details

- **DHCP Server**: dnsmasq (replaces udhcpd for IPv6 support)
- **Access Point**: hostapd with WPA2 security
- **NAT/Routing**: iptables and ip6tables for traffic forwarding
- **IPv6 Features**: Router Advertisement (RA) enabled
- **Architecture**: Multi-arch support (armhf, armv7, aarch64, amd64, i386)

## 📄 Documentation

For detailed technical information, development notes, and advanced configuration, see the included `CLAUDE.md` file.

## 🤝 Contributing

This add-on welcomes contributions! Please:
1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request with clear documentation

## 📋 License

Based on the original work by João Loureiro, enhanced with IPv6 support and modern dual-stack configuration.

---

**Ready to give your IoT devices modern dual-stack networking!** 🌐✨