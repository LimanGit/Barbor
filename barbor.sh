#!/bin/sh

ROOTFS_DIR=/home/container
PROOT_VERSION="5.3.0"

ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
else
  printf "Unsupported CPU architecture: ${ARCH}\n"
  exit 1
fi

mkdir -p $ROOTFS_DIR

if [ ! -e $ROOTFS_DIR/.installed ]; then
    # Download static xz binary (comes as .tar.gz so we can extract it)
    curl -L --retry 3 \
        -o $ROOTFS_DIR/xz-static.tar.gz \
        "https://github.com/therootcompany/xz-static/releases/download/v5.2.5/xz-5.2.5-linux-x86_64.tar.gz"
    tar -xzf $ROOTFS_DIR/xz-static.tar.gz -C $ROOTFS_DIR
    mv $ROOTFS_DIR/xz-5.2.5-linux-x86_64/xz $ROOTFS_DIR/xz
    chmod 755 $ROOTFS_DIR/xz
    rm -rf $ROOTFS_DIR/xz-static.tar.gz $ROOTFS_DIR/xz-5.2.5-linux-x86_64

    # Download rootfs
    curl -L --retry 3 \
        -o $ROOTFS_DIR/rootfs.tar.xz \
        "https://repo-default.voidlinux.org/live/current/void-x86_64-ROOTFS-20250202.tar.xz"

    # Decompress xz then extract tar
    $ROOTFS_DIR/xz -d $ROOTFS_DIR/rootfs.tar.xz
    tar -xvf $ROOTFS_DIR/rootfs.tar -C $ROOTFS_DIR
    rm -f $ROOTFS_DIR/rootfs.tar $ROOTFS_DIR/xz

    # Download proot
    curl -L --retry 3 \
        -o $ROOTFS_DIR/proot \
        "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"
    chmod 755 $ROOTFS_DIR/proot

    # Download gotty
    curl -L --retry 3 \
        -o $ROOTFS_DIR/gotty.tar.gz \
        "https://github.com/sorenisanerd/gotty/releases/download/v1.5.0/gotty_v1.5.0_linux_${ARCH_ALT}.tar.gz"
    tar -xzf $ROOTFS_DIR/gotty.tar.gz -C $ROOTFS_DIR/usr/local/bin
    chmod 755 $ROOTFS_DIR/usr/local/bin/gotty
    rm -f $ROOTFS_DIR/gotty.tar.gz

    mkdir -p $ROOTFS_DIR/root
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\n" > $ROOTFS_DIR/etc/resolv.conf

    touch $ROOTFS_DIR/.installed
fi

printf "\nWelcome to Void Linux (proot)!\n\n"
printf "   xbps-install [package]   : install a package\n"
printf "   xbps-remove [package]    : remove a package\n"
printf "   xbps-install -Su         : sync and upgrade all packages\n"
printf "   xbps-query -Rs [keyword] : search for a package\n"
printf "   gotty -p [port] -w bash  : share your terminal\n\n"

$ROOTFS_DIR/proot \
--rootfs="${ROOTFS_DIR}" \
--link2symlink \
--kill-on-exit \
--root-id \
--cwd=/root \
--bind=/proc \
--bind=/dev \
--bind=/sys \
--bind=/tmp \
/bin/sh
