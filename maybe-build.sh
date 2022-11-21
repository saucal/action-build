#!/bin/bash -e
# Build
mkdir -p "${GITHUB_WORKSPACE}/${BUILD_DIR}"
cd "${GITHUB_WORKSPACE}/${BUILD_DIR}";
if [ -f "$BUILD_DIR/.github/build-for-deployment.sh" ]; then
	echo "Running code specific build script"
	bash "$BUILD_DIR/.github/build-for-deployment.sh"
else
	echo "Running default build script"
	bash "$GITHUB_ACTION_PATH/build-for-deployment.sh"
fi
