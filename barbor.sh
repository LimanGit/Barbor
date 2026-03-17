#!/bin/sh

##############################
# Debian Linux Installation  #
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

# Download & decompress the Debian root file system if not already installed.
if [ ! -e $ROOTFS_DIR/.installed ]; then
    curl -Lo /tmp/rootfs.tar.gz \
    "https://github.com/LimanGit/Barbor/releases/download/debian-rootfs/debian.tar.gz"
    tar -xzf /tmp/rootfs.tar.gz -C $ROOTFS_DIR
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
    rm -rf /tmp/rootfs.tar.gz /tmp/gotty.tar.gz
    # Create .installed to later check whether Debian is installed.
    touch $ROOTFS_DIR/.installed
    mkdir $ROOTFS_DIR/root
    mkdir $ROOTFS_DIR/proc
    mkdir $ROOTFS_DIR/tmp
    
fi

# Print some useful information to the terminal before entering PRoot.
clear && cat << EOF

 ██████╗ ███████╗██████╗ ██╗ █████╗ ███╗   ██╗
 ██╔══██╗██╔════╝██╔══██╗██║██╔══██╗████╗  ██║
 ██║  ██║█████╗  ██████╔╝██║███████║██╔██╗ ██║
 ██║  ██║██╔══╝  ██╔══██╗██║██╔══██║██║╚██╗██║
 ██████╔╝███████╗██████╔╝██║██║  ██║██║ ╚████║
 ╚═════╝ ╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝

 Welcome to Debian Bookworm (proot)!
 Debian is a stable, versatile Linux distribution great for running all kinds of applications.

 Here are some useful commands to get you started:

    apt install [package]  : install a package
    apt remove [package]   : remove a package
    apt update             : update the package index
    apt upgrade            : upgrade installed packages
    apt search [keyword]   : search for a package
    apt show [package]     : show information about a package
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
