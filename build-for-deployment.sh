#!/bin/bash -e
set -e

if [ -f 'composer.json' ]; then
	echo "--------------------------------------------------"
	echo "Setup authentication for our SatisPress instance"
	if [ -n "${SATIS_KEY}" ]; then
		composer config http-basic.packages.saucal.com "${SATIS_KEY}" "$(composer config homepage | sed 's,http[s]\?://,,')"
	else 
		echo "SatisPress key not set."
	fi

	if [ "${VALIDATE_COMPOSER}" == "true" ]; then
		echo "--------------------------------------------------"
		echo "Validating composer structure"
		composer validate --strict --no-check-all --no-check-publish --check-lock
		EXIT_CODE=$?
		if [ $EXIT_CODE -ne 0 ]; then
			exit $EXIT_CODE;
		fi
	fi

	# As we are on the deploy branch, plugins should exist. Run composer install to update dependencies as needed.
	echo "--------------------------------------------------"
	echo "Running composer install"

	# Check if the type of the composer project requires the autoloader
	REQUIRE_AUTOLOADER="plugin theme wordpress-plugin wordpress-theme"
	if [[ $REQUIRE_AUTOLOADER =~ $(composer config type) ]]; then
		composer install --no-dev
	else
		echo "Not installing autoloader as the type is not set to any of: $REQUIRE_AUTOLOADER"
		composer install --no-dev --no-autoloader
	fi

else
	echo "--------------------------------------------------"
	echo "No composer.json found. Skipping composer install."
fi

if [ -f 'package.json' ]; then
	if [ -f 'pnpm-lock.yaml' ]; then
		echo "--------------------------------------------------"
		echo "Installing node dependencies"
		pnpm recursive install --shamefully-hoist
		echo "--------------------------------------------------"
		echo "Running node build (if present)"
		pnpm recursive run build --if-present
		echo "--------------------------------------------------"
		echo "Running node test (if present)"
		pnpm recursive run test --if-present
	elif [ "null" = "$(jq -cM '.workspaces' < package.json)" ]; then
		echo "--------------------------------------------------"
		echo "Installing node dependencies"
		npm ci
		echo "--------------------------------------------------"
		echo "Running node build (if present)"
		npm run build --if-present
		echo "--------------------------------------------------"
		echo "Running node test (if present)"
		npm run test --if-present
	else
		echo "--------------------------------------------------"
		echo "Installing node dependencies"
		npm install -ws
		echo "--------------------------------------------------"
		echo "Running node build (if present)"
		npm run build --if-present -r
		echo "--------------------------------------------------"
		echo "Running node test (if present)"
		npm run test --if-present -r
	fi
else
	echo "--------------------------------------------------"
	echo "No package.json found. Skipping node install."
fi
