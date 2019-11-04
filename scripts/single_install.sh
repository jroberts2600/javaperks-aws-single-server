#!/bin/bash

echo "Pre-installation tasks..."

# 
# Install OS updates
# 
echo 'libc6 libraries/restart-without-asking boolean true' | sudo debconf-set-selections
export DEBIAN_FRONTEND=noninteractive
echo "...installing Ubuntu updates"
sudo apt-get -y update > /dev/null 2>&1
sudo apt-get -y upgrade > /dev/null 2>&1

# 
# Install required packages for:
#   * basic utilities (unzip, jq, git)
#   * Python 3 & Pip
#   * DNSMasq
#   * MySQL Client
#   * NodeJS
#   * Docker
#   * Java
#   * Maven
#   * Nginx
# 
echo "...installing system packages"
sudo apt-get install -y \
    unzip \
    git \
    jq \
    python3 \
    python3-pip \
    python3-dev \
    dnsmasq \
    mysql-client \
    default-libmysqlclient-dev \
    npm \
    docker.io \
    openjdk-11-jre \
    openjdk-11-jdk \
    maven \
    mysql-client-core-5.7 \
    nginx \
    ldap-utils > /dev/null 2>&1

# 
# Install Python libraries:
#   * AWS SDK (boto)
#   * MySQL
#   * Vault
# 
echo "...installing python libraries"
pip3 install botocore
pip3 install boto3
pip3 install mysqlclient
pip3 install awscli
pip3 install hvac

# 
# Create directories we'll need for all our software
# 
echo "...creating directories"
mkdir -p /root/.aws
mkdir -p /root/go
mkdir -p /root/ldap
mkdir -p /etc/vault.d
mkdir -p /etc/consul.d/server
mkdir -p /etc/consul.d/template
mkdir -p /etc/nomad.d
mkdir -p /etc/docker
mkdir -p /opt/vault
mkdir -p /opt/consul
mkdir -p /var/run/consul
mkdir -p /opt/nomad
mkdir -p /opt/nomad/plugins

# 
# Setup AWS credentials file
# 
echo "...setting AWS credentials"
sudo bash -c "cat >/root/.aws/config" << 'EOF'
[default]
aws_access_key_id=${AWS_ACCESS_KEY}
aws_secret_access_key=${AWS_SECRET_KEY}
EOF
sudo bash -c "cat >/root/.aws/credentials" << 'EOF'
[default]
aws_access_key_id=${AWS_ACCESS_KEY}
aws_secret_access_key=${AWS_SECRET_KEY}
EOF

# 
# Reset all environment variables so they 
# can be passed from this script into the 
# next one.
# 
echo "...setting environment variables"
export MYSQL_HOST="${MYSQL_HOST}"
export MYSQL_USER="${MYSQL_USER}"
export MYSQL_PASS="${MYSQL_PASS}"
export MYSQL_DB="${MYSQL_DB}"
export AWS_ACCESS_KEY="${AWS_ACCESS_KEY}"
export AWS_SECRET_KEY="${AWS_SECRET_KEY}"
export AWS_KMS_KEY_ID="${AWS_KMS_KEY_ID}"
export REGION="${REGION}"
export S3_BUCKET="${S3_BUCKET}"
export VAULT_URL="${VAULT_URL}"
export VAULT_LICENSE="${VAULT_LICENSE}"
export CONSUL_URL="${CONSUL_URL}"
export CONSUL_LICENSE="${CONSUL_LICENSE}"
export CONSUL_JOIN_KEY="${CONSUL_JOIN_KEY}"
export CONSUL_JOIN_VALUE="${CONSUL_JOIN_VALUE}"
export CTEMPLATE_URL="${CTEMPLATE_URL}"
export NOMAD_URL="${NOMAD_URL}"
export TABLE_PRODUCT="${TABLE_PRODUCT}"
export TABLE_CART="${TABLE_CART}"
export TABLE_ORDER="${TABLE_ORDER}"
export LDAP_ADMIN_PASS="${LDAP_ADMIN_PASS}"
export LDAP_ADMIN_USER="cn=admin,dc=javaperks,dc=local"
export GOPATH=/root/go
export GOCACHE=/root/go/.cache
export CLIENT_IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`

# 
# Add our hostname to the resolver's host file
# 
echo $CLIENT_IP $(echo "ip-$CLIENT_IP" | sed "s/\./-/g") >> /etc/hosts

# 
# Clone the repo so we can run 
# our actual build script
# 
echo "...cloning repo"
cd /root
git clone --branch "${BRANCH_NAME}" https://github.com/kevincloud/javaperks-aws-single-server.git

# 
# Make our build script runnable
# 
chmod +x /root/javaperks-aws-single-server/scripts/build.sh

echo "Preparation done."

# 
# Run the build script
# 
cd /root/javaperks-aws-single-server/
. ./scripts/build.sh
