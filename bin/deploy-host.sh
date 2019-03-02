#!/usr/bin/env bash

exec > >(tee /var/log/user-data.log) 2>&1

# This will build a deployment host as part of userdata package.
# User data should look like this..

if ! [ -x "$(command -v sudo)" ]; then
    echo 'Error: sudo is not installed.' >&2
    exit 1
fi

if ! [ -x "$(command -v python3)" ]; then
    echo 'Error: python3 is not installed.' >&2
    exit 1
fi

if ! [ -x "$(command -v pip3)" ]; then
    echo 'Error: pip3 is not installed.' >&2
    exit 1
fi

pip3 install -qq --upgrade --no-cache-dir --user git+ssh://git@github.com/pivotal-energy-solutions/tensor-infrastructure.git

deploy_host.py $@
