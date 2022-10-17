#!/bin/bash

# Reference:
# https://www.digitalocean.com/community/tutorials/how-to-set-up-an-ikev2-vpn-server-with-strongswan-on-ubuntu-22-04
 
source utils/functions

# server IP
# Assume:
#     Server with public IP
#     Configure through SSH 
SERVER_IP=$(echo $SSH_CONNECTION | awk '{print $3}')
#read -p 'Server IP: ' SERVER_IP

# install packages required
sudo apt update -y
sudo apt install strongswan strongswan-pki libcharon-extra-plugins \
    libcharon-extauth-plugins libstrongswan-extra-plugins libtss2-tcti-tabrmd0 -y

mkdir -p ~/pki/{cacerts,certs,private}
chmod 700 ~/pki

# Generate self signed CA
pki --gen --type rsa --size 4096 --outform pem > ~/pki/private/ca-key.pem
pki --self --ca --lifetime 3650 --in ~/pki/private/ca-key.pem \
    --type rsa --dn "CN=VPN root CA" --outform pem > ~/pki/cacerts/ca-cert.pem

# Generate CA for VPN server
pki --gen --type rsa --size 4096 --outform pem > ~/pki/private/server-key.pem
pki --pub --in ~/pki/private/server-key.pem --type rsa \
    | pki --issue --lifetime 1825 \
        --cacert ~/pki/cacerts/ca-cert.pem \
        --cakey ~/pki/private/ca-key.pem \
        --dn "CN=$SERVER_IP" --san @$SERVER_IP --san $SERVER_IP \
        --flag serverAuth --flag ikeIntermediate --outform pem \
    >  ~/pki/certs/server-cert.pem

sudo cp -r ~/pki/* /etc/ipsec.d/

# Configure /etc/ipsec.conf for StrongSwan
IPSEC_CONF=/etc/ipsec.conf
backup $IPSEC_CONF
cat > /tmp/ipsec.conf <<EOF
config setup
    charondebug="ike 1, knl 1, cfg 0"
    uniqueids=no

conn ikev2-vpn
    auto=add
    compress=no
    type=tunnel
    keyexchange=ikev2
    fragmentation=yes
    forceencaps=yes
    dpdaction=clear
    dpddelay=300s
    rekey=no
    left=%any
    leftid=@server_domain_or_IP
    leftcert=server-cert.pem
    leftsendcert=always
    leftsubnet=0.0.0.0/0
    right=%any
    rightid=%any
    rightauth=eap-mschapv2
    rightsourceip=10.10.10.0/24
    rightdns=8.8.8.8,8.8.4.4
    rightsendcert=never
    eap_identity=%identity
    ike=chacha20poly1305-sha512-curve25519-prfsha512,aes256gcm16-sha384-prfsha384-ecp384,aes256-sha1-modp1024,aes128-sha1-modp1024,3des-sha1-modp1024!
    esp=chacha20poly1305-sha512,aes256gcm16-ecp384,aes256-sha256,aes256-sha1,3des-sha1!
EOF
sed -i "s/leftid=@server_domain_or_IP/leftid=$SERVER_IP/g" /tmp/ipsec.conf
# sed -i "s#leftcert=server-cert.pem#leftcert=/etc/ipsec.d/certs/server-cert.pem#g" /tmp/ipsec.conf
sudo cp /tmp/ipsec.conf $IPSEC_CONF

# Configure /etc/ipsec.secrets for StrongSwan
IPSEC_SECRETS=/etc/ipsec.secrets
backup $IPSEC_SECRETES
# echo ': RSA "/etc/ipsec.d/private/server-key.pem"' | sudo tee -a $IPSEC_SECRETS >/dev/null
echo ': RSA "server-key.pem"' | sudo tee -a $IPSEC_SECRETS >/dev/null
addVPNUser $IPSEC_SECRETS

# Configure Firewall
sudo ufw allow 500,4500/udp

ROUTE_RULES=/etc/ufw/before.rules
backup $ROUTE_RULES

## make /etc/ufw/before.rules readable
sudo chmod 666 $ROUTE_RULES
pattern_line_num=$(grep -n *filter $ROUTE_RULES | cut -d : -f 1)

### section 1
head -n $(($pattern_line_num - 1)) $ROUTE_RULES > /tmp/rule_sec1
### section 2
cat > /tmp/rule_sec2 <<EOF
*nat
-A POSTROUTING -s 10.10.10.0/24 -o eth0 -m policy --pol ipsec --dir out -j ACCEPT
-A POSTROUTING -s 10.10.10.0/24 -o eth0 -j MASQUERADE
COMMIT

*mangle
-A FORWARD --match policy --pol ipsec --dir in -s 10.10.10.0/24 -o eth0 -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360
COMMIT

EOF
INTERFACE=$(ip route show default | cut -d ' ' -f 5)
sed -i "s/eth0/$INTERFACE/g" /tmp/rule_sec2
### section 3
grep -A 4 *filter $ROUTE_RULES > /tmp/rule_sec3
### section 4
cat > /tmp/rule_sec4 <<EOF

-A ufw-before-forward --match policy --pol ipsec --dir in --proto esp -s 10.10.10.0/24 -j ACCEPT
-A ufw-before-forward --match policy --pol ipsec --dir out --proto esp -d 10.10.10.0/24 -j ACCEPT
EOF
### section 5
tail -n +$(($pattern_line_num + 5)) $ROUTE_RULES > /tmp/rule_sec5

cat /tmp/rule_sec[1-5] > $ROUTE_RULES
sudo chmod 640 $ROUTE_RULES
##

# Configure /etc/ufw/sysctl.conf to prevent man-in-the-middle attack
UFW_CTL=/etc/ufw/sysctl.conf
backup $UFW_CTL
[[ $(grep -e '^net/ipv4/ip_forward=1' $UFW_CTL) ]] || echo 'net/ipv4/ip_forward=1' | sudo tee -a $UFW_CTL >>/dev/null
[[ $(grep -e '^net/ipv4/conf/all/accept_redirects=0' $UFW_CTL) ]] || echo 'net/ipv4/conf/all/accept_redirects=0' | sudo tee -a $UFW_CTL >>/dev/null
[[ $(grep -e '^net/ipv4/conf/all/send_redirects=0' $UFW_CTL) ]] || echo 'net/ipv4/conf/all/send_redirects=0' | sudo tee -a $UFW_CTL >>/dev/null
[[ $(grep -e '^net/ipv4/ip_no_pmtu_disc=1' $UFW_CTL) ]] || echo 'net/ipv4/ip_no_pmtu_disc=1' | sudo tee -a $UFW_CTL >>/dev/null

sudo ufw disable
echo 'y' | sudo ufw enable

mkdir -p CA
cp /etc/ipsec.d/cacerts/ca-cert.pem CA/ca-cert.pem
