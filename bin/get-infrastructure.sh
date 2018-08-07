#!/usr/bin/env bash

# This will pull the infrastructure module and install it
# curl --silent --show-error --retry 5 https://raw.githubusercontent.com/pivotal-energy-solutions/rc-files/master/bin/get-infrastructure.sh | sh

echo "Building the stack"

if ! [ -x "$(command -v sudo)" ]; then
    echo 'Error: sudo is not installed.' >&2
    exit 1
fi

if ! [ -x "$(command -v python2.7)" ]; then
    echo 'Error: python2.7 is not installed.' >&2
    exit 1
fi

if ! [ -x "$(command -v git)" ]; then
    echo "Installing git"
    sudo yum install -y git
fi


if ! [ -x "$(command -v pip)" ]; then
    echo "Installing python pip"
    curl --silent --show-error --retry 5 https://bootstrap.pypa.io/get-pip.py | sudo python
fi

sudo pip install https://github.com/pivotal-energy-solutions/tensor-infrastructure.git
