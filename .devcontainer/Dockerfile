FROM mcr.microsoft.com/devcontainers/base:bookworm

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        cmake \
        git \
        libusb-1.0-0 \
        ninja-build \
        python3-pip \
        python3-venv \
        usbutils \
        udev \
    && rm -rf /var/lib/apt/lists/*
