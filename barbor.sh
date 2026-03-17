#!/bin/sh

##############################
# Void Linux Installation    #
##############################

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
    # Download rootfs
    curl -L --retry 3 -o /tmp/rootfs.tar.xz \
        "https://repo-default.voidlinux.org/live/current/void-x86_64-ROOTFS-20250202.tar.xz"

    # Decompress xz first, then extract tar separately
    # in case tar -J is not supported
    xz -d /tmp/rootfs.tar.xz
    tar -xf /tmp/rootfs.tar -C $ROOTFS_DIR
    rm -f /tmp/rootfs.tar

    # Download proot to /tmp so it's callable on the host
    curl -L --retry 3 \
        -o /tmp/proot \
        "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"
    chmod 755 /tmp/proot
    cp /tmp/proot $ROOTFS_DIR/usr/local/bin/proot

    # Download and extract gotty
    curl -L --retry 3 \
        -o /tmp/gotty.tar.gz \
        "https://github.com/sorenisanerd/gotty/releases/download/v1.5.0/gotty_v1.5.0_linux_${ARCH_ALT}.tar.gz"
    tar -xzf /tmp/gotty.tar.gz -C $ROOTFS_DIR/usr/local/bin
    chmod 755 $ROOTFS_DIR/usr/local/bin/gotty

    # DNS
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\n" > ${ROOTFS_DIR}/etc/resolv.conf

    # Cleanup
    rm -f /tmp/gotty.tar.gz

    touch $ROOTFS_DIR/.installed
fi

# Use /tmp/proot on first run, fall back to inside rootfs on subsequent runs
PROOT_BIN=/tmp/proot
if [ ! -f "$PROOT_BIN" ]; then
    PROOT_BIN=$ROOTFS_DIR/usr/local/bin/proot
fi

cat << EOF

 ██╗   ██╗ ██████╗ ██╗██████╗
 ██║   ██║██╔═══██╗██║██╔══██╗
 ██║   ██║██║   ██║██║██║  ██║
 ╚██╗ ██╔╝██║   ██║██║██║  ██║
  ╚████╔╝ ╚██████╔╝██║██████╔╝
   ╚═══╝   ╚═════╝ ╚═╝╚═════╝

 Welcome to Void Linux (proot)!

 Package manager commands:
    xbps-install [package]   : install a package
    xbps-remove [package]    : remove a package
    xbps-install -Su         : sync and upgrade all packages
    xbps-query -Rs [keyword] : search for a package
    gotty -p [port] -w bash  : share your terminal

EOF

$PROOT_BIN \
--rootfs="${ROOTFS_DIR}" \
--link2symlink \
--kill-on-exit \
--root-id \
--cwd=/root \
--bind=/proc \
--bind=/dev \
--bind=/sys \
--bind=/tmp \
/bin/bash
