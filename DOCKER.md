# Running the blog on a server

Target: an Ubuntu VPS with Docker and the compose plugin, `ufw` active, SSH on a custom port.
Stack: **nginx** (the only published port) → **Rails/Puma** → **SQLite** in a named volume.
The app uses SQLite, so there is no database container; the database file and the uploads each live in a named volume (`ruby-blog_blog_db`, `ruby-blog_blog_storage`).

## 1. First install

```bash
git clone https://github.com/AhmedJguirim/ruby_blog.git /opt/ruby_blog && cd /opt/ruby_blog
scripts/init-env.sh --email you@example.com --url https://blog.example.com
scripts/redeploy.sh        # builds and starts everything (about 5 minutes the first time)
```

`init-env.sh` writes `.env` (mode 600) with random secrets and prints the first password once.
Use `--force` to regenerate (the old file is kept as `.env.bak.<date>`), `--port` to change the port.
Never commit `.env`; `.env.example` shows every variable.

The first user is created from `ADMIN_EMAIL` / `ADMIN_PASSWORD` at start-up. No demo data is added.

## 2. Ports, TLS, firewall

nginx listens on `${WEB_PORT}` (default **18090**) on `${BIND_ADDR}`:

| `--url` given to `init-env.sh` | `BIND_ADDR` | meaning |
|---|---|---|
| `https://…` | `127.0.0.1` | a TLS reverse proxy on the same host forwards to it |
| `http://<ip or host>…` | `0.0.0.0` | reachable directly over plain http (demo only) |

Docker publishes ports through its own iptables rules, **so `ufw deny 18090` does not block a port bound to `0.0.0.0`**. Keep `127.0.0.1` unless you want it open.

Example for the host's own nginx (certificates e.g. from certbot):

```nginx
server {
    listen 443 ssl;
    server_name blog.example.com;
    client_max_body_size 16m;
    location / {
        proxy_pass http://127.0.0.1:18090;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

With an `https://` URL the app redirects http to https, sets HSTS and secure cookies, and relies on `X-Forwarded-Proto`. Real client IPs (for rate limiting) come from `X-Forwarded-For`, trusted only from private addresses. Open only 80/443 and your SSH port in `ufw`.

## 3. Updating

| Command | What it does |
|---|---|
| `scripts/deploy.sh [--branch B] [--force] [-q]` | fetch, **DB backup**, fast-forward, build, start, health check. If the new version is unhealthy it returns to the previous commit and puts the bad one on hold (`--force` retries it). Only one deploy at a time. |
| `scripts/redeploy.sh [--no-cache] [-q]` | rebuild and restart the code on disk; git and the database are not touched |
| `scripts/rollback.sh [-y] [COMMIT]` | go back to the previous healthy commit; the one you leave is put on hold |
| `scripts/backup.sh [-q] [--keep N]` | database dump + uploads archive into `backups/`, newest 10 kept |
| `scripts/restore.sh [-y] [--db F] [--uploads F]` | replace the data from a backup (asks first, backs up the current data before) |

Migrations run automatically at start (`db:prepare`). A rollback does not undo migrations; use `restore.sh` if a migration must be undone. None of the scripts runs `docker compose down -v`; do not run it by hand, it deletes the volumes.

Nightly backup: `0 3 * * * cd /opt/ruby_blog && scripts/backup.sh -q`

## 4. Everyday commands

```bash
docker compose ps
docker compose logs -f web          # logs are rotated (3 x 10 MB per container)
docker compose exec web bundle exec rails console
```

Mail (password reset) is off until `SMTP_ADDRESS`, `SMTP_USERNAME`, `SMTP_PASSWORD` are set in `.env`; without them reset mails are dropped.

## 5. Limits worth knowing

- One Puma process with 5 threads and SQLite: fine for a demo, not for heavy write traffic. Rate-limit counters live in memory and reset on restart.
- Uploads: JPEG/PNG/GIF, 5 MB each, at most 3 per article, one per comment; nginx rejects bodies over 16 MB (1 MB elsewhere).
- Ruby 3.1 and Rails 6.1 are past end of life. Some gem advisories can only be fixed by moving to Rails 7+ and Ruby 3.2+.
- The pages load Tailwind, jQuery, CKEditor, Flowbite and Font Awesome from public CDNs, so visitors need internet access; no Content-Security-Policy is set because of that.
