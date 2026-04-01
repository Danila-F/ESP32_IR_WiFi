FROM mcr.microsoft.com/devcontainers/base:bookworm

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        cmake \
        git \
        libusb-1.0-0 \
        ninja-build \
        openssh-client \
        python3-pip \
        python3-venv \
        usbutils \
        udev \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/platformio \
    && /opt/platformio/bin/pip install --no-cache-dir --upgrade pip setuptools wheel \
    && /opt/platformio/bin/pip install --no-cache-dir platformio \
    && ln -sf /opt/platformio/bin/pio /usr/local/bin/pio \
    && ln -sf /opt/platformio/bin/platformio /usr/local/bin/platformio
