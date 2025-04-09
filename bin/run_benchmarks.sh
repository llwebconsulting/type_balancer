#!/bin/bash

# Default Ruby versions if no specific version is provided
RUBY_VERSIONS=("3.2.8" "3.3.7" "3.4.2")

# Parse command line arguments
SPECIFIC_VERSION=""
SPECIFIC_YJIT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --version|-v)
            SPECIFIC_VERSION="$2"
            shift 2
            ;;
        --yjit)
            SPECIFIC_YJIT="true"
            shift
            ;;
        --no-yjit)
            SPECIFIC_YJIT="false"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--version|-v VERSION] [--yjit|--no-yjit]"
            exit 1
            ;;
    esac
done

# Array to store image tags for cleanup
IMAGES_TO_CLEANUP=()

# Clean up previous results regardless of mode
rm -rf benchmark_results
mkdir -p benchmark_results

# Function to run benchmarks for a specific Ruby version
run_benchmarks() {
    local ruby_version=$1
    local enable_yjit=$2
    local yjit_flag=$3
    local tag_suffix=$4
    local image_tag="type_balancer:${ruby_version}${tag_suffix}"
    local result_file="benchmark_results/ruby${ruby_version}${tag_suffix}.txt"

    echo "Building image for Ruby ${ruby_version} (YJIT: ${enable_yjit})"
    
    # Build the Docker image with --no-cache
    if ! docker build --no-cache \
        --build-arg RUBY_VERSION=${ruby_version} \
        --build-arg ENABLE_YJIT=${enable_yjit} \
        --build-arg RUBY_YJIT_ENABLE=${yjit_flag} \
        -t ${image_tag} .; then
        echo "Error: Failed to build Docker image"
        return 1
    fi

    # Add image to cleanup list
    IMAGES_TO_CLEANUP+=("${image_tag}")

    echo "Running benchmarks for Ruby ${ruby_version} (YJIT: ${enable_yjit})"
    
    # Create results directory if it doesn't exist
    mkdir -p benchmark_results

    # Run the end-to-end benchmark
    echo "Running end-to-end benchmark..."
    if ! timeout 300 docker run --rm ${image_tag} /bin/bash -c "set -x && cd /app && \
        bundle exec ruby -I lib -I lib/type_balancer \
        benchmark/end_to_end_benchmark.rb" > "${result_file}" 2>&1; then
        echo "Error: End-to-end benchmarks timed out or failed"
        return 1
    fi

    echo "Finished benchmarks for Ruby ${ruby_version} (YJIT: ${enable_yjit})"
    return 0
}

if [ -n "$SPECIFIC_VERSION" ]; then
    # Run single version
    if [ -n "$SPECIFIC_YJIT" ]; then
        # Run with specific YJIT setting
        if [ "$SPECIFIC_YJIT" = "true" ]; then
            run_benchmarks $SPECIFIC_VERSION "true" "1" "_yjit"
        else
            run_benchmarks $SPECIFIC_VERSION "false" "0" ""
        fi
    else
        # Run both YJIT settings for specific version
        run_benchmarks $SPECIFIC_VERSION "false" "0" ""
        run_benchmarks $SPECIFIC_VERSION "true" "1" "_yjit"
    fi
else
    # Run full suite
    for version in "${RUBY_VERSIONS[@]}"; do
        # Run without YJIT
        run_benchmarks $version "false" "0" ""
        # Run with YJIT
        run_benchmarks $version "true" "1" "_yjit"
    done
fi

echo "All benchmarks completed. Results are in the benchmark_results directory."

# --- Cleanup --- 

echo "Cleaning up Docker images..."
if [ ${#IMAGES_TO_CLEANUP[@]} -gt 0 ]; then
    docker rmi ${IMAGES_TO_CLEANUP[@]} || true
else
    echo "No images to remove."
fi

# Clean up any lingering containers
echo "Cleaning up any lingering containers..."
docker ps -a | grep type_balancer | awk '{print $1}' | xargs -r docker rm -f || true

echo "Cleanup complete." 