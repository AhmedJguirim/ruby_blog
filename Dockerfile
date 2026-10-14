# syntax=docker/dockerfile:1
#
# Targets:  web   -> Rails + Puma (default, last stage)
#           nginx -> nginx with the precompiled assets baked in
#
# Ruby 3.1 is the newest version Rails 6.1 runs on (the app was on 2.7.5).
# The build stage uses the full Debian image (compilers and headers
# included), so no apt-get is needed anywhere; sqlite3 ships precompiled.
ARG RUBY_BUILD_IMAGE=ruby:3.1.7-bookworm
ARG RUBY_RUNTIME_IMAGE=ruby:3.1.7-slim-bookworm
# webpacker 5 / webpack 4 need Node <= 16 (OpenSSL 3 breaks their md4 hashing)
ARG NODE_IMAGE=node:16-bookworm-slim
ARG NGINX_IMAGE=nginxinc/nginx-unprivileged:1.27-alpine

FROM ${NODE_IMAGE} AS node

# ---------------------------------------------------------------- build
FROM ${RUBY_BUILD_IMAGE} AS build
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /opt /opt
RUN ln -s /opt/yarn-*/bin/yarn /usr/local/bin/yarn

ENV RAILS_ENV=production \
    NODE_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_PATH=/usr/local/bundle
WORKDIR /rails

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install --jobs 4 \
 && rm -rf "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY . .
# Assets are compiled at build time. The values below only exist for this
# RUN (they are not stored in the image) so the app can boot while compiling.
RUN SECRET_KEY_BASE=build-time-only-not-a-secret-build-time-only \
    JWT_SECRET_KEY=build-time-only-not-a-secret-build-time-only \
    SECRET_KEY_BASE_DUMMY=1 \
    bundle exec rails assets:precompile \
 && rm -rf node_modules tmp/cache app/assets/builds/*.map log/* \
 && mkdir -p tmp/pids log storage

# ---------------------------------------------------------------- nginx
FROM ${NGINX_IMAGE} AS nginx
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=build /rails/public /usr/share/nginx/html

# ---------------------------------------------------------------- web
FROM ${RUBY_RUNTIME_IMAGE} AS web
ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=1 \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_PATH=/usr/local/bundle \
    DATABASE_PATH=/data/db/production.sqlite3 \
    PORT=3000
WORKDIR /rails

RUN groupadd --gid 1000 rails \
 && useradd --uid 1000 --gid 1000 --create-home --shell /usr/sbin/nologin rails \
 && mkdir -p /data/db \
 && chown rails:rails /data/db

COPY --from=build --chown=rails:rails /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=rails:rails /rails /rails
COPY --chown=rails:rails docker/entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint \
 && chown -R rails:rails /rails/storage /rails/tmp /rails/log

USER rails
EXPOSE 3000
ENTRYPOINT ["entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
