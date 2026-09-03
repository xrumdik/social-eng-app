# --- Стадия 1: сборка статического сайта ---
FROM hugomods/hugo:exts-0.140.2 AS build
WORKDIR /src
COPY . .
RUN hugo --minify

# --- Стадия 2: раздача через nginx ---
FROM nginxinc/nginx-unprivileged:1.30-alpine

# Этот базовый образ сам переключает пользователя на непривилегированного
# (uid 101) уже внутри себя — явно возвращаемся к root на время наших
# операций копирования и выставления прав, иначе COPY/RUN ниже могут
# упасть с ошибкой доступа, унаследовав чужого непривилегированного
# пользователя раньше времени.
USER root

COPY --from=build /src/public /usr/share/nginx/html
COPY docker-entrypoint.d/40-inject-pod-info.sh /docker-entrypoint.d/40-inject-pod-info.sh
RUN chmod +x /docker-entrypoint.d/40-inject-pod-info.sh

# Отдаём владение статикой пользователю с uid 101 (тот же, что и рантайм-
# пользователь образа), чтобы entrypoint-скрипт мог писать в эти файлы
# при каждом старте контейнера. Используем числовой UID/GID, а не имя
# "nginx" — в этом варианте образа именованный пользователь может
# называться иначе или отсутствовать в /etc/passwd.
RUN chown -R 101:101 /usr/share/nginx/html /var/cache/nginx /var/run

# Обязательно возвращаемся к непривилегированному пользователю явно —
# иначе финальный образ остался бы запускаться от root, сводя на нет
# весь смысл перехода на nginx-unprivileged.
USER 101

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:8080/ || exit 1
EXPOSE 8080
