openvpn-server
=====
This is a simple opevpn-server. It is intended for home users needing to run an openvpn server for privacy.

It will create the configuration needed for the openvpn server to run and also the client configuration needed for the clients to connect.

For authorization there are no client certificates generated. The authorization is user-based. This is a compromise between security and ease-of-use.

Details
=====
On first run the certificates and all configuration will be generated. A user **vpn_user** will be created and a random password will be assigned.

How to use
=====
The container needs to run with **NET_ADMIN** capability. It is best to use volumes so that the server certificates are not regenerated every time a new container is created.

    docker run -it -v openvpn_data:/etc/openvpn -p 1194:1194 --cap-add=NET_ADMIN thanosz/openvpn-server


The client configuration will be generated under /var/lib/docker/volumes/openvpn_data/_data/client/client.ovpn. You need to change the SERVER_NAME and PORT according to your configuration. Normally SERVER_NAME would be the external DNS name of your router and PORT would be the external port on your router which has to be redirected to the docker host at the default openvpn port 1194. 

Import client.opvn to the openvpn client application

The /var/lib/docker/volumes/openvpn_data/_data/client/auth.txt contains the password for the vpn_user which you need to put when prompted in the openvpn client application.
