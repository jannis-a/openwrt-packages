include $(TOPDIR)/rules.mk

PKG_NAME:=prometheus-node-exporter-lua-client_traffic
PKG_VERSION:=2026.11.14
PKG_RELEASE:=1

PKG_LICENSE:=GPL-2.0
# Runtime dependencies only: apk installs them on the router from the official
# feeds. As DEPENDS the SDK would build them, and through them the kernel with
# all its modules.
EXTRA_DEPENDS:=prometheus-node-exporter-lua, firewall4, kmod-nft-bridge

PKG_MAINTAINER:=Jannis Assenheimer <jannis.assenheimer@gmail.com>

include $(INCLUDE_DIR)/package.mk

define Package/prometheus-node-exporter-lua-client_traffic
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Prometheus node exporter (client_traffic collector)
  PKGARCH:=all
endef

define Package/prometheus-node-exporter-lua-client_traffic/description
  Collector for prometheus-node-exporter-lua: bytes and packets per client
  MAC and direction, for the traffic between the clients of br-lan and the
  router. The counters live in the nftables table bridge client_traffic,
  configured in /etc/nftables.d/client-traffic.ruleset (br-lan by default)
  and loaded by fw4. The mac label matches wifi_stations and uci_dhcp_host.
endef

define Build/Compile
endef

define Package/prometheus-node-exporter-lua-client_traffic/conffiles
/etc/nftables.d/client-traffic.ruleset
endef

define Package/prometheus-node-exporter-lua-client_traffic/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/prometheus-collectors
	$(INSTALL_DATA) ./files/client_traffic.lua $(1)/usr/lib/lua/prometheus-collectors/client_traffic.lua
	$(INSTALL_DIR) $(1)/etc/nftables.d
	$(INSTALL_CONF) ./files/client-traffic.ruleset $(1)/etc/nftables.d/client-traffic.ruleset
	$(INSTALL_DIR) $(1)/usr/share/nftables.d/ruleset-post
	$(LN) /etc/nftables.d/client-traffic.ruleset $(1)/usr/share/nftables.d/ruleset-post/client-traffic.nft
endef

define Package/prometheus-node-exporter-lua-client_traffic/postinst
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] || fw4 -q reload
endef

# fw4 leaves tables it does not own alone, so remove the counters explicitly.
define Package/prometheus-node-exporter-lua-client_traffic/prerm
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] || nft delete table bridge client_traffic 2>/dev/null
exit 0
endef

$(eval $(call BuildPackage,prometheus-node-exporter-lua-client_traffic))
