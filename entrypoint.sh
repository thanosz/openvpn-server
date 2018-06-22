#!/bin/bash


writeServerConfig() {

	[[ -f /etc/openvpn/server/config.ovpn ]] && return
	echo First run...
	mkdir -p /etc/openvpn/server
	echo Generating server configuration...
	cat > /etc/openvpn/server/config.ovpn << EOF
port 1194
proto tcp
dev tun0

ca /etc/openvpn/easy-rsa/keys/ca.crt
cert /etc/openvpn/easy-rsa/keys/$(hostname).crt
key /etc/openvpn/easy-rsa/keys/$(hostname).key
dh /etc/openvpn/easy-rsa/keys/dh2048.pem
cipher AES-256-CBC

plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login
client-cert-not-required
#verify-client-cert none
username-as-common-name

server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway autolocal"
#push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 208.67.222.222"
push "dhcp-option DNS 208.67.220.220"

keepalive 10 120
comp-lzo
persist-key
persist-tun
status /var/log/openvpn-status.log
verb 3

log-append /var/log/openvpn
status /tmp/vpn.status 10
EOF
}

writeClientConfig() {
	[[ -f /etc/openvpn/client/client.ovpn ]] && return
	echo Generating client configuration...
	mkdir -p /etc/openvpn/client
	cat > /etc/openvpn/client/client.ovpn << EOF
remote SERVER_NAME PORT
auth-user-pass
client
proto tcp
dev tun
resolv-retry infinite
nobind
persist-key
persist-tun
ns-cert-type server
cipher AES-256-CBC
auth SHA1
comp-lzo
verb 3
EOF

echo >> /etc/openvpn/client/client.ovpn
echo '<ca>' >> /etc/openvpn/client/client.ovpn
cat /etc/openvpn/easy-rsa/keys/ca.crt >> /etc/openvpn/client/client.ovpn
echo '</ca>' >> /etc/openvpn/client/client.ovpn
echo You can find the client configuration in container volume or under /etc/openvpn/client
echo "You need to modify the client configuration to reflect your setup (server name, port)"
}

addVpnUser() {
	if ! grep vpn_user /etc/passwd > /dev/null; then
		echo Adding user vpn_user...
		useradd -m vpn_user
		if [[ -f /etc/openvpn/client/auth.txt ]]; then
			PASSWORD=$(tail -n1 /etc/openvpn/client/auth.txt)
		else
 			PASSWORD=$(date | md5sum | head -c 10)
		fi
		echo Setting password $PASSWORD for vpn_user 
		echo "vpn_user:${PASSWORD}" | chpasswd
		echo vpn_user > /etc/openvpn/client/auth.txt
		echo $PASSWORD >> /etc/openvpn/client/auth.txt
		echo You can find the authorization data in container volume or under /etc/openvpn/client
	fi
}


generateCerts() {
	[[ -f /etc/openvpn/easy-rsa/keys/dh2048.pem ]] && return
	echo Generating certificates...
	cp -r /usr/share/easy-rsa /etc/openvpn/
	cd /etc/openvpn/easy-rsa
	source ./vars
	./clean-all
	./pkitool --initca
	./pkitool --server $(hostname)
	./build-dh

}

echo Starting...
generateCerts
writeServerConfig
writeClientConfig
addVpnUser

echo Running OpenVPN server...
[[ -d /dev/net ]] || mkdir -p /dev/net
[[ -a /dev/net/tun ]] || mknod /dev/net/tun c 10 200 

if ! iptables -C FORWARD -s 10.8.0.0/24 -j ACCEPT 2>/dev/null; then
	iptables -A FORWARD -s 10.8.0.0/24 -j ACCEPT
	iptables -A FORWARD -d 10.8.0.0/24 -j ACCEPT
	iptables -t nat -A POSTROUTING -s 10.8.0.0/24  -o `ip r | grep default | awk '{print $5}'` -j MASQUERADE
fi

openvpn --config /etc/openvpn/server/config.ovpn
