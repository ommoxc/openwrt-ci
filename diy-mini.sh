#!/bin/bash
# ghproxy 加速地址，如失效可更换
export GH_PROXY="https://mirror.ghproxy.com"
# 拼接函数
gh_url() {
    echo "${GH_PROXY}/$1"
}

# ===================== Git 全局防超时配置 =====================
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 1000
git config --global http.lowSpeedTime 60
git config --global core.compression 0

# 修改默认IP
# sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate
# 更改默认 Shell 为 zsh
# sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd
# TTYD 免登录
# sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# 移除要替换的包
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/net/msd_lite
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/luci/applications/luci-app-netdata

# Git稀疏克隆，只克隆指定目录到本地，增加容错
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  echo "===== sparse clone: $repourl branch:$branch ====="
  proxy_repo=$(gh_url "$repourl")
  if ! git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $proxy_repo; then
    echo "WARN: clone $repourl failed, skip"
    return 0
  fi
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir
  git sparse-checkout set $@
  mv -f $@ ../package/ 2>/dev/null || true
  cd ..
  rm -rf $repodir
}

# 添加额外插件
git clone --depth=1 $(gh_url "https://github.com/kongfl888/luci-app-adguardhome") package/luci-app-adguardhome || true
git clone --depth=1 $(gh_url "https://github.com/Jason6111/luci-app-netdata") package/luci-app-netdata || true
# git_sparse_clone master https://github.com/syb999/openwrt-19.07.1 package/network/services/msd_lite

# 科学上网插件
git clone --depth=1 -b main $(gh_url "https://github.com/fw876/helloworld") package/luci-app-ssr-plus || true
git clone --depth=1 $(gh_url "https://github.com/xiaorouji/openwrt-passwall-packages") package/openwrt-passwall || true
git clone --depth=1 $(gh_url "https://github.com/xiaorouji/openwrt-passwall") package/luci-app-passwall || true
git clone --depth=1 $(gh_url "https://github.com/xiaorouji/openwrt-passwall2") package/luci-app-passwall2 || true
git_sparse_clone master https://github.com/vernesong/OpenClash luci-app-openclash

# Themes
git clone --depth=1 -b 18.06 $(gh_url "https://github.com/kiddin9/luci-theme-edge") package/luci-theme-edge || true
git clone --depth=1 -b 18.06 $(gh_url "https://github.com/jerrykuku/luci-theme-argon") package/luci-theme-argon || true
git clone --depth=1 $(gh_url "https://github.com/jerrykuku/luci-app-argon-config") package/luci-app-argon-config || true
git clone --depth=1 $(gh_url "https://github.com/xiaoqingfengATGH/luci-theme-infinityfreedom") package/luci-theme-infinityfreedom || true
git_sparse_clone main https://github.com/haiibo/packages luci-theme-opentomcat

# 更改 Argon 主题背景：文件不存在就跳过
BG_SRC="$GITHUB_WORKSPACE/images/bg1.jpg"
BG_DST="package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg"
if [ -f "$BG_SRC" ]; then
  cp -f "$BG_SRC" "$BG_DST"
else
  echo "WARN: bg1.jpg not found, skip argon background"
fi

# 晶晨宝盒（IPQ807非晶晨，保留）
git_sparse_clone main https://github.com/ophub/luci-app-amlogic luci-app-amlogic
if [ -f package/luci-app-amlogic/root/etc/config/amlogic ]; then
  sed -i "s|firmware_repo.*|firmware_repo 'https://github.com/haiibo/OpenWrt'|g" package/luci-app-amlogic/root/etc/config/amlogic
  # sed -i "s|kernel_path.*|kernel_path 'https://github.com/ophub/kernel'|g" package/luci-app-amlogic/root/etc/config/amlogic
  sed -i "s|ARMv8|ARMv8_MINI|g" package/luci-app-amlogic/root/etc/config/amlogic
fi

# SmartDNS
git clone --depth=1 -b lede $(gh_url "https://github.com/pymumu/luci-app-smartdns") package/luci-app-smartdns || true
git clone --depth=1 $(gh_url "https://github.com/pymumu/openwrt-smartdns") package/smartdns || true

# msd_lite
git clone --depth=1 $(gh_url "https://github.com/ximiTech/luci-app-msd_lite") package/luci-app-msd_lite || true
git clone --depth=1 $(gh_url "https://github.com/ximiTech/msd_lite") package/msd_lite || true

# MosDNS
git clone --depth=1 $(gh_url "https://github.com/sbwml/luci-app-mosdns") package/luci-app-mosdns || true

# Alist
git clone --depth=1 $(gh_url "https://github.com/sbwml/luci-app-alist") package/luci-app-alist || true

# iStore
git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui
git_sparse_clone main https://github.com/linkease/istore luci

# 在线用户
git_sparse_clone main https://github.com/haiibo/packages luci-app-onliner
if [ -f package/lean/default-settings/files/zzz-default-settings ]; then
  sed -i '$i uci set nlbwmon.@nlbwmon[0].refresh_interval=2s' package/lean/default-settings/files/zzz-default-settings
  sed -i '$i uci commit nlbwmon' package/lean/default-settings/files/zzz-default-settings
fi
if [ -f package/luci-app-onliner/root/usr/share/onliner/setnlbw.sh ]; then
  chmod 755 package/luci-app-onliner/root/usr/share/onliner/setnlbw.sh
fi

# x86 型号只显示 CPU 型号（IPQ807 跳过）
# sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}${hydrid}/g' package/lean/autocore/files/x86/autocore

# 修改本地时间格式
find package/lean/autocore/files/*/index.htm 2>/dev/null | xargs -I {} sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' {} 2>/dev/null || true

# 修改版本为编译日期
if [ -f package/lean/default-settings/files/zzz-default-settings ]; then
  date_version=$(date +"%y.%m.%d")
  orig_version=$(grep DISTRIB_REVISION= package/lean/default-settings/files/zzz-default-settings | awk -F "'" '{print $2}')
  sed -i "s/${orig_version}/R${date_version} by Haiibo/g" package/lean/default-settings/files/zzz-default-settings
fi

# 修复 hostapd 报错：patch不存在就跳过
PATCH_SRC="$GITHUB_WORKSPACE/scripts/011-fix-mbo-modules-build.patch"
PATCH_DST="package/network/services/hostapd/patches/011-fix-mbo-modules-build.patch"
if [ -f "$PATCH_SRC" ]; then
  cp -f "$PATCH_SRC" "$PATCH_DST"
else
  echo "WARN: hostapd patch not found, skip"
fi

# 修复 armv8 设备 xfsprogs 报错（IPQ807不需要，可选开启）
# sed -i 's/TARGET_CFLAGS.*/TARGET_CFLAGS += -DHAVE_MAP_SYNC -D_LARGEFILE64_SOURCE/g' feeds/packages/utils/xfsprogs/Makefile

# 修改 Makefile
find package/*/ -maxdepth 2 -path "*/Makefile" 2>/dev/null | xargs -i sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' {} 2>/dev/null || true
find package/*/ -maxdepth 2 -path "*/Makefile" 2>/dev/null | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {} 2>/dev/null || true
find package/*/ -maxdepth 2 -path "*/Makefile" 2>/dev/null | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {} 2>/dev/null || true
find package/*/ -maxdepth 2 -path "*/Makefile" 2>/dev/null | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {} 2>/dev/null || true

# 取消主题默认设置
find package/luci-theme-*/* -type f -name '*luci-theme-*' -print -exec sed -i '/set luci.main.mediaurlbase/d' {} \; 2>/dev/null || true

# 调整 Docker 到 服务 菜单
sed -i 's/"admin"/"admin", "services"/g' feeds/luci/applications/luci-app-dockerman/luasrc/controller/*.lua 2>/dev/null || true
sed -i 's/"admin"/"admin", "services"/g; s/admin\//admin\/services\//g' feeds/luci/applications/luci-app-dockerman/luasrc/model/cbi/dockerman/*.lua 2>/dev/null || true
sed -i 's/admin\//admin\/services\//g' feeds/luci/applications/luci-app-dockerman/luasrc/view/dockerman/*.htm 2>/dev/null || true
sed -i 's|admin\\|admin\\/services\\|g' feeds/luci/applications/luci-app-dockerman/luasrc/view/dockerman/container.htm 2>/dev/null || true

# 调整 ZeroTier 到 服务 菜单
# sed -i 's/vpn/services/g; s/VPN/Services/g' feeds/luci/applications/luci-app-zerotier/luasrc/controller/zerotier.lua
# sed -i 's/vpn/services/g' feeds/luci/applications/luci-app-zerotier/luasrc/view/zerotier/zerotier_status.htm

# 取消对 samba4 的菜单调整
# sed -i '/samba4/s/^/#/' package/lean/default-settings/files/zzz-default-settings

./scripts/feeds update -a
./scripts/feeds install -a
