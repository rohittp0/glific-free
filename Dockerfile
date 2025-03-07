ARG ELIXIR_VERSION=1.14.5
ARG ERLANG_VERSION=25.3.2.7
ARG ALPINE_VERSION=3.16.7

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION}

# These two args need to stay here – otherwise they will be empty at RUN stage
ARG NODE_VERSION
ARG POSTGRES_VERSION

ARG FP=DOES_NOT_EXIST
ARG AUTH_KEY=DOES_NOT_EXIST

ENV LANG=C.UTF-8

# Install dependencies
RUN apk add --no-cache --update \
    build-base git curl zsh vim inotify-tools openssl ncurses-libs npm \
    nodejs-current \
    postgresql14

# Create a directory for the app code
WORKDIR /app/glific

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install mkcert
RUN wget -O mkcert https://github.com/FiloSottile/mkcert/releases/download/v1.4.3/mkcert-v1.4.3-linux-amd64 && \
    chmod +x mkcert && \
    mv mkcert /usr/local/bin

RUN mkdir config


# copy entire config directory
COPY config config

# Copy the dev.secret.exs file
COPY config/dev.secret.exs.txt config/dev.secret.exs

# Copy the .env.dev file
COPY config/.env.dev.txt config/.env.dev

# Create the priv/cert directory
RUN mkdir -p priv/cert

# Install SSL certificates

RUN /usr/local/bin/mkcert --install && \
    mkcert glific.test api.glific.test && \
    mv glific.test* priv/cert && \
    cp "`mkcert --CAROOT`/"/* priv/cert

COPY mix.lock mix.exs .

RUN mix hex.repo add oban https://github.com/sorentwo/oban

# do the setup, break into steps for caching during debugging
RUN mix deps.get
RUN mix deps.compile

# Lets make sure everything is in /app
# COPY . .
    
ENTRYPOINT ["/bin/sh", "/app/glific/config/entrypoint.sh"]
