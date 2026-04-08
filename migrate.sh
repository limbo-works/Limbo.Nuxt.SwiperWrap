#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT"

echo "==> Running Nuxt 4 + ESLint + release-please migration in: $(pwd)"

# 1) Delete legacy ESLint and manifest variants if they exist.
for f in \
  .nvmrc \
  .eslintrc \
  .eslintrc.js \
  .eslintrc.cjs \
  .eslintrc.mjs \
  .eslintrc.ts \
  .release-please-manifest.yml \
  .release-please-manifest.yaml
  do
  if [[ -e "$f" ]]; then
    rm -f "$f"
    echo "deleted $f"
  fi
done

# 2) Recreate .nvmrc from scratch.
cat > .nvmrc <<'EOF'
24
EOF
echo "added .nvmrc"

# 3) Recreate .npmrc from scratch.
cat > .npmrc <<'EOF'
@limbo-works:registry=https://npm.pkg.github.com

shamefully-hoist=true
strict-peer-dependencies=false
EOF
echo "wrote .npmrc"

# 4) Recreate release workflow from scratch.
mkdir -p .github/workflows
rm -f .github/workflows/release-please.yml
cat > .github/workflows/release-please.yml <<'EOF'
name: Release Please and Publish

on:
    push:
        branches:
            - main

permissions:
    contents: write
    pull-requests: write
    packages: write

jobs:
    release-please:
        runs-on: ubuntu-latest
        steps:
            - uses: googleapis/release-please-action@v4
              id: release
              with:
                  target-branch: main
                  config-file: release-please-config.json
                  manifest-file: .release-please-manifest.json
                  token: ${{ secrets.GITHUB_TOKEN }}

            - uses: actions/checkout@v6
              if: ${{ steps.release.outputs.release_created }}

            - uses: actions/setup-node@v6
              with:
                  node-version: 24
                  registry-url: https://npm.pkg.github.com/
              if: ${{ steps.release.outputs.release_created }}

            - run: yarn
              env:
                  NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
              if: ${{ steps.release.outputs.release_created }}

            - run: yarn publish
              env:
                  NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
              if: ${{ steps.release.outputs.release_created }}
EOF
echo "rewrote .github/workflows/release-please.yml"

# 5) Ensure release-please config exists.
cat > release-please-config.json <<'EOF'
{
  "packages": {
    ".": {
      "changelog-path": "CHANGELOG.md",
      "release-type": "node",
      "bump-minor-pre-major": false,
      "bump-patch-for-minor-pre-major": false,
      "draft": false,
      "prerelease": false
    }
  },
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json"
}
EOF
echo "wrote release-please-config.json"

# 6) Ensure flat ESLint config exists.
cat > eslint.config.mjs <<'EOF'
import config from '@limbo-works/lint-configs/eslint.config.simple.mjs';
export default [...config];
EOF
echo "wrote eslint.config.mjs"

# 7) Ensure release-please manifest JSON exists and matches package version if possible.
if [[ -f package.json ]]; then
  PKG_VERSION="$(node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('package.json','utf8'));process.stdout.write(String(p.version||'1.0.0'));" 2>/dev/null || echo "1.0.0")"
else
  PKG_VERSION="1.0.0"
fi

cat > .release-please-manifest.json <<EOF
{
    ".": "${PKG_VERSION}"
}
EOF
echo "wrote .release-please-manifest.json (${PKG_VERSION})"

# 8) Update package.json when present.
if [[ -f package.json ]]; then
  node <<'EOF'
const fs = require('fs');
const path = 'package.json';
const pkg = JSON.parse(fs.readFileSync(path, 'utf8'));

pkg.main = './nuxt.config.ts';
pkg.devDependencies = pkg.devDependencies || {};
pkg.devDependencies['@limbo-works/lint-configs'] = '^2.1.0';
pkg.devDependencies['nuxt'] = '^4';

pkg.scripts = pkg.scripts || {};
if (!pkg.scripts['lint:fix']) {
  pkg.scripts['lint:fix'] = 'yarn prettier --write . && yarn eslint --fix --quiet .';
}

fs.writeFileSync(path, JSON.stringify(pkg, null, '\t') + '\n');
EOF
  echo "updated package.json"
fi

# 9) Rename nuxt config js -> ts if needed.
if [[ -f nuxt.config.js && ! -f nuxt.config.ts ]]; then
  mv nuxt.config.js nuxt.config.ts
  echo "renamed nuxt.config.js -> nuxt.config.ts"
fi

# 10) Ensure tsconfig extends Nuxt generated config.
if [[ ! -f tsconfig.json ]]; then
  cat > tsconfig.json <<'EOF'
{
  "extends": "./.nuxt/tsconfig.json"
}
EOF
  echo "created tsconfig.json"
fi

# 11) Upgrade dependencies to latest when Yarn is available as well as preparation and linting.
if [[ -f package.json ]] && command -v yarn >/dev/null 2>&1; then
  yarn
  yarn upgrade --latest
  echo "ran yarn upgrade --latest"
  yarn nuxi prepare
  echo "ran yarn nuxi prepare"
  yarn lint:fix
  echo "ran yarn lint:fix"
fi

echo "==> Migration complete"
