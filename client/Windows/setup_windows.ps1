Param (
	[Parameter(Mandatory)]$CAPath, 
	[Parameter(Mandatory)]$ServerIP,
	[Parameter(Mandatory)]$VPNName
)

Import-Certificate `
	-CertStoreLocation cert:\LocalMachine\Root\ `
	-FilePath $capath
Add-VpnConnection `
	-Name "$vpnname" `
	-ServerAddress "$serverip" `
	-TunnelType "IKEv2" `
	-AuthenticationMethod "EAP" `
	-EncryptionLevel "Maximum" `
	-RememberCredential

Get-VpnConnection -Name "$vpnname"

Set-VpnConnectionIPsecConfiguration `
	-Name "$vpnname" `
	-AuthenticationTransformConstants GCMAES256 `
	-CipherTransformConstants GCMAES256 `
	-DHGroup ECP384 `
	-IntegrityCheckMethod SHA384 `
	-PfsGroup ECP384 `
	-EncryptionMethod GCMAES256
