#!/bin/bash
# This script will bootstrap Ubuntu with DevOps related tools

###############################################################################
# Customize the script by passing values to the named parameters below, e.g.
# ./bootstrap-ubuntu-devops.sh --kubectl 1.20.2
nodejs=${nodejs:-16}
kubectl=${kubectl:-1.26.5}
terragrunt=${terragrunt:-0.50.0}
packer=${packer:-1.9.2}
vault=${vault:-1.14.1}
keygen=${keygen:-true}
java=${java:-11}

while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
    # echo $1 $2 # Optional to see the parameter:value result
  fi
  shift
done

###############################################################################
echo "Installing general utilities..."
sudo apt-get -y update
sudo apt-get -y install python3 python3-pip python3-virtualenv python3-setuptools git default-jdk unzip build-essential vim nano wget

echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_${nodejs}.x | sudo bash -
sudo apt-get install -y nodejs

echo "Installing Java ${java}..."
sudo apt-get install openjdk-${java}-jdk

echo "Installing Ansible..."
sudo apt-get-add-repository -y ppa:ansible/ansible
sudo apt-get -y update
sudo apt-get -y install ansible

echo "Installing Docker..."
sudo app install docker.io
sudo apt-get -y update
sudo apt-get -y install ansible

echo "Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -f awscliv2.zip
rm -rf ./aws

echo "Installing kubectl ${kubectl}..."
sudo apt-get -y update
sudo apt-get -y install apt-transport-https gnupg2
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
if grep -Fxq "deb https://apt.kubernetes.io/ kubernetes-xenial main" /etc/apt/sources.list.d/kubernetes.list
then
  echo "Not adding kubectl repo because it is already present"
else
  echo "Adding kubectl repo..."
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
fi
sudo apt-get update -y
sudo apt-get install -y kubectl=${kubectl}*


echo "Installing eksctl ${eksctl}..."
# for ARM systems, set ARCH to: `arm64`, `armv6` or `armv7`
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"

# (Optional) Verify checksum
curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check

tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz

sudo mv /tmp/eksctl /usr/local/bin



echo "Installing the latest Helm..."
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm ./get_helm.sh

echo "Installing k9s..."
curl -sS https://webinstall.dev/k9s | bash

echo "Installing Terraform..."
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update -y && sudo apt install terraform -y

echo "Installing Terragrunt ${terragrunt}..."
curl -o terragrunt -L https://github.com/gruntwork-io/terragrunt/releases/download/v${terragrunt}/terragrunt_linux_amd64
sudo chmod +x terragrunt
sudo mv terragrunt /usr/local/bin/terragrunt

echo "Installing Packer ${packer}..."
curl -o packer.zip https://releases.hashicorp.com/packer/${packer}/packer_${packer}_linux_amd64.zip
unzip packer.zip
sudo mv packer /usr/local/bin/packer
rm packer.zip

echo "Installing Vault ${vault}..."
curl -o vault.zip https://releases.hashicorp.com/vault/${vault}/vault_${vault}_linux_amd64.zip
unzip vault.zip
sudo mv vault /usr/local/bin/vault
rm vault.zip

echo "Installing Postman..."
sudo snap install postman

echo "Cleaning up after bootstrapping..."
sudo apt-get -y update
sudo apt-get -y autoremove
sudo apt-get -y clean

if [ $keygen = true ] ; then
  echo "Checking if ssh key already exists..."
  if [ ! -f ~/.ssh/id_rsa ] ; then
    echo "Generating a new SSH key..."
    ssh-keygen -q -t rsa -b 4096 -N "" -C "$(whoami)@$(hostname) on $(cat /etc/os-release)" -f ~/.ssh/id_rsa <<<y 2>&1 >/dev/null
  else
    echo "Key already exists"
  fi
fi