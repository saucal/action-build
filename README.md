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
```
