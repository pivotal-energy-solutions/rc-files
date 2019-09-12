#!/usr/bin/env bash

# This will pull the infrastructure module and install it
# curl -sSL --retry 5 https://github.com/pivotal-energy-solutions/rc-files/raw/master/bin/get-infrastructure.sh | sh -s -- -c beta

if ! [ -x "$(command -v sudo)" ]; then
    echo 'Error: sudo is not installed.' >&2
    exit 1
fi

_MISSING_KEYS=0
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$EC2_REGION" ]; then
  echo ""
  echo  "Error:  One or more of the following environment variables is not set: "
  echo -n "   \$AWS_ACCESS_KEY_ID ($AWS_ACCESS_KEY_ID), "
  echo -n "\$AWS_SECRET_ACCESS_KEY ($AWS_SECRET_ACCESS_KEY), and or"
  echo -n "\$EC2_REGION ($EC2_REGION)."
  _MISSING_KEYS=1
fi

# This is how pulling from a private github repo (using git+ssh) is enabled.
_MISSING_AUTH_SOCK=0
if [ -z "${SSH_AUTH_SOCK}" ] ; then
  echo ""
  echo "Error:  No SSH_AUTH_SOCK Found!!"
  _MISSING_AUTH_SOCK=1
fi

if [ $_MISSING_KEYS ] || [ $_MISSING_AUTH_SOCK ]; then
  echo ""
  echo -n "Ensure that ssh config has been set up properly.  You need to ensure that "
  if [ $_MISSING_KEYS ] && [ $_MISSING_AUTH_SOCK ]; then echo -n "both " ; fi
  if [ $_MISSING_KEYS ] ; then
    echo -n "'sendEnv'"
  fi
  if [ $_MISSING_KEYS ] && [ $_MISSING_AUTH_SOCK ]; then echo -n " and " ;fi
  if [ $_MISSING_AUTH_SOCK ] ; then
    echo -n "''ForwardAgent'"
  fi
  echo " is set in your ~/.ssh/config.  To do that create or add to your .ssh/config the following:"
  echo ""
  echo "Host ec2-*"
  if [ $_MISSING_AUTH_SOCK ] ; then echo "  ForwardAgent yes"; fi
  if [ $_MISSING_KEYS ] ; then echo "  sendEnv AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY EC2_REGION"; fi
  echo ""
  exit 255
fi

if ! [ -x "$(command -v python3)" ]; then
    PYTHON_VERSION=3.7.4
    echo '${PYTHON_VERSION} is not installed.' >&2
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
    echo "Git is not Installing"
    sudo yum install -y git
fi

# Update pip and install pipenv and uwsgi
sudo pip3 install -qq --upgrade pip
sudo pip3 install -qq --upgrade pipenv
sudo pip3 install -qq --upgrade uwsgi

# Ensure we are good with github
if ! [ $(id -u) = 0 ]; then
    sudo -HE ssh-keygen -F github.com > /dev/null 2>&1 || \
      sudo -HE ssh-keyscan github.com > $$.ssh 2> /dev/null && \
      sudo mv $$.ssh /root/.ssh/known_hosts > /dev/null 2>&1 && \
      sudo chown root:root /root/.ssh/known_hosts && \
      sudo chmod 640 /root/.ssh/known_hosts
    sudo -HE pip3 install -qq --upgrade --no-cache-dir git+ssh://git@github.com/pivotal-energy-solutions/tensor-infrastructure.git
else
    ssh-keygen -F github.com > /dev/null 2>&1 || ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null
    pip3 install -qq --upgrade --no-cache-dir git+ssh://git@github.com/pivotal-energy-solutions/tensor-infrastructure.git
fi

create_or_update_ami.py "$@"

if [ $? -eq 0 ] ; then
    echo ""
    echo ""
    echo " Install Complete!!"
    echo ""
    echo ""
    read -p "Shall we remove it [Yn]:" ans_yn
    case "$ans_yn" in
        [Yy]) create_or_update_ami.py -r --no-verify $@;;

         *) exit 3;;
    esac
fi