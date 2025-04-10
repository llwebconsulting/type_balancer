# frozen_string_literal: true

require_relative 'lib/type_balancer/version'

Gem::Specification.new do |spec|
  spec.name = 'type_balancer'
  spec.version = TypeBalancer::VERSION
  spec.authors = ['Carl Smith']
  spec.email = ['carl@llweb.biz']

  spec.summary = 'Balances types in collections'
  spec.description = 'Balances types in collections by ensuring each type appears a similar number of times'
  spec.homepage = 'https://github.com/llwebconsulting/type_balancer'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/llwebconsulting/type_balancer'
  spec.metadata['changelog_uri'] = 'https://github.com/llwebconsulting/type_balancer/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor ext/
                                                             c_tests/])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
end
