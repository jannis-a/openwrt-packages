include $(TOPDIR)/rules.mk

PKG_NAME:=vmagent
# Renovate updates these three lines together (renovate.json5): new version,
# release reset to 1, hash from the release's checksum file.
PKG_VERSION:=1.156.0
PKG_RELEASE:=2
PKG_HASH:=1a8e4ed55df2a59d5cd03056213f50d293d4fab029e38dd960597362d92cf176

# The static vmagent-prod from the VictoriaMetrics vmutils release, not built
# from source: VictoriaMetrics needs a newer Go than the packages feed's
# default (go.mod of v1.156.0: go 1.27.3, feed default 1.26).
PKG_SOURCE:=vmutils-linux-arm64-v$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v$(PKG_VERSION)/

PKG_LICENSE:=Apache-2.0
PKG_MAINTAINER:=Jannis Assenheimer <jannis.assenheimer@gmail.com>

include $(INCLUDE_DIR)/package.mk

define Package/vmagent
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=VictoriaMetrics agent (scrape and remote write)
  URL:=https://docs.victoriametrics.com/victoriametrics/vmagent/
  # Only the arm64 release tarball is wired up.
  DEPENDS:=@aarch64
endef

define Package/vmagent/description
  vmagent scrapes Prometheus targets and pushes the samples to a remote
  write endpoint such as VictoriaMetrics. While the endpoint is unreachable
  it buffers on disk and sends the backlog later. Configured in
  /etc/config/vmagent, targets in /etc/vmagent/scrape.yml.
endef

define Package/vmagent/conffiles
/etc/config/vmagent
/etc/vmagent/scrape.yml
endef

# The tarball holds all vmutils (~130 MB); only vmagent is needed.
define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(TAR) -xzf $(DL_DIR)/$(PKG_SOURCE) -C $(PKG_BUILD_DIR) vmagent-prod
endef

define Build/Compile
endef

define Package/vmagent/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/vmagent-prod $(1)/usr/bin/vmagent
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/vmagent.init $(1)/etc/init.d/vmagent
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/vmagent.config $(1)/etc/config/vmagent
	$(INSTALL_DIR) $(1)/etc/vmagent
	$(INSTALL_DATA) ./files/scrape.yml $(1)/etc/vmagent/scrape.yml
endef

$(eval $(call BuildPackage,vmagent))
