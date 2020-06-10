![Model](https://github.com/bciobanu/pain/workflows/Model/badge.svg)

# Running locally

``` sh
docker-compose build
docker-compose up
```

# Building for production

Get `prod.secrets.exs` from _someone_ and put it in `dashboard/config`.

``` sh
docker build . --tag bciobanu/pain-deploy
docker push bciobanu/pain-deploy
```
