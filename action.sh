#!/bin/bash
set -x

export HOME_DIR="/mnt"
export runner_uid=$(id -u)
export runner_gid=$(id -g)
export GITHUB_WORKSPACE=$(pwd)

function cleanup() {
	if [ -f /swapfile ]; then
		sudo swapoff /swapfile
		sudo rm -rf /swapfile
	fi
	df -h
	sudo rm -rf /etc/apt/sources.list.d/* \
	/usr/share/dotnet \
	/usr/local/lib/android \
	/opt/hostedtoolcache/CodeQL \
	/usr/local/.ghcup \
	/usr/share/swift \
	/usr/local/lib/node_modules \
	/usr/local/share/powershell \
	/opt/ghc /usr/local/lib/heroku
	sudo command -v docker && docker rmi $(docker images -q)
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
	df -h
}

function init() {
	[ -f sources.list ] && (
		sudo cp -rf sources.list /etc/apt/sources.list
		sudo rm -rf /etc/apt/sources.list.d/* /var/lib/apt/lists/*
		sudo apt-get clean all
	)
	sudo apt-get update
	# sudo apt-get dist-upgrade -y
	sudo apt-get -y install ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
		bzip2 ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext gcc-multilib g++-multilib \
		git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev \
		libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libreadline-dev libssl-dev libtool lrzsz \
		mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf python2.7 python3 python3-pyelftools \
		libpython3-dev qemu-utils rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip \
		vim wget xmlto xxd zlib1g-dev
	sudo timedatectl set-timezone Asia/Shanghai
	git config --global user.name "GitHub Action"
	git config --global user.email "action@github.com"
}

function build() {
	set -e
	release_tag="$(date +%Y-%m-%d)"
	[ -d ./files/etc/config ] || mkdir -p ./files/etc/config
	echo ${release_tag} >./files/etc/config/version

	if [ -d ${HOME_DIR}/openwrt ]; then
		pushd openwrt
		git pull
		popd
	else
		id
		# git clone https://github.com/openwrt/openwrt.git ${HOME_DIR}/openwrt
		sudo git clone https://github.com/coolsnowwolf/lede.git ${HOME_DIR}/openwrt
		sudo chown -R ${runner_uid}:${runner_gid} ${HOME_DIR}/openwrt
		[ -f ./feeds.conf.default ] && cat ./feeds.conf.default >> ${HOME_DIR}/openwrt/feeds.conf.default
	fi
	pushd ${HOME_DIR}/openwrt

	[ -d ./package/luci-app-openclash ] || git clone --depth=1 https://github.com/vernesong/OpenClash.git ./package/luci-app-openclash

	./scripts/feeds update -a
	./scripts/feeds install -a

	echo 

	if [ -d ${GITHUB_WORKSPACE}/patches ]; then

		git apply --check ${GITHUB_WORKSPACE}/patches/*.patch
		if [ $? -eq 0 ]; then
			git am ${GITHUB_WORKSPACE}/patches/*.patch
		fi
	fi
	[ -d ${GITHUB_WORKSPACE}/files ] && cp -fr ${GITHUB_WORKSPACE}/files ./files
	[ -f ${GITHUB_WORKSPACE}/config ] && cp -fr ${GITHUB_WORKSPACE}/config ./.config
	ls -l
	make defconfig
	make download -j$(nproc)
	df -h
	make -j$(nproc)
	if [ $? -ne 0 ]; then
		make -j1 V=s
	fi
	df -h
	popd
}

function artifact() {
	set -e
	sudo mkdir -p ${HOME_DIR}/openwrt-r5s-squashfs
	sudo ls -hl ${HOME_DIR}/openwrt/bin/targets/rockchip/armv8
	sudo cp ${HOME_DIR}/openwrt/bin/targets/rockchip/armv8/*-squashfs-sysupgrade.img.gz ${HOME_DIR}/openwrt-r5s-squashfs/
	sudo cp ${HOME_DIR}/openwrt/bin/targets/rockchip/armv8/config.buildinfo ${HOME_DIR}/openwrt-r5s-squashfs/
	sudo zip -r ${HOME_DIR}/openwrt-r5s-squashfs.zip ${HOME_DIR}/openwrt-r5s-squashfs
}

function auto() {
	cleanup
	init
	build
	artifact
}

$@
