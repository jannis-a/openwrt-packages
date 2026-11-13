# openwrt-packages

Additional packages for OpenWrt, built with the official SDK and published
as a signed apk feed on GitHub Pages.

## Usage

```sh
wget -O /etc/apk/keys/jannis-a.pem https://jannis-a.github.io/openwrt-packages/jannis-a.pem
echo '@jannis-a https://jannis-a.github.io/openwrt-packages/25.12/aarch64_cortex-a53/packages.adb' \
	> /etc/apk/repositories.d/jannis-a.list
apk update
apk add <package>@jannis-a
```

The tag keeps a package on this feed, so `apk upgrade` does not replace it
with a package of the same name from another feed.

## Contributing

Changes go through pull requests. Every pull request is linted, version
checked and built; the built packages are attached as artifacts. A changed
package needs a higher `PKG_VERSION` or `PKG_RELEASE`. Merges to `main`
publish the feed.
