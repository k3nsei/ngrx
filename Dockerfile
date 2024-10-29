FROM mcr.microsoft.com/dotnet/sdk:8.0.403-noble AS base

RUN apt-get update -yq && \
    apt-get upgrade -yq && \
    apt-get install ca-certificates curl gnupg2 unzip zip jq -yq

ENV NODE_VERSION 22.10.0
ENV NPM_VERSION 10.9.0
ENV YARN_VERSION 1.22.22

ENV VOLTA_HOME /usr/local/volta

RUN curl https://get.volta.sh | bash -s -- --skip-setup && \
    ${VOLTA_HOME}/bin/volta install node@v${NODE_VERSION} && \
    ${VOLTA_HOME}/bin/volta install npm@v${NPM_VERSION} && \
    ${VOLTA_HOME}/bin/volta install yarn@v${YARN_VERSION}

ENV PATH $VOLTA_HOME/bin:$PATH

RUN dotnet --version && \
    node --version && \
    npm --version && \
    yarn --version

FROM base AS deps

WORKDIR /app

ARG CI
ENV CI=${CI:-true}

COPY package.json yarn.lock ./

RUN yarn --frozen-lockfile --non-interactive

FROM base AS build

WORKDIR /app

ARG CI
ENV CI=${CI:-true}

ARG NX_DAEMON
ENV NX_DAEMON=${NX_DAEMON:-false}

ARG NX_NATIVE_LOGGING
ENV NX_NATIVE_LOGGING=${NX_NATIVE_LOGGING:-"nx::native::cache,nx::native::db"}

COPY . .

COPY --from=deps /app/node_modules ./node_modules

RUN node --run lint || true

RUN node --run test || true

RUN node --run build || true
