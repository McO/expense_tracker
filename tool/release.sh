#!/usr/bin/env bash
# One local release: bump SemVer + build number, write the changelog from task
# commits, build the signed APK, commit, tag, push, publish a GitHub Release.
#
# Usage: tool/release.sh <major|minor|patch|X.Y.Z> [--dry-run]
#
# --dry-run prints every step and the generated changelog section; it writes,
# commits, tags, pushes and publishes nothing (analyze/test/build are not run).
#
# Testing seam (honoured ONLY together with --dry-run): RELEASE_DRY_RUN_SKIP_CHECKS
# is a comma list of precondition names to skip: branch,clean,sync,gh,key.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
GH_REPO="McO/expense_tracker"

BUMP=""
DRY_RUN=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY_RUN=1 ;;
    -*) echo "Unknown flag: $a" >&2; exit 64 ;;
    *) [ -z "$BUMP" ] && BUMP="$a" || { echo "Too many arguments." >&2; exit 64; } ;;
  esac
done
if [ -z "$BUMP" ]; then
  echo "Usage: tool/release.sh <major|minor|patch|X.Y.Z> [--dry-run]" >&2
  exit 64
fi

SKIP=","
[ "$DRY_RUN" = 1 ] && SKIP=",${RELEASE_DRY_RUN_SKIP_CHECKS:-},"
skipped() { [[ "$SKIP" == *",$1,"* ]]; }
refuse() { echo "Refusing to release: $1" >&2; exit 1; }
step() { echo "==> $*"; }
run() { if [ "$DRY_RUN" = 1 ]; then echo "    [dry-run] would run: $*"; else "$@"; fi; }

step "1/7 Preconditions"
skipped branch || [ "$(git rev-parse --abbrev-ref HEAD)" = "main" ] \
  || refuse "not on main (on '$(git rev-parse --abbrev-ref HEAD)')."
skipped clean || [ -z "$(git status --porcelain)" ] \
  || refuse "working tree is not clean (commit or stash your changes)."
if ! skipped sync; then
  git fetch --quiet origin main || refuse "cannot fetch origin/main."
  [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] \
    || refuse "main is not in sync with origin/main (push or pull first)."
fi
skipped gh || gh auth status >/dev/null 2>&1 \
  || refuse "gh is not authenticated (run 'gh auth login')."
skipped key || [ -f android/key.properties ] \
  || refuse "android/key.properties is missing (run tool/create-release-key.sh)."
echo "    ok"

step "2/7 Version"
CURRENT="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml)"
NEW_VERSION_FULL="$(dart tool/release_notes.dart next pubspec.yaml "$BUMP")"
NEW_VERSION="${NEW_VERSION_FULL%%+*}"
TAG="v$NEW_VERSION"
DATE="$(date +%Y-%m-%d)"
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  refuse "tag $TAG already exists."
fi
echo "    $CURRENT -> $NEW_VERSION_FULL (tag $TAG)"

PREV_TAG="$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || true)"
if [ -n "$PREV_TAG" ]; then RANGE="$PREV_TAG..HEAD"; else RANGE="HEAD"; fi
SECTION_FILE="$(mktemp)"
git log --format=%s "$RANGE" | dart tool/release_notes.dart section "$NEW_VERSION" "$DATE" > "$SECTION_FILE"

# Restore the working files if anything fails before the release commit.
BACKUP_DIR="$(mktemp -d)"
COMMITTED=0
cleanup() {
  status=$?
  if [ "$DRY_RUN" = 0 ] && [ "$COMMITTED" = 0 ] && [ "$status" != 0 ]; then
    echo "Release failed before commit; restoring pubspec.yaml and CHANGELOG.md." >&2
    cp "$BACKUP_DIR/pubspec.yaml" pubspec.yaml
    if [ -f "$BACKUP_DIR/CHANGELOG.md" ]; then cp "$BACKUP_DIR/CHANGELOG.md" CHANGELOG.md; else rm -f CHANGELOG.md; fi
  fi
  rm -rf "$BACKUP_DIR"
}
trap cleanup EXIT
cp pubspec.yaml "$BACKUP_DIR/pubspec.yaml"
[ -f CHANGELOG.md ] && cp CHANGELOG.md "$BACKUP_DIR/CHANGELOG.md"

if [ "$DRY_RUN" = 1 ]; then
  echo "    [dry-run] would write 'version: $NEW_VERSION_FULL' to pubspec.yaml"
else
  sed -i.bak "s/^version:.*/version: $NEW_VERSION_FULL/" pubspec.yaml && rm -f pubspec.yaml.bak
fi

step "3/7 Checks"
run flutter analyze
run flutter test

step "4/7 Changelog (commits ${RANGE})"
if [ "$DRY_RUN" = 1 ]; then
  echo "    [dry-run] would prepend to CHANGELOG.md:"
  sed 's/^/    | /' "$SECTION_FILE"
else
  dart tool/release_notes.dart prepend CHANGELOG.md "$SECTION_FILE"
fi

step "5/7 Build"
APK_OUT="build/release/expense-tracker-$NEW_VERSION.apk"
run flutter build apk --release
if [ "$DRY_RUN" = 1 ]; then
  echo "    [dry-run] would copy build/app/outputs/flutter-apk/app-release.apk to $APK_OUT"
else
  mkdir -p build/release
  cp build/app/outputs/flutter-apk/app-release.apk "$APK_OUT"
fi

step "6/7 Commit and tag"
if [ "$DRY_RUN" = 1 ]; then
  echo "    [dry-run] would run: git add pubspec.yaml CHANGELOG.md"
  echo "    [dry-run] would run: git commit -m 'chore(release): $TAG'"
  echo "    [dry-run] would run: git tag -a $TAG -m 'Release $TAG'"
  echo "    [dry-run] would run: git push origin main $TAG"
else
  git add pubspec.yaml CHANGELOG.md
  if ! git commit -m "chore(release): $TAG"; then
    git reset -q HEAD -- pubspec.yaml CHANGELOG.md || true
    echo "git commit failed; pubspec.yaml and CHANGELOG.md were unstaged and are restored." >&2
    exit 1
  fi
  COMMITTED=1
  git tag -a "$TAG" -m "Release $TAG"
  if ! git push origin main "$TAG"; then
    echo "Push failed after the release commit and tag were created locally." >&2
    echo "  Retry:  git push origin main $TAG" >&2
    echo "  Abort:  git tag -d $TAG && git reset --hard HEAD~1   (discards the release commit)" >&2
    exit 1
  fi
fi

step "7/7 Publish"
run gh release create "$TAG" "$APK_OUT" --repo "$GH_REPO" --title "$TAG" --notes-file "$SECTION_FILE" \
  || { echo "The commit and tag are pushed but publishing failed; rerun the gh release create command by hand." >&2; exit 1; }
rm -f "$SECTION_FILE"
echo "Done: $TAG"
