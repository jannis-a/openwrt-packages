# openwrt-packages

Additional packages for OpenWrt, built with the official SDK and published
as a signed apk feed on GitHub Pages.

## Packages

| Package | Description | Upstream | License |
|---|---|---|---|
| [prometheus-node-exporter-lua-client_traffic](utils/prometheus-node-exporter-lua-client_traffic) | Collector for prometheus-node-exporter-lua: bytes and packets per client MAC between br-lan and the router, counted by an nftables table that fw4 loads | - | GPL-2.0 |
| [vmagent](utils/vmagent) | Scrapes Prometheus targets and pushes the samples via remote write, with an on-disk buffer | [VictoriaMetrics](https://github.com/VictoriaMetrics/VictoriaMetrics) | Apache-2.0 |

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
