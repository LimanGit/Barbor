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
    curl -L --retry 3 -o $ROOTFS_DIR/rootfs.tar.xz \
        "https://repo-default.voidlinux.org/live/current/void-x86_64-ROOTFS-20250202.tar.xz"

    tar -xvf $ROOTFS_DIR/rootfs.tar.xz -C $ROOTFS_DIR
    rm -f $ROOTFS_DIR/rootfs.tar.xz

    curl -L --retry 3 \
        -o $ROOTFS_DIR/proot \
        "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"
    chmod 755 $ROOTFS_DIR/proot

    curl -L --retry 3 \
        -o $ROOTFS_DIR/gotty.tar.gz \
        "https://github.com/sorenisanerd/gotty/releases/download/v1.5.0/gotty_v1.5.0_linux_${ARCH_ALT}.tar.gz"
    tar -xzf $ROOTFS_DIR/gotty.tar.gz -C $ROOTFS_DIR/usr/local/bin
    chmod 755 $ROOTFS_DIR/usr/local/bin/gotty
    rm -f $ROOTFS_DIR/gotty.tar.gz

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
/bin/sh--bind=/dev \
--bind=/sys \
--bind=/tmp \
/bin/sh
