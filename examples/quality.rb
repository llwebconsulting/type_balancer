# frozen_string_literal: true

require 'type_balancer'
require 'yaml'

class QualityChecker
  GREEN = "\e[32m"
  RED = "\e[31m"
  YELLOW = "\e[33m"
  RESET = "\e[0m"

  def initialize
    @issues = []
    @examples_run = 0
    @examples_passed = 0
  end

  def run
    check_basic_distribution
    check_available_items
    check_edge_cases
    check_position_precision
    check_available_positions_edge_cases
    check_balance_method_robust
    check_real_world_feed
    check_custom_type_field

    print_summary
    exit(@issues.empty? ? 0 : 1)
  end

  private

  def record_issue(message)
    @issues << message
  end

  def check_basic_distribution
    @examples_run += 1
    @section_examples_run = 0 if !defined?(@section_examples_run)
    @section_examples_passed = 0 if !defined?(@section_examples_passed)
    @section_examples_run += 1
    puts "\nBasic Distribution Example:"
    positions = TypeBalancer.calculate_positions(total_count: 10, ratio: 0.3)

    if positions == [0, 5, 9]
      @examples_passed += 1
      @section_examples_passed += 1
    else
      record_issue("Basic distribution positions #{positions.inspect} don't match expected [0, 5, 9]")
    end

    spacing = positions&.each_cons(2)&.map { |a, b| b - a }
    puts "Positions for 3 items across 10 slots: #{positions.inspect}"
    puts "Spacing between positions: #{spacing.inspect}"

    return unless spacing != [5, 4]

    record_issue("Basic distribution spacing #{spacing.inspect} isn't optimal [5, 4]")
  end

  def check_available_items
    @examples_run += 1
    @section_examples_run += 1
    puts "\nAvailable Items Example:"
    positions = TypeBalancer.calculate_positions(
      total_count: 10,
      ratio: 0.5,
      available_items: [0, 1, 2]
    )

    if positions == [0, 1, 2]
      @examples_passed += 1
      @section_examples_passed += 1
    else
      record_issue("Available items test returned #{positions.inspect} instead of expected [0, 1, 2]")
    end

    puts "Positions when only 3 slots available: #{positions.inspect}"
  end

  def check_edge_cases
    puts "\nEdge Cases:"

    # Single item
    @examples_run += 1
    @section_examples_run += 1
    single = TypeBalancer.calculate_positions(total_count: 1, ratio: 1.0)
    puts "Single item: #{single.inspect}"
    if single == [0]
      @examples_passed += 1
      @section_examples_passed += 1
    else
      record_issue("Single item case returned #{single.inspect} instead of [0]")
    end

    # No items
    @examples_run += 1
    @section_examples_run += 1
    none = TypeBalancer.calculate_positions(total_count: 100, ratio: 0.0)
    puts "No items needed: #{none.inspect}"
    if none == []
      @examples_passed += 1
      @section_examples_passed += 1
    else
      record_issue("Zero ratio case returned #{none.inspect} instead of []")
    end

    # All items
    @examples_run += 1
    @section_examples_run += 1
    all = TypeBalancer.calculate_positions(total_count: 5, ratio: 1.0)
    puts "All items needed: #{all.inspect}"
    if all == [0, 1, 2, 3, 4]
      @examples_passed += 1
      @section_examples_passed += 1
    else
      record_issue("Full ratio case returned #{all.inspect} instead of [0, 1, 2, 3, 4]")
    end
    print_section_table('calculate_positions')
  end

  def check_position_precision
    puts "\nPosition Precision Cases:"
    
    # Two positions in three slots
    @examples_run += 1
    @section_examples_run += 1
    positions = TypeBalancer.calculate_positions(total_count: 3, ratio: 0.67)
    puts "Two positions in three slots: #{positions.inspect}"
    if positions == [0, 1]
      @examples_passed += 1
      @section_examples_passed += 1
    else
      record_issue("Two in three case returned #{positions.inspect} instead of [0, 1]")
    end

    # Single position in three slots
    @examples_run += 1
    @section_examples_run += 1
    positions = TypeBalancer.calculate_positions(total_count: 3, ratio: 0.34)
    puts "Single position in three slots: #{positions.inspect}"
    if positions == [0]
      @examples_passed += 1
      @section_examples_passed += 1
    else
      record_issue("One in three case returned #{positions.inspect} instead of [0]")
    end
    print_section_table('calculate_positions')
  end

  def check_available_positions_edge_cases
    puts "\nAvailable Positions Edge Cases:"

    # Single target with multiple available positions
    @examples_run += 1
    @section_examples_run += 1
    positions = TypeBalancer.calculate_positions(
      total_count: 5,
      ratio: 0.2,
      available_items: [1, 2, 3]
    )
    puts "Single target with multiple available: #{positions.inspect}"
    if positions == [1]
      @examples_passed += 1
      @section_examples_passed += 1
    else
      record_issue("Single target with multiple available returned #{positions.inspect} instead of [1]")
    end

    # Two targets with multiple available positions
    @examples_run += 1
    @section_examples_run += 1
    positions = TypeBalancer.calculate_positions(
      total_count: 10,
      ratio: 0.2,
      available_items: [1, 3, 5]
    )
    puts "Two targets with multiple available: #{positions.inspect}"
    if positions == [1, 5]
      @examples_passed += 1
      @section_examples_passed += 1
    else
      record_issue("Two targets with multiple available returned #{positions.inspect} instead of [1, 5]")
    end

    # Exact match of available positions
    @examples_run += 1
    @section_examples_run += 1
    positions = TypeBalancer.calculate_positions(
      total_count: 10,
      ratio: 0.3,
      available_items: [2, 4, 6]
    )
    puts "Exact match of available positions: #{positions.inspect}"
    if positions == [2, 4, 6]
      @examples_passed += 1
      @section_examples_passed += 1
    else
      record_issue("Exact match case returned #{positions.inspect} instead of [2, 4, 6]")
    end
    print_section_table('calculate_positions')
  end

  def check_balance_method_robust
    puts "\n#{YELLOW}Robust Balance Method Tests:#{RESET}"
    scenarios = YAML.load_file(File.expand_path('../balance_test_data.yml', __FILE__))
    section_run = 0
    section_passed = 0
    scenarios.each do |scenario|
      @examples_run += 1
      section_run += 1
      # Deep symbolize keys for all items in the scenario
      items = (scenario['items'] || []).map { |item| deep_symbolize_keys(item) }
      type_order = scenario['type_order']
      expected_type_counts = scenario['expected_type_counts'] || {}
      expected_first_type = scenario['expected_first_type']

      # Test with and without type_order
      [nil, type_order].uniq.each do |order|
        label = order ? "with type_order #{order}" : "default order"
        begin
          # Special handling for the empty input case
          if scenario['name'] =~ /empty/i
            begin
              if order
                TypeBalancer.balance(items, type_field: :type, type_order: order)
              else
                TypeBalancer.balance(items, type_field: :type)
              end
              # If no exception, this is a failure
              record_issue("#{scenario['name']} (#{label}): Expected exception for empty input, but none was raised")
              puts "#{RED}#{scenario['name']} (#{label}): Expected exception for empty input, but none was raised#{RESET}"
            rescue => e
              if e.message =~ /Collection cannot be empty/
                @examples_passed += 1
                section_passed += 1
                puts "#{GREEN}#{scenario['name']} (#{label}): Correctly raised exception for empty input#{RESET}"
              else
                record_issue("#{scenario['name']} (#{label}): Unexpected exception: #{e}")
                puts "#{RED}#{scenario['name']} (#{label}): Unexpected exception: #{e}#{RESET}"
              end
            end
            next
          end
          # Normal test logic for other cases
          result = if order
            TypeBalancer.balance(items, type_field: :type, type_order: order)
          else
            TypeBalancer.balance(items, type_field: :type)
          end
        rescue => e
          record_issue("#{scenario['name']} (#{label}): Exception raised: #{e}")
          puts "#{RED}#{scenario['name']} (#{label}): Exception raised: #{e}#{RESET}"
          next
        end
        # Check type counts
        type_counts = result.group_by { |i| i[:type] }.transform_values(&:size)
        if expected_type_counts && !expected_type_counts.empty?
          if type_counts != expected_type_counts
            record_issue("#{scenario['name']} (#{label}): Type counts #{type_counts.inspect} do not match expected #{expected_type_counts.inspect}")
            puts "#{RED}#{scenario['name']} (#{label}): Type counts #{type_counts.inspect} do not match expected #{expected_type_counts.inspect}#{RESET}"
          else
            @examples_passed += 1
            section_passed += 1
            puts "#{GREEN}#{scenario['name']} (#{label}): Passed#{RESET}"
          end
        end
        # Check first type for custom order
        if expected_first_type && order
          if result.first && result.first[:type] != expected_first_type
            record_issue("#{scenario['name']} (#{label}): First type #{result.first[:type]} does not match expected #{expected_first_type}")
            puts "#{RED}#{scenario['name']} (#{label}): First type #{result.first[:type]} does not match expected #{expected_first_type}#{RESET}"
          else
            @examples_passed += 1
            section_passed += 1
            puts "#{GREEN}#{scenario['name']} (#{label}): Custom order respected#{RESET}"
          end
        end
        puts "  Result: #{result.map { |i| i[:type] }.inspect}"
        puts "  Type counts: #{type_counts.inspect}"
      end
    end
    print_section_table('balance_method', section_run, section_passed)
  end

  # Helper to deeply symbolize keys in a hash
  def deep_symbolize_keys(obj)
    case obj
    when Hash
      obj.each_with_object({}) { |(k, v), h| h[k.to_sym] = deep_symbolize_keys(v) }
    when Array
      obj.map { |v| deep_symbolize_keys(v) }
    else
      obj
    end
  end

  def check_real_world_feed
    @examples_run += 1
    puts "\n#{YELLOW}Real World Example - Content Feed:#{RESET}"
    feed_size = 20
    items = [
      { type: 'video', id: 1 },
      { type: 'video', id: 2 },
      { type: 'video', id: 3 },
      { type: 'image', id: 4 },
      { type: 'image', id: 5 },
      { type: 'image', id: 6 },
      { type: 'article', id: 7 },
      { type: 'article', id: 8 },
      { type: 'article', id: 9 }
    ]
    # Test with custom type order
    ordered_result = TypeBalancer.balance(
      items,
      type_field: :type,
      type_order: %w[article image video]
    )
    if ordered_result.first[:type] == 'article'
      @examples_passed += 1
      puts "#{GREEN}Custom type order respected in real world feed#{RESET}"
      print_section_table('real_world_feed', 1, 1)
    else
      record_issue("Custom type order not respected in real world feed")
      puts "#{RED}Custom type order not respected in real world feed#{RESET}"
      print_section_table('real_world_feed', 1, 0)
    end
    puts "  Balanced items with custom order: #{ordered_result.map { |i| i[:type] }.inspect}"
  end

  def check_custom_type_field
    @examples_run += 1
    puts "\nCustom Type Field Example:"
    data = [
      { category: 'A', payload: 1 },
      { category: 'B', payload: 2 },
      { category: 'C', payload: 3 },
      { category: 'A', payload: 4 }
    ]
    balanced = TypeBalancer.balance(data, type_field: :category)
    found = balanced.map { |i| i[:category] }.uniq.sort
    expected = %w[A B C]
    if found == expected
      @examples_passed += 1
      puts "#{GREEN}Custom field respected: #{found.inspect}#{RESET}"
    else
      record_issue("Expected #{expected.inspect}, got #{found.inspect}")
      puts "#{RED}Custom field test failed: #{found.inspect}#{RESET}"
    end
    print_section_table('custom_type_field', 1, found == expected ? 1 : 0)
  end

  def print_summary
    puts "\n#{'-' * 50}"
    puts 'Quality Check Summary:'
    puts "Examples Run: #{@examples_run}"
    puts "Expectations Passed: #{@examples_passed}"

    if @issues.empty?
      puts "\n#{GREEN}All quality checks passed! ✓#{RESET}"
    else
      puts "\n#{RED}Quality check failed with #{@issues.size} issues:#{RESET}"
      @issues.each_with_index do |issue, index|
        puts "#{RED}#{index + 1}. #{issue}#{RESET}"
      end
    end
    puts "#{'-' * 50}"
  end

  # Print a summary table for a section
  def print_section_table(section, run = @section_examples_run, passed = @section_examples_passed)
    failed = run - passed
    puts "\nSection: #{section}"
    puts "-----------------------------"
    puts "  #{GREEN}Passing: #{passed}#{RESET}"
    puts "  #{RED}Failing: #{failed}#{RESET}"
    puts "-----------------------------\n"
    # Reset section counters for next section
    @section_examples_run = 0
    @section_examples_passed = 0
  end
end

QualityChecker.new.run
