FROM debian:bullseye
RUN apt update && \
	apt install -y openvpn easy-rsa iptables && \
	apt clean
COPY entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh
ENTRYPOINT /root/entrypoint.sh


