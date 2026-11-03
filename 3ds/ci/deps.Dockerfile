# The build environment for the port's releases: devkitPro's 3DS toolchain, the 3DS libraries it ships, makerom and
# bannertool, and OpenMW's dependencies cross-built by deps/build-deps.sh into /work/3ds/.deps. The release builds
# link 3ds/.deps to it. Built from the repository's root:
#
#     docker build -f 3ds/ci/deps.Dockerfile -t openmw-3ds-deps .

FROM devkitpro/devkitarm:20260610

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential cmake ninja-build python3 patch unzip zip xz-utils \
        bzip2 curl ca-certificates file pkg-config autoconf automake libtool git \
    && rm -rf /var/lib/apt/lists/*

RUN dkp-pacman -Sy --noconfirm --needed 3ds-dev 3ds-zlib 3ds-lz4 3ds-yaml_cpp 3ds-liblua51 3ds-mpg123 3ds-libpng \
        3ds-freetype 3ds-libjpeg-turbo 3ds-bzip2 \
    && dkp-pacman -Scc --noconfirm

RUN curl -sSfL -o /tmp/makerom.zip \
        https://github.com/3DSGuy/Project_CTR/releases/download/makerom-v0.19.0/makerom-v0.19.0-ubuntu_x86_64.zip \
    && unzip -q /tmp/makerom.zip -d /tmp/makerom \
    && install -m 755 "$(find /tmp/makerom -name makerom -type f | head -1)" /usr/local/bin/makerom \
    && curl -sSfL -o /tmp/bannertool.tar.gz \
        https://github.com/carstene1ns/3ds-bannertool/releases/download/1.2.3/bannertool-1.2.3-linux.tar.gz \
    && mkdir /tmp/bannertool && tar -xzf /tmp/bannertool.tar.gz -C /tmp/bannertool \
    && install -m 755 "$(find /tmp/bannertool -name bannertool -type f | grep -m1 x86_64 || find /tmp/bannertool -name bannertool -type f | head -1)" \
        /usr/local/bin/bannertool \
    && rm -rf /tmp/makerom* /tmp/bannertool* \
    && makerom -version | head -1 && bannertool 2>&1 | head -1

COPY 3ds/deps /work/3ds/deps
RUN bash /work/3ds/deps/build-deps.sh \
    && rm -rf /work/3ds/.deps/build /work/3ds/.deps/src /work/3ds/.deps/pristine /work/3ds/.deps/downloads

# The git tree of 3ds/deps the image was built from: a build checks it against its own (3ds/ci/check-deps.sh).
ARG DEPS_TREE=unknown
RUN echo "$DEPS_TREE" > /work/deps-tree
