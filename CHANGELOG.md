# Changelog

## [0.1.1] - 2024-03-XX

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
