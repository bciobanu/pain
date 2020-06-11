# -------------------- Python Modules --------------------
FROM debian:stretch as python-modules
RUN apt-get update && apt-get install -y \
    python3 \
    python3-dev \
    python3-pip \
    g++ \
    libjpeg-dev \
    zlib1g-dev

# Upgrade pip utils
RUN pip3 install --upgrade pip setuptools wheel
 
# Copy requirements separately so that the cache is invalidated only when it changes
COPY model/requirements.txt ./
RUN pip3 install \
    --quiet \
    --prefix=/py_deps \
    --no-warn-script-location \
    -r requirements.txt \
    -f https://download.pytorch.org/whl/torch_stable.html

# -------------------- Build -------------------- 
FROM erlang:21 as builder

ARG MIX_ENV=prod
ARG ELIXIR=v1.10.3
ENV MIX_ENV=${MIX_ENV}

# Elixir
ADD https://github.com/elixir-lang/elixir/releases/download/${ELIXIR}/Precompiled.zip elixir.zip
RUN unzip elixir.zip

ENV PATH="/elixir/bin:${PATH}"

COPY model model

WORKDIR /
RUN mkdir /dashboard
WORKDIR /dashboard

RUN mix local.hex --force && \
    mix local.rebar --force

COPY dashboard/mix.exs dashboard/mix.lock ./
RUN mix deps.get

# Add NPM repo
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs npm

# Build assets
RUN mkdir assets
WORKDIR assets

# Copy and install packages separately from the other assets to cache them
COPY dashboard/assets/package.json dashboard/assets/package-lock.json ./
RUN npm ci --progress=false --no-audit --loglevel=error

COPY dashboard/assets ./
RUN npm run deploy

WORKDIR /dashboard

COPY dashboard/config config
COPY dashboard/lib lib
COPY dashboard/priv priv

RUN mix do compile
RUN mix phx.digest
RUN mkdir /release
RUN mix release --path /release

# -------------------- Run -------------------- 
FROM debian:stretch

RUN apt-get update && apt-get install -y openssl python3 inotify-tools

ENV ERLPORT_PYTHON=python3
ENV PYTHONPATH=/usr/local/lib/python3.5/site-packages

COPY --from=builder /model /model
COPY --from=python-modules /py_deps /usr/local

RUN mkdir /dashboard
WORKDIR /dashboard
COPY --from=builder /release .
RUN chown -R nobody: .

COPY deploy.sh .
ENTRYPOINT ["sh", "./deploy.sh"]
