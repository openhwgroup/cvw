#!/bin/sh

# Copy linux and busybox binaries (with symbol info) to images directory
cp "$BUILD_DIR"/linux-*/vmlinux "$BINARIES_DIR"/vmlinux
cp "$BUILD_DIR"/busybox-*/busybox "$BINARIES_DIR"/busybox
