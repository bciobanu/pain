# -------------------- Build -------------------- 
FROM elixir:1.9.4-alpine as builder
ENV LANG=C.UTF-8
ENV MIX_ENV=dev

RUN apk update && apk add \
    nodejs \
    npm \
    python3 \
    python3-dev \
    g++ \
    musl-dev \
    jpeg-dev \
    zlib-dev

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

RUN apk del --purge

# -------------------- Run -------------------- 
FROM alpine
ENV LANG=C.UTF-8

RUN apk update && apk add openssl ncurses-libs

ENV MIX_ENV=dev
ENV PORT=4000

RUN mkdir /dashboard
WORKDIR /dashboard

COPY --from=builder /py_deps /usr/local
COPY --from=builder /release ./
RUN chown -R nobody: ./

EXPOSE ${PORT}
ENTRYPOINT ["./bin/dashboard", "start"]
