#!/usr/bin/env bash
# 问学 Quest Academy — 双端 Release 构建与打包脚本
#
# 用途：清理旧产物 → 构建 Android（按 ABI 分包）与 Windows → 按自动更新的
#       资产命名规则重命名并输出到 dist/，可直接上传到 GitHub Release。
#
# 命名规则（供 update_service 匹配，详见 AGENTS.md「版本发布与自动更新」）：
#   Android  quest-academy-<version>-android-<abi>.apk   （abi: arm64-v8a / armeabi-v7a / x86_64）
#   Windows  quest-academy-<version>-windows-x64.zip     （包内为 Release 目录内容）
#
# 用法（Git Bash）：
#   ./scripts/build_release.sh              # 构建双端
#   ./scripts/build_release.sh android      # 仅 Android
#   ./scripts/build_release.sh windows      # 仅 Windows
#
# 前置条件：
#   - flutter / java / nuget.exe 已在 PATH
#   - ANDROID_HOME 已设置（Android 构建）
#   - android/key.properties 与 android/app/quest-release.jks 存在（release 签名）
set -euo pipefail

# ── 路径与常量 ─────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$PROJECT_DIR/dist"

# nuget.exe 默认位置（flutter_tts 的 Windows 构建需要）
NUGET_DIR="${NUGET_DIR:-$HOME/.workbuddy/binaries/nuget}"
if [ -d "$NUGET_DIR" ]; then
  export PATH="$NUGET_DIR:$PATH"
fi

# ── 读取版本号 ─────────────────────────────────────────────
# 取自 pubspec.yaml 的 `version: x.y.z+n`，只取 x.y.z 部分。
VERSION="$(grep -E '^version:' "$PROJECT_DIR/pubspec.yaml" \
  | head -1 | sed -E 's/^version:[[:space:]]*//; s/\+.*$//' | tr -d '\r')"
if [ -z "$VERSION" ]; then
  echo "❌ 无法从 pubspec.yaml 读取版本号" >&2
  exit 1
fi
echo "📦 构建版本：v$VERSION"

TARGET="${1:-all}"

# ── 清理旧产物 ─────────────────────────────────────────────
clean() {
  echo "🧹 清理旧构建产物…"
  rm -rf "$PROJECT_DIR/build"
  rm -rf "$PROJECT_DIR/android/build" "$PROJECT_DIR/android/app/build"
  rm -f "$PROJECT_DIR/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"
  rm -rf "$DIST_DIR"
  mkdir -p "$DIST_DIR"
}

# ── Android ────────────────────────────────────────────────
build_android() {
  echo "🤖 构建 Android（按 ABI 分包）…"
  # --no-tree-shake-icons：本项目启用图标树摇会导致构建失败，详见 AGENTS.md
  (cd "$PROJECT_DIR" && flutter build apk --release --split-per-abi --no-tree-shake-icons)

  local apk_dir="$PROJECT_DIR/build/app/outputs/flutter-apk"
  # flutter 输出命名为 app-<abi>-release.apk，重命名以匹配自动更新匹配规则
  declare -A ABI_MAP=(
    ["app-arm64-v8a-release.apk"]="arm64-v8a"
    ["app-armeabi-v7a-release.apk"]="armeabi-v7a"
    ["app-x86_64-release.apk"]="x86_64"
  )
  for src in "${!ABI_MAP[@]}"; do
    local abi="${ABI_MAP[$src]}"
    if [ -f "$apk_dir/$src" ]; then
      cp "$apk_dir/$src" "$DIST_DIR/quest-academy-$VERSION-android-$abi.apk"
      echo "  ✅ quest-academy-$VERSION-android-$abi.apk"
    fi
  done
}

# ── Windows ────────────────────────────────────────────────
build_windows() {
  echo "🪟 构建 Windows…"
  # --no-tree-shake-icons：同 Android，启用图标树摇会导致构建失败
  (cd "$PROJECT_DIR" && flutter build windows --release --no-tree-shake-icons)

  local release_dir="$PROJECT_DIR/build/windows/x64/runner/Release"
  if [ ! -d "$release_dir" ]; then
    echo "❌ 未找到 Windows 构建输出：$release_dir" >&2
    exit 1
  fi

  local zip_name="quest-academy-$VERSION-windows-x64.zip"
  # 在 Release 目录内打包，保证 ZIP 根目录即为可直接运行的程序文件
  (cd "$release_dir" && zip -r -q "$DIST_DIR/$zip_name" .)
  echo "  ✅ $zip_name"
}

# ── 校验和 ─────────────────────────────────────────────────
checksums() {
  echo "🔐 生成 SHA256 校验和…"
  (cd "$DIST_DIR" && sha256sum * > "checksums-sha256.txt")
}

# ── 执行 ───────────────────────────────────────────────────
mkdir -p "$DIST_DIR"
case "$TARGET" in
  android) clean; build_android; checksums ;;
  windows) clean; build_windows; checksums ;;
  all)     clean; build_android; build_windows; checksums ;;
  *)
    echo "用法：$0 [android|windows|all]" >&2
    exit 1
    ;;
esac

echo ""
echo "🎉 完成！产物位于：$DIST_DIR"
ls -lh "$DIST_DIR"
