ARG CONTAINER_VERSION=latest
ARG CONTAINER_BASE_IMAGE=docker.io/library/debian:12

ARG CONTAINER_IMAGE_REGISTRY=localhost
ARG CONTAINER_IMAGE_REGISTRY_REMOTE=${CONTAINER_IMAGE_REGISTRY}
ARG CONTAINER_IMAGE_NAME=wally
ARG CONTAINER_IMAGE_NAME_FULL=${CONTAINER_IMAGE_REGISTRY}/${CONTAINER_IMAGE_NAME}
ARG CONTAINER_IMAGE_VERSION=${CONTAINER_VERSION}
ARG CONTAINER_BUILDER_IMAGE=${CONTAINER_IMAGE_NAME_FULL}:${CONTAINER_IMAGE_VERSION}-builder
ARG CONTAINER_DEVEL_IMAGE=${CONTAINER_IMAGE_NAME_FULL}:${CONTAINER_IMAGE_VERSION}-devel

FROM ${CONTAINER_BASE_IMAGE} as wally-builder
ARG TARGETARCH TARGETOS TARGETPLATFORM TARGETVARIANT

RUN --mount=type=bind,source=./bin,target=/wally/bin \
    bash /wally/bin/wally-package-install.sh && \
    apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

RUN --mount=type=bind,source=./bin,target=/wally/bin \
    export WALLY=/wally && \
    export RISCV=/opt/riscv && \
    bash "$WALLY/bin/installation/riscv-gnu-toolchain-install.sh" --clean

RUN --mount=type=bind,source=./bin,target=/wally/bin \
    export WALLY=/wally && \
    export RISCV=/opt/riscv && \
    bash "$WALLY/bin/installation/elf2hex-install.sh" --clean && \
    bash "$WALLY/bin/installation/qemu-install.sh" --clean && \
    bash "$WALLY/bin/installation/spike-install.sh" --clean && \
    # bash "$WALLY/bin/installation/sail-install.sh" --clean && \
    bash "$WALLY/bin/installation/verilator-install.sh" --clean

FROM wally-builder as wally-devel
ARG TARGETARCH TARGETOS TARGETPLATFORM TARGETVARIANT
