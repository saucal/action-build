#!/bin/bash -e
if [ -f 'composer.json' ]; then
	echo "--------------------------------------------------"
	echo "Setup authentication for our SatisPress instance"
	if [ -n "${SATIS_KEY}" ]; then
		composer config http-basic.packages.saucal.com "${SATIS_KEY}" satispress
	else 
		echo "SatisPress key not set."
	fi

	# As we are on the deploy branch, plugins should exist. Run composer install to update dependencies as needed.
	echo "--------------------------------------------------"
	echo "Running composer install"
	composer install --no-dev
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
	
fi
