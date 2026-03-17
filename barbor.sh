#!/bin/sh

##############################
# Void Linux Installation    #
##############################

ROOTFS_DIR=/home/container
PROOT_VERSION="5.3.0"
LOG_FILE=/home/container/install.log

# Start logging everything
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[$(date)] Starting installation script"

ARCH=$(uname -m)
echo "[$(date)] Detected architecture: $ARCH"

if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
else
  echo "[$(date)] ERROR: Unsupported CPU architecture: ${ARCH}"
  exit 1
fi

# Check available tools
echo "[$(date)] Checking available tools..."
which curl && echo "[$(date)] curl: OK" || echo "[$(date)] curl: NOT FOUND"
which tar  && echo "[$(date)] tar: OK"  || echo "[$(date)] tar: NOT FOUND"
which xz   && echo "[$(date)] xz: OK"   || echo "[$(date)] xz: NOT FOUND"

# Check disk space
echo "[$(date)] Disk space:"
df -h /home/container /tmp

# Download & decompress the Void Linux root file system if not already installed.
if [ ! -e $ROOTFS_DIR/.installed ]; then
    echo "[$(date)] Downloading Void Linux rootfs..."
    curl -v --progress-bar -Lo /tmp/rootfs.tar.xz \
        "https://repo-default.voidlinux.org/live/current/void-x86_64-ROOTFS-20250202.tar.xz"
    CURL_EXIT=$?
    echo "[$(date)] curl exit code: $CURL_EXIT"

    if [ $CURL_EXIT -ne 0 ]; then
        echo "[$(date)] ERROR: Failed to download rootfs. Aborting."
        exit 1
    fi

    echo "[$(date)] Downloaded file size:"
    ls -lh /tmp/rootfs.tar.xz

    echo "[$(date)] Extracting rootfs to $ROOTFS_DIR ..."
    mkdir -p $ROOTFS_DIR
    tar -xJf /tmp/rootfs.tar.xz -C $ROOTFS_DIR
    TAR_EXIT=$?
    echo "[$(date)] tar exit code: $TAR_EXIT"

    if [ $TAR_EXIT -ne 0 ]; then
        echo "[$(date)] ERROR: Extraction failed. Aborting."
        exit 1
    fi

    echo "[$(date)] Rootfs extraction complete. Top-level contents:"
    ls -la $ROOTFS_DIR
else
    echo "[$(date)] Rootfs already installed, skipping download."
fi

################################
# Package Installation & Setup #
################################

if [ ! -e $ROOTFS_DIR/.installed ]; then
    echo "[$(date)] Downloading proot..."
    curl -v --progress-bar -Lo /tmp/proot \
        "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"
    CURL_EXIT=$?
    echo "[$(date)] proot curl exit code: $CURL_EXIT"
    ls -lh /tmp/proot

    if [ $CURL_EXIT -ne 0 ]; then
        echo "[$(date)] ERROR: Failed to download proot. Aborting."
        exit 1
    fi

    chmod 755 /tmp/proot
    cp /tmp/proot $ROOTFS_DIR/usr/local/bin/proot
    echo "[$(date)] proot installed."

    echo "[$(date)] Downloading gotty..."
    curl -v --progress-bar -Lo /tmp/gotty.tar.gz \
        "https://github.com/sorenisanerd/gotty/releases/download/v1.5.0/gotty_v1.5.0_linux_${ARCH_ALT}.tar.gz"
    CURL_EXIT=$?
    echo "[$(date)] gotty curl exit code: $CURL_EXIT"
    ls -lh /tmp/gotty.tar.gz

    if [ $CURL_EXIT -ne 0 ]; then
        echo "[$(date)] ERROR: Failed to download gotty. Aborting."
        exit 1
    fi

    tar -xzf /tmp/gotty.tar.gz -C $ROOTFS_DIR/usr/local/bin
    echo "[$(date)] gotty installed. Contents of /usr/local/bin:"
    ls -lh $ROOTFS_DIR/usr/local/bin

    chmod 755 $ROOTFS_DIR/usr/local/bin/proot $ROOTFS_DIR/usr/local/bin/gotty
fi

# Clean-up after installation complete & finish up.
if [ ! -e $ROOTFS_DIR/.installed ]; then
    echo "[$(date)] Writing resolv.conf..."
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > ${ROOTFS_DIR}/etc/resolv.conf

    echo "[$(date)] Cleaning up /tmp..."
    rm -rf /tmp/rootfs.tar.xz /tmp/gotty.tar.gz

    echo "[$(date)] Marking installation as complete."
    touch $ROOTFS_DIR/.installed
fi

# Use proot from /tmp if it exists, otherwise fall back to inside rootfs
PROOT_BIN=/tmp/proot
if [ ! -f "$PROOT_BIN" ]; then
    PROOT_BIN=$ROOTFS_DIR/usr/local/bin/proot
fi

echo "[$(date)] Using proot at: $PROOT_BIN"
echo "[$(date)] Launching PRoot environment..."

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

 Log file is at: $LOG_FILE

EOF

###########################
# Start PRoot environment #
###########################

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
