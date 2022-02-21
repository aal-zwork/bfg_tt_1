ARG D_IMAGE_OS_NAME=ubuntu
ARG D_IMAGE_OS_VER=18.04
ARG D_IMAGE_TAG=$D_IMAGE_OS_NAME:$D_IMAGE_OS_VER

FROM $D_IMAGE_TAG as base
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq &&\
    apt-get install -y --no-install-recommends \
    ca-certificates curl wget tzdata bash vim && \
    apt-get purge -y --auto-remove && \
    rm -rf /var/lib/apt/lists/*


# For testing
FROM base as python-build
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    autoconf automake bzip2 dpkg-dev file g++ gcc imagemagick libbz2-dev libc6-dev libcurl4-openssl-dev \
    libdb-dev libevent-dev libffi-dev libgdbm-dev libglib2.0-dev libgmp-dev libjpeg-dev libkrb5-dev liblzma-dev \
    libmagickcore-dev libmagickwand-dev libmaxminddb-dev libncurses5-dev libncursesw5-dev libpng-dev libpq-dev \
    libreadline-dev libsqlite3-dev libssl-dev libtool libwebp-dev libxml2-dev libxslt-dev libyaml-dev \
    make patch unzip xz-utils zlib1g-dev default-libmysqlclient-dev && \
    apt-get purge -y --auto-remove && \
    rm -rf /var/lib/apt/lists/*

ENV PYTHON_VERSION=3.6.13
RUN mkdir -p /opt/sos/src/python-${PYTHON_VERSION} && cd /opt/sos/src/python-${PYTHON_VERSION} && \
    wget -O python-${PYTHON_VERSION}.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" && \
    tar -xJf python-${PYTHON_VERSION}.tar.xz --strip-components=1 && rm python-${PYTHON_VERSION}.tar.xz && \
    ./configure --build="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" --prefix=/opt/sos --enable-loadable-sqlite-extensions --enable-optimizations --enable-option-checking=fatal --with-system-expat --with-system-ffi --without-ensurepip && \
    make install && \
    find /opt/sos/ -depth \( \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name '*.a' \) \) -o \( -type f -a -name 'wininst-*.exe' \) \) -exec rm -rf '{}' + && \
    cd /opt/sos && rm -rf src

RUN cd /opt/sos/bin && ln -s idle3 idle && ln -s pydoc3 pydoc && ln -s python3 python && ln -s python3-config python-config

ENV PYTHON_PIP_VERSION=21.1.3
ENV PYTHON_GET_PIP_URL=https://github.com/pypa/get-pip/raw/a1675ab6c2bd898ed82b1f58c486097f763c74a9/public/get-pip.py
RUN mkdir -p /opt/sos/src/pip && cd /opt/sos/src/pip && \
    wget -O get-pip.py "$PYTHON_GET_PIP_URL" && \
    /opt/sos/bin/python get-pip.py --disable-pip-version-check --no-cache-dir "pip==$PYTHON_PIP_VERSION" && \
    find /opt/sos -depth \( \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \) -exec rm -rf '{}' + && \
    cd /opt/sos && rm -rf src


FROM base as prod
ENV container=docker  
STOPSIGNAL SIGRTMIN+3
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    systemd systemd-sysv && \
    apt-get purge -y --auto-remove && \
    rm -rf /var/lib/apt/lists/* && \
    rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev*\
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
    /lib/systemd/system/systemd-update-utmp*

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    openssh-server python3 && \
    apt-get purge -y --auto-remove && \
    rm -rf /var/lib/apt/lists/*

RUN ssh-keygen -A && mkdir /run/sshd && systemctl enable ssh

# TODO: Workaround! Need use secrets or volumes
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh
COPY id_rsa_bfg_1.pub /root/.ssh/authorized_keys
RUN touch /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys

# For testing
# COPY --from=python-build /opt/sos /opt/sos

ENTRYPOINT ["/sbin/init"]
CMD ["--log-level=info"]
# CMD [ "/usr/sbin/sshd", "-D" ]

WORKDIR /root