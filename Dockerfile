# Allow platform to be specified at build time
ARG PLATFORM=linux/arm64
ARG RUBY_VERSION
FROM --platform=${PLATFORM} ruby:${RUBY_VERSION}-slim

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    pkg-config \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Rust if YJIT is enabled
ARG ENABLE_YJIT=false
ARG RUBY_YJIT_ENABLE=0
ENV RUBY_YJIT_ENABLE=${RUBY_YJIT_ENABLE}

RUN if [ "${ENABLE_YJIT}" = "true" ]; then \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; \
    fi

WORKDIR /app

# Copy all necessary files for building the gem
COPY Gemfile Gemfile.lock type_balancer.gemspec Rakefile ./
COPY lib/ lib/
COPY benchmark/ benchmark/

# Initialize Git repository and stage files (needed for gemspec)
RUN git init && \
    git add .

# Install dependencies
RUN bundle install

# Set environment variable for Ruby to find native extensions
ENV RUBYLIB=/app/lib

CMD ["bundle", "exec", "rake", "benchmark:complete"] 