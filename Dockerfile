# Stage 1
FROM debian:bookworm-slim AS builder

WORKDIR /build

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl python3 git build-essential pkg-config && \
    rm -rf /var/lib/apt/lists/*

# Install ninja
RUN git clone --branch=v1.12.1 --depth=1 https://github.com/ninja-build/ninja.git && \
    cd ninja && \
    ./configure.py --bootstrap && \
    chmod +x ninja && \
    mv ninja /usr/local/bin/ninja

# Install meson
RUN git clone --branch=1.6.1 --depth=1 https://github.com/mesonbuild/meson.git && \
    cd meson && \
    ./packaging/create_zipapp.py --outfile meson.pyz --interpreter '/usr/bin/env python3' && \
    chmod +x meson.pyz && \
    mv meson.pyz /usr/local/bin/meson

# Stage 2
FROM debian:bookworm-slim 

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y \
    curl python3 build-essential git pkg-config libglib2.0-dev libexpat1-dev libheif-dev\
    liblcms2-dev libjpeg-dev libpng-dev libwebp-dev libexif-dev && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt install -y nodejs

# Copy build tools from builder stage
COPY --from=builder /usr/local/bin/ninja /usr/local/bin/ninja
COPY --from=builder /usr/local/bin/meson /usr/local/bin/meson

# Build libvips
RUN git clone --branch=v8.16.0 --depth=1 https://github.com/libvips/libvips.git && \
    cd libvips && \
    meson setup build --prefix /usr/local --libdir=lib && \
    cd build && \
    meson compile && \
    meson install && \
    ldconfig && \
    cd .. && \
    rm -rf libvips

ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig
ENV LD_LIBRARY_PATH=/usr/local/lib

WORKDIR /app

RUN pkg-config --cflags vips-cpp && pkg-config --libs vips-cpp

# Ensure sharp builds against system libvips
ENV npm_config_build_from_source=true
ENV SHARP_IGNORE_GLOBAL_LIBVIPS=0

COPY package.json package-lock.json ./
RUN npm i --build-from-source

# Copy app
COPY . .