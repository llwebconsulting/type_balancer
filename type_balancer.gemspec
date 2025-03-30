# frozen_string_literal: true

require_relative 'lib/type_balancer/version'

Gem::Specification.new do |spec|
  spec.name = 'type_balancer'
  spec.version = TypeBalancer::VERSION
  spec.authors = ['Carl']
  spec.email = ['carl@example.com']

  spec.summary = 'A Ruby gem for balancing items in a collection based on their types'
  spec.description = 'TypeBalancer helps you evenly distribute items in a collection based on their types, ' \
                     'maintaining a balanced representation of each type throughout the sequence.'
  spec.homepage = 'https://github.com/yourusername/type_balancer'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[lib/**/*.rb [A-Z]*.md])
  spec.require_paths = ['lib']
end
