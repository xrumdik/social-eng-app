# --- Стадия 1: сборка статического сайта ---
FROM hugomods/hugo:exts-0.140.2 AS build
WORKDIR /src
COPY . .
RUN hugo --minify

# --- Стадия 2: раздача через nginx ---
FROM nginxinc/nginx-unprivileged:1.30-alpine
COPY --from=build /src/public /usr/share/nginx/html
COPY docker-entrypoint.d/40-inject-pod-info.sh /docker-entrypoint.d/40-inject-pod-info.sh
RUN chmod +x /docker-entrypoint.d/40-inject-pod-info.sh

# Заранее отдаём владение статикой пользователю nginx (uid 101), чтобы
# entrypoint-скрипт (перезапись HTML при старте) мог писать в эти файлы,
# даже когда контейнер реально запущен без root. Непривилегированный
# пользователь задаётся не здесь через USER (порт 80 < 1024 требует root
# или capability NET_BIND_SERVICE — обычный USER тут привёл бы к падению
# при старте), а через securityContext в k8s Deployment: runAsUser +
# точечно добавленная capability NET_BIND_SERVICE вместо полного root-доступа.
RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/run

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:8080/ || exit 1

EXPOSE 8080
