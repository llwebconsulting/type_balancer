#!/bin/bash

# Array of Ruby versions to test
RUBY_VERSIONS=("3.2.8" "3.3.7" "3.4.2")

# Array to store image tags for cleanup
IMAGES_TO_CLEANUP=()

# Function to run benchmarks for a specific Ruby version
run_benchmarks() {
    local ruby_version=$1
    local enable_yjit=$2
    local yjit_flag=$3
    local tag_suffix=$4
    local image_tag="type_balancer:${ruby_version}${tag_suffix}"

    echo "Building image for Ruby ${ruby_version} (YJIT: ${enable_yjit})"
    
    # Build the Docker image
    docker build \
        --build-arg RUBY_VERSION=${ruby_version} \
        --build-arg ENABLE_YJIT=${enable_yjit} \
        --build-arg RUBY_YJIT_ENABLE=${yjit_flag} \
        -t ${image_tag} .

    # Add image to cleanup list
    IMAGES_TO_CLEANUP+=("${image_tag}")

    echo "Running benchmarks for Ruby ${ruby_version} (YJIT: ${enable_yjit})"
    
    # Create results directory if it doesn't exist
    mkdir -p benchmark_results

    # Run the benchmarks and save results
    # --rm flag ensures container is removed after running
    docker run --rm ${image_tag} /bin/bash -c "\
        bundle exec rake compile && \
        bundle exec rake benchmark:complete 2>&1" \
        > "benchmark_results/ruby${ruby_version}${tag_suffix}.txt"
}

# Clean up previous results
rm -rf benchmark_results
mkdir -p benchmark_results

# Run benchmarks for each Ruby version
for version in "${RUBY_VERSIONS[@]}"; do
    # Run without YJIT
    run_benchmarks $version "false" "0" ""
    # Run with YJIT
    run_benchmarks $version "true" "1" "_yjit"
done

echo "All benchmarks completed. Results are in the benchmark_results directory."

# Cleanup Docker images
echo "Cleaning up Docker images..."
for image in "${IMAGES_TO_CLEANUP[@]}"; do
    echo "Removing image ${image}"
    docker rmi ${image}
done
echo "Cleanup complete." 