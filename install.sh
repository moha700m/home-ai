#!/usr/bin/env bash
# pc-local — تثبيت بنقرة واحدة (macOS / Linux)
# الاستخدام:
#   curl -fsSL https://raw.githubusercontent.com/moha700m/home-ai/main/install.sh | bash
set -euo pipefail

REPO_OWNER="${HOME_AI_OWNER:-moha700m}"
REPO_NAME="${HOME_AI_REPO:-home-ai}"
INSTALL_DIR="${HOME_AI_DIR:-$HOME/home-ai}"
PORT="${HOME_AI_PORT:-3847}"
BRANCH="${HOME_AI_BRANCH:-main}"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { printf "${CYAN}==>${NC} %s\n" "$*"; }
ok()    { printf "${GREEN}OK${NC}  %s\n" "$*"; }
warn()  { printf "${YELLOW}!!${NC}  %s\n" "$*"; }
fail()  { printf "${RED}ERR${NC} %s\n" "$*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "مطلوب الأمر: $1"
}

ensure_path_local_bin() {
  local bin="$HOME/.local/bin"
  mkdir -p "$bin"
  case ":$PATH:" in
    *":$bin:"*) ;;
    *) export PATH="$bin:$PATH" ;;
  esac
  if [ -n "${SHELL:-}" ] && [ -f "${HOME}/.zshrc" ]; then
    if ! grep -q '.local/bin' "${HOME}/.zshrc" 2>/dev/null; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.zshrc"
      ok "أُضيف ~/.local/bin إلى ~/.zshrc"
    fi
  elif [ -f "${HOME}/.bashrc" ]; then
    if ! grep -q '.local/bin' "${HOME}/.bashrc" 2>/dev/null; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.bashrc"
      ok "أُضيف ~/.local/bin إلى ~/.bashrc"
    fi
  fi
}

install_node_hint() {
  fail "Node.js 22+ غير موجود. ثبّته من https://nodejs.org ثم أعد تشغيل السكربت."
}

clone_via_git() {
  local url="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
  info "استنساخ من GitHub: ${url}"
  if [ -d "${INSTALL_DIR}/.git" ]; then
    info "المجلد موجود — تحديث..."
    git -C "$INSTALL_DIR" fetch --depth 1 origin "$BRANCH"
    git -C "$INSTALL_DIR" checkout "$BRANCH"
    git -C "$INSTALL_DIR" pull --ff-only origin "$BRANCH" || true
  else
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone --branch "$BRANCH" --depth 1 "$url" "$INSTALL_DIR"
  fi
}

clone_via_origin() {
  ensure_path_local_bin
  if ! command -v origin >/dev/null 2>&1; then
    info "تثبيت Origin CLI..."
    curl -fsSL https://downloads.cursor.com/origin/install.sh | sh
    ensure_path_local_bin
  fi
  command -v origin >/dev/null 2>&1 || fail "origin غير موجود بعد التثبيت. نفّذ: export PATH=\"\$HOME/.local/bin:\$PATH\""
  if [ ! -d "${INSTALL_DIR}/.git" ]; then
    info "تسجيل الدخول لـ Origin (إن لزم)..."
    origin auth status >/dev/null 2>&1 || origin auth login
    info "استنساخ عبر Origin: ${REPO_OWNER}/${REPO_NAME}"
    # clone into parent then rename if needed
    local parent
    parent="$(dirname "$INSTALL_DIR")"
    mkdir -p "$parent"
    (
      cd "$parent"
      if [ -d "$REPO_NAME" ] && [ "$(cd "$REPO_NAME" && pwd)" != "$(mkdir -p "$INSTALL_DIR" && cd "$INSTALL_DIR" && pwd)" ]; then
        warn "يوجد مجلد ${REPO_NAME} مسبقاً"
      fi
      origin repo clone "justmgz/${REPO_NAME}" || origin repo clone "${REPO_OWNER}/${REPO_NAME}"
      if [ -d "$parent/$REPO_NAME" ] && [ "$parent/$REPO_NAME" != "$INSTALL_DIR" ]; then
        mv "$parent/$REPO_NAME" "$INSTALL_DIR"
      fi
    )
  else
    info "المجلد موجود — تخطي الـ clone"
  fi
}

main() {
  info "تثبيت pc-local (home-ai)"
  need_cmd curl
  need_cmd git

  if ! command -v node >/dev/null 2>&1; then
    install_node_hint
  fi
  local major
  major="$(node -v | sed 's/^v//' | cut -d. -f1)"
  if [ "$major" -lt 22 ]; then
    warn "يُفضّل Node 22+ (عندك $(node -v))"
  else
    ok "Node $(node -v)"
  fi

  # جرّب GitHub أولاً؛ إذا فشل (خاص/غير موجود) استخدم Origin
  if git ls-remote "https://github.com/${REPO_OWNER}/${REPO_NAME}.git" HEAD >/dev/null 2>&1 \
    || git ls-remote "https://github.com/justmgz/${REPO_NAME}.git" HEAD >/dev/null 2>&1; then
    if ! git ls-remote "https://github.com/${REPO_OWNER}/${REPO_NAME}.git" HEAD >/dev/null 2>&1; then
      REPO_OWNER="justmgz"
    fi
    clone_via_git
  else
    warn "المستودع غير ظاهر على GitHub العام — التثبيت عبر Origin"
    REPO_OWNER="justmgz"
    clone_via_origin
  fi

  [ -f "${INSTALL_DIR}/package.json" ] || fail "ما لقيت package.json في ${INSTALL_DIR}"

  info "تثبيت الحزم (npm install)..."
  (
    cd "$INSTALL_DIR"
    npm install
  )
  ok "الحزم جاهزة"

  info "التحقق من الوكيل..."
  (
    cd "$INSTALL_DIR"
    npx --yes "@cursor/bdk@0.2.24" validate --dir . >/dev/null
  )
  ok "validate نجح"

  cat <<EOF

${GREEN}تم التثبيت${NC}
المجلد: ${INSTALL_DIR}

تشغيل الـ playground:
  cd ${INSTALL_DIR}
  npm run dev

ثم افتح: http://127.0.0.1:${PORT}/playground

للمحادثة بالذكاء الاصطناعي (مرة واحدة):
  cd ${INSTALL_DIR}
  npx @cursor/bdk login

فحص قدرة الجهاز مباشرة:
  cd ${INSTALL_DIR}
  npm run call:specs

EOF

  if [ "${HOME_AI_START:-0}" = "1" ]; then
    info "تشغيل الخادم على المنفذ ${PORT}..."
    cd "$INSTALL_DIR"
    exec npx --yes "@cursor/bdk@0.2.24" serve --dir . --mode single --dev --port "$PORT"
  fi
}

main "$@"
