FROM ubuntu:18.04 AS builder

ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8 

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  	locales locales-all \
    wget \
    bzip2 \
    ca-certificates \
    openssl \
    curl \
    libffi-dev \
    libssl-dev \
    libyaml-dev \
    libxml2 \
    libxml2-dev \
    libpq-dev \
    libxslt1-dev \
    procps \
    zlib1g-dev \
    libjemalloc-dev \
    imagemagick \
  && rm -rf /var/lib/apt/lists/*

# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
  && { \
    echo 'install: --no-document'; \
    echo 'update: --no-document'; \
  } >> /usr/local/etc/gemrc

ENV RUBY_MAJOR 2.6
ENV RUBY_VERSION 2.6.5
ENV RUBY_DOWNLOAD_SHA256 66976b716ecc1fd34f9b7c3c2b07bbd37631815377a2e3e85a5b194cfdcbed7d
ENV RUBYGEMS_VERSION 3.0.6

# some of ruby's build scripts are written in ruby
# we purge this later to make sure our final image uses what we just built
RUN set -ex \
  && buildDeps=' \
    autoconf \
    bison \
    gcc \
    libbz2-dev \
    libgdbm-dev \
    libglib2.0-dev \
    libncurses-dev \
    libreadline-dev \
    libxml2-dev \
    libxslt-dev \
    make \
    ruby \
  ' \
  && apt-get update \
  && apt-get install -y --no-install-recommends $buildDeps \
  && rm -rf /var/lib/apt/lists/* \
  && curl -fSL -o ruby.tar.gz "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz" \
  && echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum -c - \
  && mkdir -p /usr/src/ruby \
  && tar -xzf ruby.tar.gz -C /usr/src/ruby --strip-components=1 \
  && rm ruby.tar.gz \
  && cd /usr/src/ruby \
  && { echo '#define ENABLE_PATH_CHECK 0'; echo; cat file.c; } > file.c.new && mv file.c.new file.c \
  && autoconf \
  && ./configure --with-jemalloc --disable-install-doc \
  && make -j"$(nproc)" \
  && make install \
  && apt-get purge -y --auto-remove $buildDeps \
  && gem update --system $RUBYGEMS_VERSION \
  && rm -r /usr/src/ruby

# install things globally, for great justice
# and don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
  BUNDLE_BIN="$GEM_HOME/bin" \
  BUNDLE_SILENCE_ROOT_WARNING=1 \
  BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" \
&& chmod 777 "$GEM_HOME" "$BUNDLE_BIN"

RUN gem install bundler -v 2.1.4
RUN apt-get update
RUN apt-get -y install curl
RUN apt-get install -my gnupg
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get -qqyy install nodejs yarn && rm -rf /var/lib/apt/lists/*

#RUN echo 'LC_ALL="en_US.UTF-8"' > /etc/default/locale
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update
RUN apt-get install -y openssl libpq-dev build-essential libcurl4-openssl-dev git software-properties-common	

RUN mkdir /usr/src/app

WORKDIR /usr/src/app

ENV PATH /usr/src/app/node_modules/.bin:$PATH

COPY package.json /usr/src/app/package.json

RUN npm install -g bower

RUN npm install -g grunt-cli

COPY . /usr/src/app

#RUN gem install compass && gem install font-awesome-sass && gem install sass-css-importer-load-paths && gem install scss_lint

RUN bower --allow-root install

RUN npm install

RUN export PATH=$PATH:/usr/local/rvm/bin:/usr/local/rvm/sbin && bundle install

#RUN grunt prod

RUN npm run build

#CMD ng serve --host 0.0.0.0 --disable-host-check --configuration kubernetes

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