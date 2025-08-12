ARG WALLY_CONTAINER_VERSION=latest
ARG WALLY_CONTAINER_BASE_IMAGE=docker.io/almalinux/9-base:9.6

ARG WALLY_CONTAINER_BUILDER_IMAGE=wally-builder
ARG WALLY_CONTAINER_DEVEL_IMAGE=wally-devel

ARG RISCV_GNU_TOOLCHAIN_VERSION=23863c2ca74e6c050f0c97e7af61f5f1776aadd1

FROM ${WALLY_CONTAINER_BASE_IMAGE} as wally-builder
ARG TARGETARCH TARGETOS TARGETPLATFORM TARGETVARIANT

ARG RISCV_GNU_TOOLCHAIN_VERSION
ENV RISCV_GNU_TOOLCHAIN_VERSION=${RISCV_GNU_TOOLCHAIN_VERSION}
ENV RISCV_INSTALL_PREFIX=/opt/riscv

ENV WALLY_HOME=/root
ENV WALLY_SOURCE_DIR=/workspaces/cvw
ENV WALLY_PYTHON_VENV_DIR=${WALLY_HOME}/.venv/wally
ENV WALLY_PYTHON_EXECUTABLE=${WALLY_PYTHON_VENV_DIR}/bin/python

ENV RISCV=${RISCV_INSTALL_PREFIX}
ENV WALLY=${WALLY_SOURCE_DIR}

RUN --mount=type=bind,source=./bin,target=${WALLY_SOURCE_DIR}/bin \
    bash "${WALLY_SOURCE_DIR}/bin/wally-package-install.sh" --clean

RUN --mount=type=bind,source=./bin,target=${WALLY_SOURCE_DIR}/bin \
    bash "${WALLY_SOURCE_DIR}/bin/installation/riscv-gnu-toolchain-install.sh" --clean

RUN --mount=type=bind,source=./bin,target=${WALLY_SOURCE_DIR}/bin \
    --mount=type=bind,source=./linux,target=${WALLY_SOURCE_DIR}/linux \
    bash "${WALLY_SOURCE_DIR}/bin/wally-tool-chain-install.sh" --clean --no-buildroot --no-skywater

COPY --chmod=755 ./containers/wally-devel/container-setup.sh /etc/wally/container-setup.sh

ENV WALLY_CORE_DUMP_SIZE=300000
ENV WALLY_PYTHON_VENV_DIR=${RISCV_INSTALL_PREFIX}/riscv-python
ENV WALLY_PYTHON_EXECUTABLE=${WALLY_PYTHON_VENV_DIR}/bin/python

FROM ${WALLY_CONTAINER_BUILDER_IMAGE} as wally-devel
ARG TARGETARCH TARGETOS TARGETPLATFORM TARGETVARIANT
