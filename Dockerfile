FROM node:10 as builder

RUN apt-get update && apt-get install -y vim

RUN npm install -g @angular/cli

RUN npm install -g ng-common

RUN ng build

#CMD ng serve --host 0.0.0.0 --disable-host-check --configuration kubernetes

ADD . /app
WORKDIR /app
ENV PATH /app/node_modules/.bin:$PATH
RUN npm rebuild node-sass --force
RUN npm install --force
RUN ng build --configuration kubernetes

FROM litespeedtech/openlitespeed:latest AS runner

RUN export DEBIAN_FRONTEND=noninteractive && apt-get update \
	&& apt-get install -y --no-install-recommends wget telnet unzip tzdata telnet netcat vim dos2unix curl software-properties-common gnupg apt-transport-https \
	&& ln -fs /usr/share/zoneinfo/America/Mexico_City /etc/localtime \
	&& dpkg-reconfigure --frontend noninteractive tzdata dos2unix \
	&& apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mv /usr/local/lsws/Example /usr/local/lsws/Mifos

COPY --from=builder /usr/src/app/dist/community-app /usr/local/lsws/Mifos/html

COPY ./httpd_config.conf /usr/local/lsws/conf/httpd_config.conf

COPY ./vhconf.conf /usr/local/lsws/conf/vhosts/Mifos/vhconf.conf 

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]


EXPOSE 80 443 7080