# 💬 Chat

### How to install dependencies ?

```bash
sudo bash install.sh
```

### Environment

Fill `.env_example` and rename it `.env`

### Server

```bash
...
```

### Client

```bash
...
```

### 🔐 Generates keys pair for JWT

#### Generate a SSL certificate

```bash
openssl genrsa -out keys/private.pem 2048
openssl rsa -in keys/private.pem -out keys/public.pem -outform PEM -pubout
```

### 🐳 Docker

#### Run

```bash
docker-compose up

or

docker-compose up -d (detach mode)
```

#### Reset db data

```bash
docker-compose up --renew-anon-volumes
```