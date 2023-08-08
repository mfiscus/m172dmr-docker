# syntax=docker/dockerfile:1-labs

FROM --platform=linux/arm/v7 navikey/raspbian-bullseye:latest AS base
#FROM --platform=linux/arm/v7 mfiscus/raspberrypios:bullseye AS base

ENTRYPOINT ["/init"]

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8" TZ="UTC"
ENV XLXMODULE="A" M172DMR_CONFIG_DIR="/config" M172DMR_CONFIG_TMP_DIR="/config_tmp"
ENV URL LOCATION="Nowhere" DESCRIPTION="Multi-Mode Repeater" CALLSIGN="AD8DP D" LOCALPORT="32010"
ENV DSTNAME="M17-USA Z" DSTPORT="17000" GAINADJUSTDB="-3" DAEMON="0" ID="1234567"
ENV XLXFILE="/config/XLXHosts.txt" XLXREFLECTOR="950" XLXMODULE="A" STARTUPSTID="4001" STARTUPPC="1"
ENV ADDRESS="127.0.0.1" PORT="62030" JITTER="500" PASSWORD="passw0rd" FILE="/config/DMRIDs.dat"
ARG M172DMR_INST_DIR="/src/MMDVM_CM" MD380VOCODER_INST_DIR="/src/md380_vocoder"
ARG IMBEVOCODER_INST_DIR="/src/imbe_vocoder" MBELIB_INST_DIR="/src/mbelib"
ARG ARCH=x86_64 S6_OVERLAY_VERSION=3.1.5.0 S6_RCD_DIR=/etc/s6-overlay/s6-rc.d S6_LOGGING=1 S6_KEEP_ENV=1

# install dependencies
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt update && \
    apt upgrade -y && \
    apt install -y \
        build-essential \
        cmake \
        curl \
        wget

# Setup directories
RUN mkdir -p \
    ${IMBEVOCODER_INST_DIR} \
    ${M172DMR_CONFIG_DIR} \
    ${MBELIB_INST_DIR} \
    ${MD380VOCODER_INST_DIR} \
    ${M172DMR_CONFIG_TMP_DIR} \
    ${M172DMR_INST_DIR}

# Fetch and extract S6 overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${ARCH}.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-${ARCH}.tar.xz

# Clone md380_vocoder repository
ADD --keep-git-dir=true https://github.com/nostar/md380_vocoder.git#master ${MD380VOCODER_INST_DIR}

# Clone imbe_vocoder repository
ADD --keep-git-dir=true https://github.com/nostar/imbe_vocoder.git#master ${IMBEVOCODER_INST_DIR}

# Clone mbelib repository
ADD --keep-git-dir=true https://github.com/szechyjs/mbelib.git#master ${MBELIB_INST_DIR}

# Clone M172DMR repository
ADD --keep-git-dir=true https://github.com/juribeparada/MMDVM_CM.git#master ${M172DMR_INST_DIR}

# Copy in source code (use local sources if repositories go down)
#COPY src/ /

# Compile and install md380_vocoder
RUN cd ${MD380VOCODER_INST_DIR} && \
    make && \
    make install && \
    ldconfig

# Compile and install md380_vocoder
RUN cd ${IMBEVOCODER_INST_DIR} && \
    make && \
    make install && \
    ldconfig

# Compile and install mbelib
RUN cd ${MBELIB_INST_DIR} && \
    mkdir -p build && cd build && \
    cmake .. && \
    make && \
    make install && \
    ldconfig

# Perform pre-compiliation configurations (move ini from from /etc to /config)
RUN sed -i "s'\(DEFAULT_INI_FILE[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*'\1\"${M172DMR_CONFIG_DIR}/M172DMR.ini\";'g" ${M172DMR_INST_DIR}/M172DMR/M172DMR.cpp

# Compile and install M172DMR
RUN cd ${M172DMR_INST_DIR}/M172DMR && \
    make && \
    make install

# Install configuration files
RUN cp -v ${M172DMR_INST_DIR}/M172DMR/M172DMR.ini ${M172DMR_CONFIG_TMP_DIR}/

# Copy in s6 service definitions and scripts
COPY root/ /

# Cleanup
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt -y purge \
        build-essential \
        cmake \
        wget && \
    apt -y autoremove && \
    apt -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    rm -rf /src

HEALTHCHECK --interval=5s --timeout=2s --retries=20 CMD /healthcheck.sh || exit 1