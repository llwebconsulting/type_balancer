# Quality Script Documentation

The TypeBalancer gem includes a comprehensive quality check script located at `/examples/quality.rb`. This script serves multiple purposes:

1. **Documentation through Examples**: Demonstrates various use cases and features of the gem
2. **Quality Assurance**: Verifies that core functionality works as expected
3. **Integration Testing**: Tests how different components work together

## Running the Script

To run the quality script:

```bash
bundle exec ruby examples/quality.rb
```

## What it Tests

The script tests several key aspects of the TypeBalancer gem:

### 1. Basic Distribution
- Demonstrates how items are distributed across available slots
- Shows spacing calculations between positions
- Verifies edge cases (single item, no items, all items)

### 2. Content Feed Example
- Shows a real-world example of content type distribution
- Verifies position allocation for different content types (video, image, article)
- Checks distribution statistics and ratios

### 3. Balancer API
- Tests the main TypeBalancer.balance method
- Verifies batch creation and size limits
- Demonstrates custom type ordering

### 4. Type Extraction
- Tests type extraction from both hash and object items
- Verifies support for different type field access methods

### 5. Error Handling
- Validates handling of empty collections
- Tests response to invalid type fields
- Verifies batch size validation

## Output Format

The script provides detailed output showing:
- Results of each test case
- Distribution statistics
- Any issues found during testing
- A summary of all examples run and passed

## Using as a Development Tool

The quality script is particularly useful when:
1. Developing new features
2. Refactoring existing code
3. Verifying changes haven't broken core functionality
4. Understanding how different features work together

## Extending the Script

When adding new features to TypeBalancer, consider:
1. Adding relevant examples to the quality script
2. Including edge cases
3. Documenting expected behavior
4. Adding appropriate quality checks 