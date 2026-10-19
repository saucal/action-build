# Build Action

Use this action to build assets and install dependencies.

## Getting Started

You should be all set with these defaults.

```yml
- name: Build
  uses: saucal/action-build@v2
  with:
    path: "source" # repo where the source code root is installed
    satis_key: ${{ secrets.SAUCAL_SATIS_KEY }} # Make sure you have set the token in GH_REPO/settings/secrets/actions
```

This should be compatible with any codebase structure, but it has been tested with a wp-content rooted structure (similar to [VIP Skeleton](https://github.com/Automattic/vip-go-skeleton))

## Full options

```yml
- uses: saucal/action-build@v2
  with:
    # Relative path to where the source code is
    # Typically where package.json and composer.json are located
    # NOTE: This action does not clone the repo
    path: ""

    # SatisPress key, to use with our SatisPress packages.saucal.com
    satis_key: ""

    # Node version to use for node build process
    node_version: "16"

    # PHP version to use for composer installation
    php_version: "latest"

    # Composer version to use during dependency installation
    composer_version: "v2"

    # Do a validation of the composer.json and composer.lock syncronzation
    validate-composer: "true"

    # Optional newline-separated list of dependency manifest paths (relative to
    # `path`). When set, the action skips manifest discovery entirely. Supply
    # this from an upstream prepare step to avoid scanning large repos. When
    # empty, the action discovers manifests via `git ls-files` (index read, no
    # filesystem walk; tracked-only so vendor/node_modules are skipped), falling
    # back to a pruned `find` if `path` is not a git checkout.
    manifest_list: ""
```

## Which node packages build

- **npm:** `npm ci` + `build` / `test` at the root, or `npm -ws` over the `workspaces` globs in `package.json`.
- **pnpm:** `pnpm-workspace.yaml` is the list of packages allowed to build. With it, the root and the packages it lists are installed, built and tested. Without it, only the root is: `pnpm recursive` with no workspace file would treat every `package.json` in the tree as a project (composer-installed plugins and code copied from a server included) and run its scripts with the job's secrets. List only the repo's own plugins and themes, never composer-installed ones.
- `e2e/` (the site's Playwright suite) is never installed, built or tested on deploy.
