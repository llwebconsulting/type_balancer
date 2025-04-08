ARG RUBY_VERSION
FROM ruby:${RUBY_VERSION}-slim

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Rust if YJIT is enabled
ARG ENABLE_YJIT=false
RUN if [ "${ENABLE_YJIT}" = "true" ]; then \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; \
    fi

WORKDIR /app

# Copy all necessary files for building the gem
COPY Gemfile Gemfile.lock type_balancer.gemspec Rakefile ./
COPY lib/ lib/
COPY ext/ ext/
COPY sig/ sig/
COPY benchmark/ benchmark/

# Initialize Git repository and stage files (needed for gemspec)
RUN git init && \
    git add .

# Install dependencies
RUN bundle install

# Create directory for compiled files
RUN mkdir -p /app/compiled

# Don't compile during build - will be done at runtime with mounted volume
CMD ["bundle", "exec", "rake", "benchmark:complete"] 