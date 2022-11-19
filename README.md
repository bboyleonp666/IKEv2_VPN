# The IKEv2 VPN Installer

## Installation
1. `git clone https://github.com/bboyleonp666/IKEv2_VPN.git`
1. `cd IKEv2_VPN/server`
1. `bash installVPN.sh`

## CA
1. After installation, the CA will be saved in `IKEv2_VPN/server/CA/ca-cert.pem`  
1. Copy the CA to your devices and use your `username` and `password` to setup your device for VPN usage
1. To add a new user to the VPN list, run `bash addUser.sh`