# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/extensiontask'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new

Rake::ExtensionTask.new('type_balancer') do |ext|
  ext.lib_dir = 'lib/type_balancer'
  ext.ext_dir = 'ext/type_balancer'
  ext.source_pattern = '*.{c,h}'
  ext.config_options = ['--with-cflags=-Wall -Wextra -O3']
end

Rake::ExtensionTask.new('gap_fillers') do |ext|
  ext.lib_dir = 'lib/type_balancer'
  ext.ext_dir = 'ext/type_balancer'
  ext.source_pattern = '*.{c,h}'
  ext.config_options = ['--with-cflags=-Wall -Wextra -O3']
  ext.config_script = 'gap_fillers_extconf.rb'
end

# Add GoogleTest task using CMake
namespace :gtest do
  desc 'Build and run all GoogleTest tests'
  task :all do
    Dir.chdir('c_tests') do
      sh './build.sh'
    end
  end

  desc 'Build and run a specific GoogleTest test (e.g., rake gtest:run[TestSuite.TestName])'
  task :run, [:test_name] do |_, args|
    test_filter = args[:test_name] ? "--gtest_filter=#{args[:test_name]}" : ''
    Dir.chdir('c_tests') do
      sh "rm -rf build && mkdir build && cd build && cmake .. && make && ./type_balancer_tests #{test_filter} | cat"
    end
  end

  desc 'List all available GoogleTest tests'
  task :list do
    Dir.chdir('c_tests') do
      sh 'rm -rf build && mkdir build && cd build && cmake .. && make && ./type_balancer_tests --gtest_list_tests | cat'
    end
  end
end

namespace :lint do
  desc 'Run C linting with clang-tidy'
  task :c do
    mkdir_p 'c_tests/build'
    Dir.chdir('c_tests/build') do
      sh 'cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..'
    end
    sh 'clang-tidy -p c_tests/build ext/type_balancer/*.{c,h}'
  end

  desc 'Run all linting checks'
  task all: %i[rubocop c]
end

desc 'Run all tests with proper mocking'
task test_with_mocks: [:spec] do
  puts 'Running tests with proper mocking...'
  Rake::Task['gtest:all'].invoke
end

task default: [:test_with_mocks, 'lint:all']

# Benchmark tasks
namespace :benchmark do
  desc 'Run distributor benchmark comparing C extension vs Pure Ruby (without YJIT)'
  task :distributor do
    ruby 'benchmark/distributor_benchmark.rb'
  end

  desc 'Run combined benchmark comparing full C vs Ruby implementations (without YJIT)'
  task :combined do
    ruby 'benchmark/combined_benchmark.rb'
  end

  desc 'Run all benchmarks (without YJIT)'
  task all: %i[distributor combined]

  namespace :yjit do
    desc 'Run distributor benchmark comparing C extension vs Pure Ruby with YJIT enabled'
    task :distributor do
      ENV['RUBY_YJIT_ENABLE'] = '1'
      ruby 'benchmark/distributor_benchmark.rb'
    end

    desc 'Run combined benchmark comparing full C vs Ruby implementations with YJIT enabled'
    task :combined do
      ENV['RUBY_YJIT_ENABLE'] = '1'
      ruby 'benchmark/combined_benchmark.rb'
    end

    desc 'Run all benchmarks with YJIT enabled'
    task all: %i[distributor combined]
  end

  desc 'Run all benchmarks with and without YJIT'
  task complete: %i[all yjit:all]
end
