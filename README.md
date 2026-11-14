# openwrt-packages

Additional packages for OpenWrt, built with the official SDK and published
as a signed apk feed on GitHub Pages.

## Packages

| Package | Description | Upstream | License |
|---|---|---|---|
| [prometheus-node-exporter-lua-quectel](utils/prometheus-node-exporter-lua-quectel) | Collector for prometheus-node-exporter-lua: signal per carrier and antenna path, cells, network mode and temperatures of a Quectel 5G module, via quectel-atd | - | GPL-2.0 |
| [quectel-atd](utils/quectel-atd) | Shares the RGMII AT port of a Quectel 5G module between local clients over a unix socket, with the `quectel-at` CLI | - | GPL-2.0 |
| [unbound](net/unbound) | Validating, recursive, caching DNS resolver; the packages feed's unbound, built with dnstap | [NLnet Labs](https://nlnetlabs.nl/projects/unbound/about/) | BSD-3-Clause |
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
