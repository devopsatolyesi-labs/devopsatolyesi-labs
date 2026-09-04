#!/usr/bin/env bash
echo "Building project in workspace: $(pwd)"
mkdir -p build_output
echo "Build v${BUILD_NUMBER:-1}" > build_output/info.txt
