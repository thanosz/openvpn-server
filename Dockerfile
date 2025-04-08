FROM debian:bookworm
RUN apt update && \
	apt install -y openvpn easy-rsa iptables && \
	apt clean
COPY entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh
VOLUME /etc/openvpn
EXPOSE 1194
ENTRYPOINT ["/root/entrypoint.sh"]


