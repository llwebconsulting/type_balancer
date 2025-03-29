FROM ruby:3.2-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile type_balancer.gemspec ./
COPY lib/type_balancer/version.rb lib/type_balancer/

RUN bundle install

COPY . .

CMD ["bundle", "exec", "rspec"] 