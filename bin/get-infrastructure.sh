#!/usr/bin/env bash

# This will pull the infrastructure module and install it
# curl -sSL --retry 5 https://github.com/pivotal-energy-solutions/rc-files/raw/master/bin/get-infrastructure.sh | sh -s -- -a axis -c production -vvv

if ! [ -x "$(command -v sudo)" ]; then
    echo 'Error: sudo is not installed.' >&2
    exit 1
fi

# We need to make sure that we allow these couple keys to be passed to our host.
_SSHD_INCORRECT=0
sudo grep -P '^AcceptEnv\s+(?=.*AWS_ACCESS_KEY_ID)(?=.*AWS_SECRET_ACCESS_KEY)(?=.*EC2_REGION)' /etc/ssh/sshd_config > /dev/null
if [ $? != 0 ] ; then
  _SSHD_INCORRECT=1
  echo ""
  echo "Warning: SSHD is not accepting of SendEnv Keys - Fixing"
  echo "" | sudo tee -a /etc/ssh/sshd_config > /dev/null
  echo "AcceptEnv AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY EC2_REGION" | sudo tee -a /etc/ssh/sshd_config > /dev/null
  sudo systemctl restart sshd
  echo "  Corrected.  A re-login will be required"
fi

# Make sure the banner is working..
sudo grep -P '^Banner\s+(?=/etc/issue.net)' /etc/ssh/sshd_config > /dev/null
if [ $? != 0 ] ; then
  echo ""
  echo "Warning: SSHD Banner Not correct - Fixing"
  echo "" | sudo tee -a /etc/ssh/sshd_config > /dev/null
  echo "Banner /etc/issue.net" | sudo tee -a /etc/ssh/sshd_config > /dev/null
  sudo systemctl restart sshd
fi


_MISSING_KEYS=0
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$EC2_REGION" ]; then
  echo ""
  if [ $_SSHD_INCORRECT = 1 ] ; then echo -n "Warning: "; else echo -n "Error: "; fi
  echo -n "One or more of the following environment variables "
  if [ $_SSHD_INCORRECT = 1 ] ; then echo "was not accepted."; else echo "was not passed in."; fi
  echo -n "   AWS_ACCESS_KEY_ID [$AWS_ACCESS_KEY_ID], "
  echo -n "AWS_SECRET_ACCESS_KEY [$AWS_SECRET_ACCESS_KEY], and or "
  echo "EC2_REGION [$EC2_REGION]."
  if [ $_SSHD_INCORRECT = 1 ] ; then
    echo "Ensure they are setup passed in and re-relogin"
  fi
  _MISSING_KEYS=1
fi

# This is how pulling from a private github repo (using git+ssh) is enabled.
_MISSING_AUTH_SOCK=0
if [ -z "${SSH_AUTH_SOCK}" ] ; then
  echo ""
  echo "Error:  No SSH_AUTH_SOCK Found!!"
  _MISSING_AUTH_SOCK=1
fi

if [ $_MISSING_KEYS = 1 ] || [ $_MISSING_AUTH_SOCK = 1 ]; then
  echo ""
  echo -n "You must ensure that "
  if [ $_MISSING_KEYS = 1 ] && [ $_MISSING_AUTH_SOCK = 1 ]; then echo -n "both " ; fi
  if [ $_MISSING_KEYS = 1 ] ; then
    echo -n "'sendEnv'"
  fi
  if [ $_MISSING_KEYS = 1 ] && [ $_MISSING_AUTH_SOCK = 1 ]; then echo -n " and " ;fi
  if [ $_MISSING_AUTH_SOCK = 1 ] ; then
    echo -n "''ForwardAgent'"
  fi
  echo " is set in your ~/.ssh/config.  To do that create or add to your .ssh/config the following:"
  echo ""
  echo "Host ec2-*"
  if [ $_MISSING_AUTH_SOCK = 1 ] ; then echo "  ForwardAgent yes"; fi
  if [ $_MISSING_KEYS = 1 ] ; then echo "  sendEnv AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY EC2_REGION"; fi
  echo ""
  if [ $_MISSING_KEYS = 1 ] ; then echo "Finally put the environment vars in your .env"; fi
  echo ""
  exit 255
fi

PYTHON_VERSION=3.7.7
PYTHON_BASE_VERSION=`echo ${PYTHON_VERSION} | cut -d "." -f 1-2`
if ! [ -x "$(command -v python${PYTHON_BASE_VERSION})" ]; then
    echo "Python ${PYTHON_VERSION} is not installed."
    sudo yum groups mark install "Development Tools"
    sudo yum -y groupinstall "Development Tools"
    sudo yum -y install openssl-libs openssl-devel bzip2-devel zlib zlib-devel libffi-devel wget git nmap-ncat which
    # Build up Python $PYTHON_VERSION
    cd /usr/src || echo "Unable to cd to /usr/src"
    sudo wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
    sudo tar xzf Python-${PYTHON_VERSION}.tgz
    cd /usr/src/Python-${PYTHON_VERSION}  || echo "Unable to cd to /usr/src/Python-${PYTHON_VERSION}"
    sudo ./configure --enable-optimizations
    sudo make install
    cd /usr/src || echo "Unable to cd to /usr/src"
    sudo rm -rf /usr/src/Python-${PYTHON_VERSION}
    sudo rm /usr/src/Python-${PYTHON_VERSION}.tgz

    # Build up Python PYTHON_BASE_VERSION Links so it's easy to find it
    sudo ln -s /usr/local/bin/python${PYTHON_BASE_VERSION} /usr/bin/python${PYTHON_BASE_VERSION}
    sudo ln -s /usr/local/bin/python${PYTHON_BASE_VERSION} /usr/bin/python3
    sudo ln -s /usr/local/bin/pip${PYTHON_BASE_VERSION} /usr/bin/pip${PYTHON_BASE_VERSION}
    sudo ln -s /usr/local/bin/pip3 /usr/bin/pip3
    sudo ln -s /usr/local/bin/easy_install-${PYTHON_BASE_VERSION} /usr/bin/easy_install-${PYTHON_BASE_VERSION}
    sudo ln -s /usr/local/bin/easy_install-${PYTHON_BASE_VERSION} /usr/bin/easy_install-3
fi

if ! [ -x "$(command -v git)" ]; then
    echo "Git is not Installing"
    sudo yum install -y git
fi

# Update pip and install pipenv and uwsgi
sudo pip3 install -qq --upgrade pip
sudo pip3 install -qq --upgrade virtualenv
sudo pip3 install -qq --upgrade poetry
sudo pip3 install -qq --upgrade uwsgi

# Ensure we are good with github
if ! [ $(id -u) = 0 ]; then
    sudo -HE ssh-keygen -F github.com > /dev/null 2>&1 || \
      ssh-keyscan github.com 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null && \
      sudo chown root:root /root/.ssh/known_hosts && \
      sudo chmod 640 /root/.ssh/known_hosts
    sudo -HE pip3 install -qq --upgrade --no-cache-dir git+ssh://git@github.com/pivotal-energy-solutions/tensor-infrastructure.git || (c=$?; echo "Issue updating infrastructure"; (exit $c))
    if ! [ -f /root/.env ]; then
      sudo touch /root/.env
    fi
else
    ssh-keygen -F github.com > /dev/null 2>&1 || ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null
    pip3 install -qq --upgrade --no-cache-dir git+ssh://git@github.com/pivotal-energy-solutions/tensor-infrastructure.git || (c=$?; echo "Issue updating infrastructure"; (exit $c))
    if ! [ -f ~/.env ]; then
      touch ~/.env
    fi
fi

sudo touch /usr/local/lib/python${PYTHON_BASE_VERSION}/site-packages/infrastructure/utils/logging_utils/.env

echo "Starting Create or Update AMI"
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
else
  echo "This FALILED!! -- NOT GOOD!"
fi