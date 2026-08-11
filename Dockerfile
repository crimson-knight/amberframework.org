FROM crystallang/crystal:1.21.0 AS builder

WORKDIR /app

COPY shard.yml shard.lock ./
RUN shards install --production

COPY . .
RUN shards build amberframework --release --no-debug

FROM crystallang/crystal:1.21.0 AS production

ENV AMBER_ENV=production
WORKDIR /app

COPY --from=builder /app/bin/amberframework /app/bin/amberframework
COPY --from=builder /app/blog /app/blog
COPY --from=builder /app/config /app/config
COPY --from=builder /app/docs /app/docs
COPY --from=builder /app/public /app/public

EXPOSE 3000
CMD ["/app/bin/amberframework"]
