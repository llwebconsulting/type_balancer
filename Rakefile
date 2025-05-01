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

# Quality check tasks
namespace :quality do
  desc 'Run basic quality checks'
  task :basic do
    puts "\nRunning basic quality checks..."
    ruby '-I lib examples/quality.rb'
  end

  desc 'Run large scale balance tests'
  task :large_scale do
    puts "\nRunning large scale balance tests..."
    ruby '-I lib examples/large_scale_balance_test.rb'
  end

  desc 'Run all quality checks'
  task all: %i[basic large_scale]
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

task default: [:test_with_mocks, 'lint:all', 'quality:all']

# Benchmark tasks
namespace :benchmark do
  desc 'Run end-to-end benchmarks'
  task :end_to_end do
    ruby 'benchmark/end_to_end_benchmark.rb'
  end

  desc 'Run all benchmarks'
  task all: [:end_to_end]

  desc 'Run complete benchmark suite'
  task complete: [:all]
end
