# -------------------- Build -------------------- 
FROM erlang:21 as builder

ENV MIX_ENV=prod

RUN set -xe && \
  ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/archive/v1.10.3.tar.gz" && \
  curl -fSL -o elixir-src.tar.gz $ELIXIR_DOWNLOAD_URL && \
  mkdir -p /usr/local/src/elixir && \
  tar -xzC /usr/local/src/elixir --strip-components=1 -f elixir-src.tar.gz && \
  rm elixir-src.tar.gz && \
  cd /usr/local/src/elixir && \
  make install clean

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get update && apt-get install -y \
    nodejs \
    npm \
    python3 \
    python3-dev \
    python3-pip \
    g++ \
    libjpeg-dev \
    zlib1g-dev

RUN pip3 install --upgrade pip setuptools wheel

COPY model ./model/
RUN cd model && pip3 install --prefix=/py_deps -r requirements.txt -f https://download.pytorch.org/whl/torch_stable.html

RUN mkdir /dashboard
WORKDIR /dashboard

RUN mix local.hex --force && \
    mix local.rebar --force

COPY dashboard/mix.exs dashboard/mix.lock ./
RUN mix deps.get

COPY dashboard/assets ./assets/
RUN cd assets && npm install && npm run deploy

COPY dashboard/config ./config
COPY dashboard/lib ./lib
COPY dashboard/priv ./priv

RUN mix do compile
RUN mix phx.digest
RUN mkdir /release
RUN mix release --path /release

# -------------------- Run -------------------- 
FROM debian:stretch

RUN apt-get update && apt-get install -y openssl python3 inotify-tools

ENV MIX_ENV=prod
ENV ERLPORT_PYTHON=python3
ENV PYTHONPATH=/usr/local/lib/python3.5/site-packages

COPY --from=builder /model /model
COPY --from=builder /py_deps /usr/local

RUN mkdir /dashboard
WORKDIR /dashboard
COPY --from=builder /release ./
RUN chown -R nobody: ./

ENTRYPOINT ["./bin/dashboard", "start"]
