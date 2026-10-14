# Ruby Blog (TheoryKraft)

A community blogging app built with Ruby on Rails. People write articles ("theories"), tag them with `#hashtags`, attach images, comment, vote, and criticise comments. There is a server-rendered web UI and a small JSON API with JWT login.

## Features

- Sign-up, login and password reset (Devise)
- Articles with automatic tags, up to 3 images each, pagination
- Comments (with an optional image), up/down votes, criticisms on comments
- JSON API under `/api/v1` (articles, comments, criticisms) with JWT auth
- Safe uploads: JPEG/PNG/GIF only, checked on the file content, 5 MB max
- Rate limiting on login, sign-up, password reset, posting, uploads and search

## Stack

Ruby 3.1 · Rails 6.1 · SQLite · Puma · Webpacker · Tailwind · Devise + JWT · RSpec · Docker, nginx

## Run it with Docker

Needs Docker with the compose plugin.

```bash
git clone https://github.com/AhmedJguirim/ruby_blog.git && cd ruby_blog
scripts/init-env.sh --email you@example.com --url http://localhost:18090
docker compose up -d --build
```

Open <http://localhost:18090> and sign in with the email and the password printed by `init-env.sh`.
Everything secret lives in the git-ignored `.env`; nothing is baked into the images.

## Deploy and update on a server

See [DOCKER.md](DOCKER.md). In short, after the first start:

```bash
scripts/deploy.sh      # backup, pull, build, restart, health check, automatic rollback
```

## Develop without Docker

```bash
bundle install && yarn install
bin/rails db:setup
bin/dev                # http://localhost:3000
bundle exec rspec
```

Needs Ruby 3.1 and Node 16 (webpack 4).

## License

MIT, see [LICENSE](LICENSE).
