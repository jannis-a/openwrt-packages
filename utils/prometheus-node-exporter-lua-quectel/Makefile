include $(TOPDIR)/rules.mk

PKG_NAME:=prometheus-node-exporter-lua-quectel
PKG_VERSION:=2026.11.14
PKG_RELEASE:=1

PKG_LICENSE:=GPL-2.0
PKG_MAINTAINER:=Jannis Assenheimer <jannis.assenheimer@gmail.com>

include $(INCLUDE_DIR)/package.mk

define Package/prometheus-node-exporter-lua-quectel
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Prometheus node exporter (quectel collector)
  DEPENDS:=+prometheus-node-exporter-lua +quectel-atd
  PKGARCH:=all
endef

define Package/prometheus-node-exporter-lua-quectel/description
  Collector for prometheus-node-exporter-lua that queries a Quectel 5G
  module (RM520N and similar) through quectel-atd: signal per carrier and
  per antenna path (RSRP, RSRQ, RSSI, SINR), serving and neighbour cells,
  bandwidth, MCS, CQI, MIMO layers, network mode (LTE/NSA/SA), AMBR,
  registration, reject causes and temperatures. All metrics have HELP
  texts. Only read commands are sent; none of them is documented to write
  to the module's flash.
endef

define Build/Compile
endef

define Package/prometheus-node-exporter-lua-quectel/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/prometheus-collectors
	$(INSTALL_DATA) ./files/quectel.lua $(1)/usr/lib/lua/prometheus-collectors/quectel.lua
endef

$(eval $(call BuildPackage,prometheus-node-exporter-lua-quectel))
