include $(TOPDIR)/rules.mk

PKG_NAME:=quectel-atd
PKG_VERSION:=2026.11.14
PKG_RELEASE:=1

PKG_LICENSE:=GPL-2.0
# Runtime dependencies only: apk installs them on the router from the official
# feeds. As DEPENDS the SDK would build them, and through them the kernel with
# all its modules.
EXTRA_DEPENDS:=lua, luasocket

PKG_MAINTAINER:=Jannis Assenheimer <jannis.assenheimer@gmail.com>

include $(INCLUDE_DIR)/package.mk

define Package/quectel-atd
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Shared access to the AT port of Quectel 5G modules
  PKGARCH:=all
endef

define Package/quectel-atd/description
  Daemon that keeps the connection to the RGMII AT port of a Quectel 5G
  module (RM520N and similar, 192.168.225.1:1555) open and runs the
  commands of local clients one after another, over the unix socket
  /var/run/quectel-at.sock. The module accepts only one client and answers
  only 1-2 s after connecting. quectel-at runs a single command from the
  shell. The AT port must be enabled (AT+QETH="eth_at","enable") and
  reachable from the router.
endef

define Build/Compile
endef

define Package/quectel-atd/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/usr/bin $(1)/etc/init.d
	$(INSTALL_BIN) ./files/quectel-atd $(1)/usr/sbin/quectel-atd
	$(INSTALL_BIN) ./files/quectel-at $(1)/usr/bin/quectel-at
	$(INSTALL_BIN) ./files/quectel-atd.init $(1)/etc/init.d/quectel-atd
endef

$(eval $(call BuildPackage,quectel-atd))
