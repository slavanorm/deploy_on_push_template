Static HTML site with nginx + SSL autodeploy.

## Structure

```
public/          # HTML files go here
infra/
  .env.example   # copy to .env, set DOMAIN and EMAIL
  docker-compose.yml
  nginx/
  certbot/
```

## VPS Setup (first time)

```bash
mkdir -p ~/persist/certbot/{conf,www}
git clone git@github.com:USER/REPO.git ~/repo
cd ~/repo/infra
cp .env.example .env
nano .env
docker compose up -d
```

## GitHub Secrets

Add these in repo Settings → Secrets → Actions:

- `HOST` — VPS IP or domain
- `USERNAME` — SSH user
- `SSH_KEY` — private key (full content)

## Deploy

Push to `main` branch. GitHub Actions handles the rest.

## Production Flow

1. Edit `public/index.html` locally
2. Commit & push to `main`
3. GitHub Actions SSHs into VPS and runs `git pull && docker compose up -d`
4. nginx serves `public/` at your domain with HTTPS

## Local Testing

```bash
python3 -m http.server 8000 --directory public
# open http://localhost:8000
```

## Nginx Configs

Three configs available in `infra/nginx/conf.d/`:

| Config | Use Case |
|--------|----------|
| `site.conf.template` | Production with DNS + SSL + www redirect |
| `site.ip-only.conf.template` | Testing via IP with self-signed cert (no DNS needed) |
| `site.no-ssl.conf.template` | HTTP only, no SSL (quick testing) |

### Testing without DNS

1. Create dummy cert:
```bash
mkdir -p ~/persist/certbot/conf/live/YOUR_DOMAIN
openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
  -keyout ~/persist/certbot/conf/live/YOUR_DOMAIN/privkey.pem \
  -out ~/persist/certbot/conf/live/YOUR_DOMAIN/fullchain.pem \
  -subj '/CN=YOUR_DOMAIN'
```

2. Use IP-only config:
```bash
cp infra/nginx/conf.d/site.ip-only.conf.template infra/nginx/conf.d/site.conf.template
docker restart nginx
```

3. Access via `https://YOUR_IP` (accept cert warning)

### HTTP only (no SSL)

```bash
cp infra/nginx/conf.d/site.no-ssl.conf.template infra/nginx/conf.d/site.conf.template
# comment out certbot in docker-compose.yml
docker compose up -d
```

Access via `http://YOUR_IP`
