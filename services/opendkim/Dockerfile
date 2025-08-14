FROM debian:bookworm-slim

RUN apt-get update -y && apt-get install -y \
opendkim \
opendkim-tools \
&& apt-get clean \
&& rm -rf  /var/lib/apt/lists/* \
&& mkdir -p /etc/opendkim/conf 
 
EXPOSE 8891/tcp

COPY ./conf/docker-entrypoint.sh /usr/local/bin
 
#WORKDIR /etc/opendkim
RUN chmod a+x /usr/local/bin/docker-entrypoint.sh
RUN mkdir -p /etc/opendkim/keys

ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh"]