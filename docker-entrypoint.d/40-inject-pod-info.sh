#!/bin/sh
# Подставляет реальное имя пода и узла (из переменных окружения,
# заданных через Downward API в Deployment) в уже собранные статические
# HTML-файлы Hugo. Выполняется официальным nginx-образом автоматически
# при каждом старте контейнера (механизм /docker-entrypoint.d/), поэтому
# каждая реплика показывает СВОИ реальные данные, а не то, что было
# на этапе сборки образа.
set -e

POD_NAME="${POD_NAME:-unknown-pod}"
NODE_NAME="${NODE_NAME:-unknown-node}"

find /usr/share/nginx/html -name "*.html" -type f -print0 | \
  xargs -0 sed -i \
    -e "s/__POD_NAME__/${POD_NAME}/g" \
    -e "s/__NODE_NAME__/${NODE_NAME}/g"

echo "[inject-pod-info] Подставлено: POD_NAME=${POD_NAME}, NODE_NAME=${NODE_NAME}"
