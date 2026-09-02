# --- Стадия 1: сборка статического сайта ---
FROM hugomods/hugo:exts-0.140.2 AS build
WORKDIR /src
COPY . .
RUN hugo --minify

# --- Стадия 2: раздача через nginx ---
FROM nginx:1.30-alpine
COPY --from=build /src/public /usr/share/nginx/html
COPY docker-entrypoint.d/40-inject-pod-info.sh /docker-entrypoint.d/40-inject-pod-info.sh
RUN chmod +x /docker-entrypoint.d/40-inject-pod-info.sh
EXPOSE 80
