FROM debian:bookworm-slim

EXPOSE 8891

RUN apt-get update -y && apt-get install -y \
opendkim \
opendkim-tools \
openssl \
&& apt-get clean \
&& rm -rf  /var/lib/apt/lists/* \
&& mkdir -p /etc/opendkim/conf

COPY ./conf/docker-entrypoint.sh /usr/local/bin

#WORKDIR /etc/opendkim
RUN chmod a+x /usr/local/bin/docker-entrypoint.sh
RUN mkdir -p /etc/opendkim/keys

ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh"]