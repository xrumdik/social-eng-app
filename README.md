# social-eng-app — Hugo-сайт "Социальная инженерия"

Это репозиторий **с кодом** — Hugo-сайт для тестирования (6 статей об атаках социальной инженерии), Dockerfile и workflow сборки образа. Манифесты для развёртывания в кластер находятся в **отдельном** архиве/репозитории `k8s-gitops` (см. соответствующий README там).

## Структура

```
.
├── hugo.toml                          # конфигурация Hugo
├── content/                           # markdown-контент (6 статей + главная)
├── layouts/                           # минималистичные HTML-шаблоны (без внешней темы)
├── static/css/style.css               # стили
├── Dockerfile                         # multi-stage: hugo build → nginx
├── docker-entrypoint.d/
│   └── 40-inject-pod-info.sh          # подстановка имени пода/узла в рантайме
└── .github/workflows/build.yml        # CI: сборка образа + пуш в GHCR + обновление k8s-gitops
```

## Особенность: видно, какой под и узел ответили на запрос

Внизу каждой страницы сайта — строка `Обслужено подом: ... (нода: ...)`. Это наглядное подтверждение того, что запросы реально обслуживаются разными подами на разных нодах кластера. Обновляйте страницу в браузере несколько раз — при `replicas: 2` без sticky-сессий значения должны чередоваться.

Механизм: Hugo — статический генератор, значения нельзя подставить "на лету" при каждом запросе. Имя пода/узла передаётся через **Downward API** в переменные окружения контейнера (`POD_NAME`, `NODE_NAME` — заданы в `k8s-gitops`), а скрипт `docker-entrypoint.d/40-inject-pod-info.sh` (запускается официальным `nginx`-образом автоматически при **каждом старте контейнера**) подставляет их в уже собранные HTML-файлы.

## Как развернуть — шаг за шагом

### 1. Замените плейсхолдер логина

В файле `.github/workflows/build.yml` замените `<ваш-github-username>` на ваш реальный логин GitHub (там, где `repository: <ваш-github-username>/k8s-gitops`) — это нужно, чтобы CI знал, в какой репозиторий с манифестами коммитить обновлённый тег образа.

Через любой текстовый редактор, либо командой:

**PowerShell (Windows)**:
```powershell
(Get-Content .github\workflows\build.yml) -replace '<ваш-github-username>', 'ваш_реальный_логин' | Set-Content .github\workflows\build.yml
```

**Git Bash / Linux**:
```bash
sed -i 's/<ваш-github-username>/ваш_реальный_логин/g' .github/workflows/build.yml
```

### 2. Создайте пустой репозиторий на GitHub

`github.com → New repository → social-eng-app` (Public или Private — не имеет значения; при создании **не** добавляйте README/`.gitignore` через веб — они уже есть локально).

### 3. Добавьте секрет для CI

`Settings → Secrets and variables → Actions → New repository secret`:
- Имя: `GITOPS_REPO_TOKEN`
- Значение: Personal Access Token с правом `repo` (создаётся в `Settings → Developer settings → Personal access tokens`). Если уже создавали такой токен при настройке демо-приложения для Argo CD — переиспользуйте его.

### 4. Загрузите репозиторий

```bash
git init
git add .
git commit -m "Initial commit: Hugo social engineering awareness site"
git branch -M main
git remote add origin https://github.com/ваш_логин/social-eng-app.git
git push -u origin main
```

При запросе логина/пароля — в поле пароля вставьте **токен**, не обычный пароль от аккаунта.

Push автоматически запустит GitHub Actions (вкладка **Actions** в репозитории на GitHub) — сборка образа и публикация в `ghcr.io/ваш_логин/social-eng-app`.

## Локальная проверка перед пушем (опционально)

Если есть Docker на своей машине:

```bash
docker build -t social-eng-app-test .
docker run --rm -p 8080:80 -e POD_NAME=test-pod -e NODE_NAME=test-node social-eng-app-test
```

Откройте `http://localhost:8080` — внизу страницы должно быть `test-pod` / `test-node`.
