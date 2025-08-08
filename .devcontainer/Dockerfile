FROM ghcr.io/almalinux/almalinux:8

# Install necessary packages
RUN dnf install -y git && \
    dnf install -y curl --allowerasing && \
    dnf clean all

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y make automake gcc gcc-c++ kernel-devel && \
    dnf clean all