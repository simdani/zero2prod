FROM lukemathwalker/cargo-chef:latest-rust-1.53:0 AS chef
WORKDIR /app

FROM chef as planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef as builder
COPY --from=planner /app/recipe.json recipe.json

RUN cargo chef cook --release --recipe-path recipe.json

COPY . .
ENV SQLX_OFFLINE true
RUN cargo build --release --bin zero2prod

# runtime stage
FROM debian:bullseye-slim AS runtime
WORKDIR /app
# install openssl
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends openssl \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# copy the ocmpiled binary from the builder environment to our runtime environment
COPY --from=builder /app/target/release/zero2prod zero2prod

# copy configuration
COPY configuration configuration
ENV APP_ENVIRONMENT production

ENTRYPOINT ["./target/release/zero2prod"]