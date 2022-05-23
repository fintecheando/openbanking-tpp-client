FROM node:16 as builder

RUN mkdir -p /app

ADD . /app

WORKDIR /app

RUN npm install && npm run build

FROM litespeedtech/openlitespeed:latest AS runner

RUN export DEBIAN_FRONTEND=noninteractive && apt-get update \
	&& apt-get install -y --no-install-recommends wget telnet unzip tzdata telnet netcat vim dos2unix curl software-properties-common gnupg apt-transport-https \
	&& ln -fs /usr/share/zoneinfo/America/Mexico_City /etc/localtime \
	&& dpkg-reconfigure --frontend noninteractive tzdata dos2unix \
	&& apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mv /usr/local/lsws/Example /usr/local/lsws/Mifos

RUN mkdir -p /usr/local/lsws/Mifos/netbank

COPY --from=builder /app/build /usr/local/lsws/Mifos/html

#COPY --from=builder /app/build /usr/local/lsws/Mifos/html/netbank

COPY ./httpd_config.conf /usr/local/lsws/conf/httpd_config.conf

COPY ./vhconf.conf /usr/local/lsws/conf/vhosts/Mifos/vhconf.conf 

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]


EXPOSE 80 443 7080