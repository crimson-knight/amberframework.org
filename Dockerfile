FROM crystallang/crystal:1.21.0@sha256:32b7b908a8c3625ebd629053daf48b6f469deaf74aeb71ad101895096b1665fa AS toolchain

WORKDIR /app
COPY config/toolchain_packages.lock config/toolchain_packages.lock
COPY scripts/install_pinned_toolchain.sh scripts/install_pinned_toolchain.sh
RUN sh scripts/install_pinned_toolchain.sh

FROM toolchain AS verification
RUN apt-get download ripgrep=14.1.0-1 && \
    printf 'c5ae63c7bee915b1cfc9f0bd07c55b4ce7f2bcd1133cba4da56719aac26101a4  ripgrep_14.1.0-1_amd64.deb\n' | sha256sum -c - && \
    dpkg -i ripgrep_14.1.0-1_amd64.deb && rm ripgrep_14.1.0-1_amd64.deb

FROM verification AS builder

WORKDIR /app

COPY shard.yml shard.lock ./
RUN shards-alpha install --frozen --production --skip-ai-docs

COPY src src
COPY config/*.cr config/
COPY config/environments config/environments
RUN mkdir -p bin && crystal-alpha build src/amberframework.cr --release --no-debug -Dwithout_mt -o bin/amberframework

COPY . .
RUN crystal-alpha run scripts/build_assets.cr
RUN crystal-alpha run scripts/build_assets.cr -- --check
RUN python3 scripts/build_publication_pages.py

FROM crystallang/crystal:1.21.0@sha256:32b7b908a8c3625ebd629053daf48b6f469deaf74aeb71ad101895096b1665fa AS production

ENV AMBER_ENV=production
WORKDIR /app

COPY --from=builder /app/bin/amberframework /app/bin/amberframework
COPY --from=builder /app/blog /app/blog
COPY --from=builder /app/config /app/config
COPY --from=builder /app/docs /app/docs
COPY --from=builder /app/public /app/public
COPY --from=builder /app/toolchain-receipts /app/toolchain-receipts

EXPOSE 3000
CMD ["/app/bin/amberframework"]
