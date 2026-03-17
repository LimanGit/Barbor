#!/bin/sh

##############################
# Void Linux Installation    #
##############################

# Define the root directory to /home/container.
# We can only write in /home/container and /tmp in the container.
ROOTFS_DIR=/home/container

PROOT_VERSION="5.3.0"

# Detect the machine architecture.
ARCH=$(uname -m)

# Only support x86_64/amd64.
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
else
  printf "Unsupported CPU architecture: ${ARCH}"
  exit 1
fi

# Download & decompress the Void Linux root file system if not already installed.
if [ ! -e $ROOTFS_DIR/.installed ]; then
    curl -Lo /tmp/rootfs.tar.xz \
    "https://repo-default.voidlinux.org/live/current/void-x86_64-ROOTFS-20250202.tar.xz"
    tar -xJf /tmp/rootfs.tar.xz -C $ROOTFS_DIR
fi

################################
# Package Installation & Setup #
################################

if [ ! -e $ROOTFS_DIR/.installed ]; then
    curl -Lo /tmp/gotty.tar.gz "https://github.com/sorenisanerd/gotty/releases/download/v1.5.0/gotty_v1.5.0_linux_${ARCH_ALT}.tar.gz"
    curl -Lo $ROOTFS_DIR/usr/local/bin/proot "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"

    tar -xzf /tmp/gotty.tar.gz -C $ROOTFS_DIR/usr/local/bin

    chmod 755 $ROOTFS_DIR/usr/local/bin/proot $ROOTFS_DIR/usr/local/bin/gotty
fi

# Clean-up after installation complete & finish up.
if [ ! -e $ROOTFS_DIR/.installed ]; then
    # Add DNS Resolver nameservers to resolv.conf.
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > ${ROOTFS_DIR}/etc/resolv.conf
    # Wipe the files we downloaded into /tmp previously.
    rm -rf /tmp/rootfs.tar.xz /tmp/gotty.tar.gz
    # Create .installed to later check whether Void Linux is installed.
    touch $ROOTFS_DIR/.installed
fi

# Print some useful information to the terminal before entering PRoot.
clear && cat << EOF

 ██╗   ██╗ ██████╗ ██╗██████╗
 ██║   ██║██╔═══██╗██║██╔══██╗
 ██║   ██║██║   ██║██║██║  ██║
 ╚██╗ ██╔╝██║   ██║██║██║  ██║
  ╚████╔╝ ╚██████╔╝██║██████╔╝
   ╚═══╝   ╚═════╝ ╚═╝╚═════╝

 Welcome to Void Linux (proot)!
 Void is a rolling release distro with the XBPS package manager and runit init system.

 Here are some useful commands to get you started:

    xbps-install [package]  : install a package
    xbps-remove [package]   : remove a package
    xbps-install -Su        : sync and upgrade all packages
    xbps-query -Rs [keyword]: search for a package
    xbps-query [package]    : show information about a package
    gotty -p [port] -w bash : share your terminal

 If you run into any issues make sure to report them on GitHub!
 https://github.com/LimanGit/barbor

EOF

###########################
# Start PRoot environment #
###########################

$ROOTFS_DIR/usr/local/bin/proot \
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
