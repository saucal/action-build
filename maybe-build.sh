#!/bin/bash -e
# Build
if [[ $BUILD_DIR != /* ]]; then
	BUILD_DIR="${GITHUB_WORKSPACE}/${BUILD_DIR}"
fi

mkdir -p "${BUILD_DIR}"

if [ -f "${BUILD_DIR}/.github/build-for-deployment.sh" ]; then
	echo "Running code specific build script"
	bash "${BUILD_DIR}/.github/build-for-deployment.sh"
	EXIT_CODE=$?
	if [ $EXIT_CODE -ne 0 ]; then
		exit $EXIT_CODE;
	fi
else
	echo "Running default build script"
	bash "$GITHUB_ACTION_PATH/build-for-deployment.sh"
	EXIT_CODE=$?
	if [ $EXIT_CODE -ne 0 ]; then
		exit $EXIT_CODE;
	fi
fi
