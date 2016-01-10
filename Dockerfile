FROM heroku/cedar:14

RUN apt-get -qq update && apt-get install -y \
  git \
  unzip \
  build-essential \
  nodejs \
  npm \
  postgresql-client \
  wget

RUN mkdir -p /app/user
ENV HOME /app
ENV DEBIAN_FRONTEND noninteractive

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# --- erlang ---

WORKDIR /tmp
RUN wget -q https://github.com/erlang/otp/archive/OTP-18.1.5.zip && \
    unzip OTP-18.1.5.zip

WORKDIR /tmp/otp-OTP-18.1.5
ENV ERL_TOP /tmp/otp-OTP-18.1.5
RUN mkdir -p /app/erlang
RUN ./otp_build autoconf
RUN ./configure --prefix=/app/erlang
RUN make && make install
ENV PATH /app/erlang/bin:/app/erlang/lib:$PATH

# --- elixir ---

WORKDIR /tmp
RUN wget -q https://github.com/elixir-lang/elixir/archive/v1.2.0.zip && \
    unzip v1.2.0.zip

WORKDIR /tmp/elixir-1.2.0
RUN mkdir -p /app/elixir
RUN make
RUN make install PREFIX=/app/elixir
ENV PATH /app/elixir/bin:/app/elixir/lib:$PATH
RUN mix local.hex --force && \
    mix local.rebar --force

# --- inotify-tools -------------
# For phoenix code reload watches

WORKDIR /tmp
RUN wget -q https://github.com/rvoicilas/inotify-tools/archive/v3.14.zip && \
    unzip v3.14.zip

WORKDIR /tmp/inotify-tools-3.14
RUN mkdir -p /app/inotify-tools
RUN ./autogen.sh && \
    ./configure --prefix=/app/inotify-tools && \
    make && \
    make install
ENV PATH /app/inotify-tools/bin:$PATH

# --- node ---
# For assets

WORKDIR /tmp
RUN wget -q https://nodejs.org/dist/v4.2.4/node-v4.2.4.tar.gz && \
    tar -xzf node-v4.2.4.tar.gz

WORKDIR /tmp/node-v4.2.4
RUN mkdir -p /app/node
RUN ./configure --prefix=/app/node && \
    make && \
    make install
ENV PATH /app/node/bin:$PATH

RUN rm -rf /tmp/*

ADD init.sh /app/
ONBUILD RUN mkdir -p /app/.profile.d
ONBUILD RUN echo "export PATH=\"$PATH\" " > /app/.profile.d/paths.sh

WORKDIR /app/user

ENTRYPOINT ["/app/init.sh"]
