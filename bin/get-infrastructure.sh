#!/usr/bin/env bash

# This will pull the infrastructure module and install it
# curl --silent --show-error --retry 5 https://raw.githubusercontent.com/pivotal-energy-solutions/rc-files/master/bin/get-infrastructure.sh | sh

echo "Pulling data"

if ! [ -x "$(command -v sudo)" ]; then
    echo 'Error: sudo is not installed.' >&2
    exit 1
fi

if ! [ -x "$(command -v python2.7)" ]; then
    echo 'Error: sudo is not installed.' >&2
    exit 1
fi


if ! [ -x "$(command -v pip)" ]; then
    curl --silent --show-error --retry 5 https://bootstrap.pypa.io/get-pip.py | sudo python
fi


#sudo apt-get install python-pip python-dev build-essential
#
#sudo pip install
