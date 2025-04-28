# Quality Script Documentation

The TypeBalancer gem includes a comprehensive quality check script located at `/examples/quality.rb`. This script serves multiple purposes:

1. **Documentation through Examples**: Demonstrates various use cases and features of the gem
2. **Quality Assurance**: Verifies that core functionality works as expected
3. **Integration Testing**: Tests how different components work together

## Running the Script

To run the quality script from the gem repository:

```bash
bundle exec ruby examples/quality.rb
```

### Running from Other Projects

You can run the quality script from any project that includes the TypeBalancer gem. This is useful for verifying the gem's behavior in your app or as part of CI for downstream projects.

**Example:**

```bash
bundle exec ruby /path/to/gems/type_balancer/examples/quality.rb
```

**How do I find the path to the gem?**

If you are not sure where the gem is installed, you can use Bundler to locate it:

```bash
bundle show type_balancer
```

This will print the path to the gem directory. The quality script is located in the `examples` subdirectory of that path. For example:

```bash
$ bundle show type_balancer
/Users/yourname/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/type_balancer-0.1.3
$ bundle exec ruby /Users/yourname/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/type_balancer-0.1.3/examples/quality.rb
```

- Ensure the gem is installed and available in your bundle.
- The script expects the test data file at `examples/balance_test_data.yml` (relative to the gem root).
- Output will be color-coded if your terminal supports ANSI colors.

## What it Tests

The script tests several key aspects of the TypeBalancer gem:

### 1. Basic Distribution
- Demonstrates how items are distributed across available slots
- Shows spacing calculations between positions
- Verifies edge cases (single item, no items, all items)

### 2. Robust Balance Method Tests
- Loads scenarios from a YAML file (`examples/balance_test_data.yml`)
- Tests `TypeBalancer.balance` with and without the `type_order` argument
- Checks type counts, custom order, and exception handling for empty input
- Prints a color-coded summary table for pass/fail counts

### 3. Content Feed Example
- Shows a real-world example of content type distribution
- Verifies position allocation for different content types (video, image, article)
- Checks distribution statistics and ratios

## Output Format

- Each section prints a color-coded summary table of passing and failing tests
- Failures and exceptions are highlighted in red; passes in green
- The final summary shows the total number of examples run and passed
- The script exits with status 0 if all tests pass, or 1 if any fail (CI-friendly)

## Using as a Development Tool

The quality script is particularly useful when:
1. Developing new features
2. Refactoring existing code
3. Verifying changes haven't broken core functionality
4. Understanding how different features work together

## Customizing/Extending the Script

- You can add new scenarios to `examples/balance_test_data.yml` to test additional cases or edge conditions.
- You may copy or extend the script for your own integration tests.
- The script can be adapted to accept a custom YAML path if needed (see comments in the script).

## Troubleshooting

- **Color output not working:** Ensure your terminal supports ANSI colors.
- **File not found:** Make sure `examples/balance_test_data.yml` exists and is accessible from the script's location.
- **Gem not found:** Ensure the TypeBalancer gem is installed and available in your bundle.
- **Path issues:** Use an absolute or correct relative path to the script when running from another project.

## Extending the Script

When adding new features to TypeBalancer, consider:
1. Adding relevant examples to the quality script
2. Including edge cases
3. Documenting expected behavior
4. Adding appropriate quality checks 