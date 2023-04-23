#!/bin/bash
set -ex
function cleanup() {
	if [ -f /swapfile ]; then
		sudo swapoff /swapfile
		sudo rm -rf /swapfile
	fi
	sudo rm -rf /etc/apt/sources.list.d/* /usr/share/dotnet /usr/local/lib/android /opt/ghc
	command -v docker && docker rmi $(docker images -q)
	sudo apt-get -y purge \
		azure-cli* \
		ghc* \
		zulu* \
		hhvm* \
		llvm* \
		firefox* \
		google* \
		dotnet* \
		openjdk* \
		mysql* \
		php*
	sudo apt autoremove --purge -y
}

function init() {
	[ -f sources.list ] && (
		sudo cp -rf sources.list /etc/apt/sources.list
		sudo rm -rf /etc/apt/sources.list.d/* /var/lib/apt/lists/*
		sudo apt-get clean all
	)
	sudo apt-get update
	sudo apt-get full-upgrade -y
	sudo apt-get -y install ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
		 bzip2 ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext gcc-multilib g++-multilib \
		 git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev \
		 libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libreadline-dev libssl-dev libtool lrzsz \
		 mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf python2.7 python3 python3-pyelftools \
		 libpython3-dev qemu-utils rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip \
		 vim wget xmlto xxd zlib1g-dev
	sudo apt-get autoremove --purge -y
	sudo timedatectl set-timezone Asia/Shanghai
	git config --global user.name "GitHub Action"
	git config --global user.email "action@github.com"
}

function build() {
	release_tag="$(date +%Y-%m-%d)"
	[ -d ./files/etc ] || mkdir -p ./files/etc
    echo ${release_tag} > ./files/etc/version

	if [ -d openwrt ]; then
		pushd openwrt
		git pull
		popd
	else
		git clone -b 20220401 https://github.com/coolsnowwolf/lede ./openwrt
	fi
	pushd openwrt

	git clone --depth=1 https://github.com/vernesong/OpenClash.git ./package/luci-app-openclash

	./scripts/feeds update -a
	./scripts/feeds install -a
	[ -d ../patches ] && git am -3 ../patches/*.patch
	[ -d ../files ] && cp -fr ../files ./files
	[ -f ../config ] && cp -fr ../config ./.config
	make defconfig
	make download -j$(nproc)
	make -j$(nproc)
	popd
}

function artifact() {
	ls -a
	mkdir -p ./openwrt-r5s-squashfs-img
	cp ./openwrt/bin/targets/rockchip/armv8/openwrt-rockchip-armv8-friendlyarm_nanopi-r5s-squashfs-sysupgrade.img.gz ./openwrt-r5s-squashfs-img
	cp ./openwrt/bin/targets/rockchip/armv8/config.buildinfo ./openwrt-r5s-squashfs-img
	zip -r openwrt-r5s-squashfs-img.zip ./openwrt-r5s-squashfs-img
}

function auto() {
	cleanup
	init
	build
	artifact
}

$@
