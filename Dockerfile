FROM debian:bullseye
RUN apt-get update
#RUN apt-get upgrade
RUN apt-get -y install openvpn easy-rsa iptables
COPY entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh
ENTRYPOINT /root/entrypoint.sh


