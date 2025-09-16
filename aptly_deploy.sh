sudo gpg --no-default-keyring --keyring /usr/share/keyrings/aptly.gpg --keyserver-options http-proxy=$http_proxy --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 9E3E53F19C7DE460
echo "deb [signed-by=/usr/share/keyrings/aptly.gpg] https://repo.aptly.info/ stable main" | sudo tee /etc/apt/sources.list.d/aptly.list
sudo apt update
sudo apt install aptly nginx

# Create mirrors for noble, updates, and security
aptly mirror create -architectures=amd64 noble-main-universe http://archive.ubuntu.com/ubuntu/ noble main universe
aptly mirror create -architectures=amd64 noble-updates-main-universe http://archive.ubuntu.com/ubuntu/ noble-updates main universe
aptly mirror create -architectures=amd64 noble-security-main-universe http://security.ubuntu.com/ubuntu/ noble-security main universe

# Run the initial download for all mirrors
aptly mirror update noble-main-universe
aptly mirror update noble-updates-main-universe
aptly mirror update noble-security-main-universe

# Create snapshots from the mirrors
aptly snapshot create noble-main-$(date +%Y%m%d) from mirror noble-main-universe
aptly snapshot create noble-updates-$(date +%Y%m%d) from mirror noble-updates-main-universe
aptly snapshot create noble-security-$(date +%Y%m%d) from mirror noble-security-main-universe

# Merge all three snapshots into one
aptly snapshot merge -latest noble-complete-$(date +%Y%m%d) noble-main-$(date +%Y%m%d) noble-updates-$(date +%Y%m%d) noble-security-$(date +%Y%m%d)

# Publish the final snapshot to be served
aptly publish snapshot -distribution="noble" noble-complete-$(date +%Y%m%d)

sudo ln -s ~/.aptly/public /var/www/html/aptly
# Your repository is now available at http://<your-mirror-server-ip>/aptly
