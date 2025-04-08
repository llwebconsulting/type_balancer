# frozen_string_literal: true

module TypeBalancer
  # This file serves as a wrapper for the C extension gap fillers
  begin
    # Load the main extension which includes the gap fillers
    require 'type_balancer/type_balancer'
    GAP_FILLERS_EXT_LOADED = true
  rescue LoadError => e
    # Don't provide a fallback - the C extension is required
    GAP_FILLERS_EXT_LOADED = false

    # Raise an error with detailed instructions
    raise LoadError, <<~ERROR_MESSAGE
      The C extension could not be loaded: #{e.message}

      This gem requires the C extension to be properly built. To fix this:

      1. Make sure you have a C compiler installed (gcc/clang)
      2. Make sure development headers are installed
      3. Try reinstalling the gem with:
         $ gem uninstall type_balancer
         $ gem install type_balancer

      If you're using Bundler:
         $ bundle pristine type_balancer

      If building from source:
         $ bundle exec rake compile

      For more information, see the README or contact the gem maintainers.
    ERROR_MESSAGE
  end
end
