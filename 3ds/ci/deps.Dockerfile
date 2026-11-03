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

# makerom and bannertool built here: their prebuilt Linux releases need a newer glibc than this image's.
RUN git clone -q --depth 1 --branch makerom-v0.19.0 https://github.com/3DSGuy/Project_CTR.git /tmp/ctr \
    && make -C /tmp/ctr/makerom deps -j"$(nproc)" > /dev/null \
    && make -C /tmp/ctr/makerom -j"$(nproc)" > /dev/null \
    && install -m 755 "$(find /tmp/ctr/makerom -name makerom -type f -perm -u+x | head -1)" /usr/local/bin/makerom \
    && git clone -q --depth 1 --branch 1.2.3 --recurse-submodules https://github.com/carstene1ns/3ds-bannertool.git /tmp/bannertool \
    && cmake -S /tmp/bannertool -B /tmp/bannertool/build -G Ninja -DCMAKE_BUILD_TYPE=Release > /dev/null \
    && cmake --build /tmp/bannertool/build > /dev/null \
    && install -m 755 "$(find /tmp/bannertool/build -name bannertool -type f | head -1)" /usr/local/bin/bannertool \
    && rm -rf /tmp/ctr /tmp/bannertool \
    && makerom 2>&1 | head -2 && bannertool 2>&1 | head -2 && ldd /usr/local/bin/bannertool /usr/local/bin/makerom

COPY 3ds/deps /work/3ds/deps
RUN bash /work/3ds/deps/build-deps.sh \
    && rm -rf /work/3ds/.deps/build /work/3ds/.deps/src /work/3ds/.deps/pristine /work/3ds/.deps/downloads

# The image's id (3ds/ci/deps-id.sh): a build checks it against its own commit's (3ds/ci/check-deps.sh).
ARG DEPS_ID=unknown
RUN echo "$DEPS_ID" > /work/deps-id
