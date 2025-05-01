# Changelog

## [0.2.1] - 2025-05-01

### Performance
- Major performance improvements in the sliding window strategy implementation:
  - Optimized window position calculation algorithm
  - Improved batch processing for large collections
  - Enhanced type distribution handling
  - Reduced memory usage and allocation
- Updated benchmark results showing consistent performance:
  - Tiny collections (10 items): 8-13μs
  - Small collections (100 items): 68-104μs
  - Medium collections (1,000 items): 648ms-1.03ms
  - Large collections (10,000 items): 6.6-10.0ms

### Enhanced
- Improved test suite with more focused test cases
- Reduced test execution time by optimizing large-scale test data
- Better handling of type ordering in Calculator and BaseStrategy
- Enhanced quality.rb output formatting for better readability
- Simplified large_scale_balance_test.rb implementation

### Fixed
- Rubocop violations:
  - Disabled Style/HashExcept cop
  - Added parameter list exceptions for complex method signatures
- Improved require statements in example scripts to use require_relative

## [0.2.0] - 2025-04-30

### Added
- Introduced strategy pattern for flexible balancing algorithms
- Added sliding window strategy as the default balancing algorithm
  - Configurable window size (default: 10)
  - Maintains both local and global type ratios
  - Adaptive behavior for remaining items
- Added comprehensive strategy documentation in README and balance.md
- Added large scale balance test suite for thorough strategy validation

### Enhanced
- Improved quality testing infrastructure
  - Added quality:all rake task that runs both quality.rb and large_scale_balance_test.rb
  - Enhanced CI workflow to run all quality checks
  - Added strategy-specific test cases
- Updated documentation with detailed strategy explanations and use cases
- Added extensive test coverage for strategy system

### Fixed
- Improved handling of type distribution in edge cases
- Better handling of remaining items when types are depleted
- Enhanced transition handling between windows

## [0.1.4] - 2025-04-29

### Fixed
- Fixed issue with providing a custom type field

## [0.1.3] - 2025-04-27

### Fixed
- Fixed type balancing behavior to properly handle edge cases where type ratios need to be maintained while respecting original collection order
- Enhanced position calculation to ensure consistent type distribution across the balanced collection
- Improved test coverage to verify correct type ratio preservation

## [0.1.2] - 2025-04-11

- Re-release of 0.1.1 due to RubyGems.org publishing issue
- No functional changes from 0.1.1

## [0.1.1] - 2025-04-10

### Refactoring
- Major refactoring of core components to follow SOLID principles:
  - Extracted core functionality into separate modules for better separation of concerns
  - Split balancer logic into `batch_processing`, `ratio_calculator`, and `type_extractor` modules
  - Improved error handling and type management
  - Enhanced position calculator with better edge case handling

### Documentation
- Added comprehensive project description and use cases to README
- Updated performance metrics with accurate benchmarks
- Improved contribution guidelines
- Enhanced quality script documentation

### Performance
- Updated benchmark results showing significant improvements:
  - Tiny collections (10 items): 6-10μs
  - Small collections (100 items): 30-52μs
  - Medium collections (1,000 items): 274-555μs
  - Large collections (10,000 items): 2.4-4.5ms

### Fixed
- Position calculator edge cases and quality checks
- RSpec test failures related to type extraction
- Custom type order handling in balancer implementation

## [0.1.0] - Initial Release

- Initial release of TypeBalancer
- Core functionality for balancing collections by type
- Basic documentation and tests
