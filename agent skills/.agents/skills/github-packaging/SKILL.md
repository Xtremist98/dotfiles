---
name: github-packaging
description: >
  Publish, list, and delete GitHub Packages (generic packages) and create
  Releases with downloadable assets, using the REST + GraphQL APIs when `gh`
  auth or the web UI isn't enough. Use when asked to "publish a package to
  GitHub", "delete a package from GitHub Packages", "add a release asset", or
  when `gh auth` is broken and API calls need a Personal Access Token. Also
  covers fixing `gh auth login` (invalid token / missing `read:org` scope).
---

# GitHub Packages & Releases

SSH key auth covers `git push` but **NOT** the GitHub API (Packages, Releases,
`gh` CLI). API work needs a Personal Access Token (PAT).

## PAT scopes needed
- Publish generic package: `write:packages` (+ `read:packages`).
- Delete a package version: `delete:packages` + `read:packages`.
- Create a Release / upload asset: `repo` (or `public_repo`).
- `gh auth login --with-token`: requires `read:org` (or `admin:org`) or it
  fails with `error validating token: missing required scope 'read:org'`.
- Store the PAT in `/tmp/ghtoken` (`chmod 600`), reference it as
  `$(cat /tmp/...)` so it never appears in command output, and `rm -f` it after.

## Publish a generic package (tarball / pkg.tar.zst)
```bash
curl -sS -X PUT \
  -u "USERNAME:$(cat /tmp/ghtoken)" \
  -H "Accept: application/vnd.github+json" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @nordgui-1.1.0-1-any.pkg.tar.zst \
  "https://maven.pkg.github.com/USERNAME/REPO/packages/generic/PKGNAME/1.1.0/nordgui-1.1.0-1-any.pkg.tar.zst"
# -> HTTP 200 "Successfully registered maven upload: ..."
```
Note: even though the host is `maven.pkg.github.com`, it registers as a
**generic** package and shows under the repo's Packages tab.

## Delete a generic package (REST API does NOT support `generic` type)
`GET /users/{user}/packages/generic/...` returns 422 `package_type parameter
is invalid`. Use the **GraphQL API** instead:
```bash
# 1. find package + version id
Q='{ "query": "query { user(login: \"USER\") { packages(first: 20) { nodes { name id versions(first: 20) { nodes { id version } } } } } }" }'
curl -sS -H "Authorization: Bearer $(cat /tmp/ghtoken)" -H "Content-Type: application/json" \
  -X POST https://api.github.com/graphql -d "$Q"
# package name looks like "packages.generic.nordgui"; grab the version id (PV_...)

# 2. delete that version
Q='{ "query": "mutation { deletePackageVersion(input: {packageVersionId: \"PV_xxxx\"}) { success } }" }'
curl -sS -H "Authorization: Bearer $(cat /tmp/ghtoken)" -H "Content-Type: application/json" \
  -X POST https://api.github.com/graphql -d "$Q"
# -> {"data":{"deletePackageVersion":{"success":true}}}
```
After deletion a temporary `deleted_<uuid>` tombstone may remain in the
packages list for a while — it is not user-visible in the Packages tab and
clears itself. Deleting the package version does **NOT** touch any Release.

## Create a Release + upload an asset
```bash
# create (can target an existing tag)
curl -sS -X POST -H "Authorization: Bearer $(cat /tmp/ghtoken)" \
  -H "Content-Type: application/json" \
  "https://api.github.com/repos/USER/REPO/releases" \
  -d '{"tag_name":"v1.1.0","name":"NordGUI 1.1.0","body":"...","draft":false,"prerelease":false}'
# get id: GET /repos/USER/REPO/releases/tags/v1.1.0  -> .id
curl -sS -X POST -H "Authorization: Bearer $(cat /tmp/ghtoken)" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @file.pkg.tar.zst \
  "https://uploads.github.com/repos/USER/REPO/releases/REL_ID/assets?name=file.pkg.tar.zst"
```
Use a real timeout (`--max-time 90`); an empty release id in the URL makes
curl hang.

## Fixing `gh` auth
- Symptom: `gh auth status` → "The token in default is invalid."
- `git push` over SSH keeps working; only the API/`gh` is affected.
- Device-code TUI sometimes renders no code in certain shells — avoid it.
- Reliable fix: `gh auth login --with-token < /tmp/ghtoken` with a PAT that
  includes `read:org` (or `admin:org`). After success, `gh auth status` shows
  ✓ and the git protocol defaults to **https** (token-based); the SSH key still
  works if you prefer it (`gh config set git_protocol ssh`).
