# Ubuntu Setup Guidance

## GUI
1. `sudo apt update && sudo apt install -y network-manager-strongswan`
2. Open VPN configuration panel
    - Connection name: `<Name>`
    - Address: `<VPN IP>`
    - Certificate: `<CA>`
    - Authentication: `EAP`
    - Username: `<User>`
    - Password: `<Password>`
    - Request an inner IP address: `[Checked]`