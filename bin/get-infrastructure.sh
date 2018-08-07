#!/usr/bin/env bash

# This will pull the infrastructure module and install it
# curl -sSL --retry 5 https://github.com/pivotal-energy-solutions/rc-files/raw/master/bin/get-infrastructure.sh | sh -s -- -c beta

echo "Building the stack"

if ! [ -x "$(command -v sudo)" ]; then
    echo 'Error: sudo is not installed.' >&2
    exit 1
fi

if ! [ -x "$(command -v python3)" ]; then
    PYTHON_VERSION=3.7.0
    echo 'Error: ${PYTHON_VERSION} is not installed.' >&2
    sudo yum -y groupinstall "development tools"
    sudo yum -y install openssl-libs openssl-devel bzip2-devel zlib zlib-devel libffi-devel wget git nmap-ncat which
    # Build up Python 3.7
    cd /usr/src
    sudo wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
    sudo tar xzf Python-${PYTHON_VERSION}.tgz
    cd /usr/src/Python-${PYTHON_VERSION}
    sudo ./configure --enable-optimizations
    sudo make install
    cd /usr/src
    sudo rm -rf /usr/src/Python-${PYTHON_VERSION}
    sudo rm /usr/src/Python-${PYTHON_VERSION}.tgz

    # Build up Python 3.7 Links so it's easy to find it
    sudo ln -s /usr/local/bin/python3.7 /usr/bin/python3.7
    sudo ln -s /usr/local/bin/python3.7 /usr/bin/python3
    sudo ln -s /usr/local/bin/pip3.7 /usr/bin/pip3.7
    sudo ln -s /usr/local/bin/pip3 /usr/bin/pip3
    sudo ln -s /usr/local/bin/easy_install-3.7 /usr/bin/easy_install-3.7
    sudo ln -s /usr/local/bin/easy_install-3.7 /usr/bin/easy_install-3
fi

if ! [ -x "$(command -v git)" ]; then
    echo "Installing git"
    sudo yum install -y git
fi

# Update pip and install pipenv
sudo pip3 install -qq --upgrade pip
sudo pip3 install -qq --upgrade pipenv

# "Ensuring that we can connect to github over ssh"
ssh-keygen -F github.com >/dev/null || sudo ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null

pip3 install -qq --upgrade --no-cache-dir --user git+ssh://git@github.com/pivotal-energy-solutions/tensor-infrastructure.git

create_or_update_ami.py $@