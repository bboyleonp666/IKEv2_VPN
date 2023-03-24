# Android Setup Guidance

## Steps
1. Import CA
    1. Install [StrongSwan Client Application](https://play.google.com/store/apps/details?id=org.strongswan.android&hl=en_US) from Play Store
    1. Save the CA file to your cellphone
    1. Open StrongSwan and tap `more` icon ( $\vdots$ ) in the upper-right corner and select `CA certificates`
    1. Tap `more` icon ( $\vdots$ ) again and select `Import Certificate`
    1. Browse and import your CA
1. Configurate Profile
    1. Tap `ADD VPN PROFILE`
    1. Fill out `Server` with the VPN IP address
    1. Make sure `VPN Type` is **IKEv2 EAP (Username/Password)**
    1. Fill out `Username` as well as `Password`
    1. (Optional) Choose your own `Profile Name`
1. Try to connect to your VPN

**Trouble Shooting:** If your failed to connect to the VPN, try unchecking the `CA Certificate` and add the correct CA manually.
