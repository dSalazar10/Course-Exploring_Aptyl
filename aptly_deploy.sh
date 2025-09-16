#!/bin/bash
# This script sets up a local Ubuntu mirror using aptly on a fresh server.

# 1. Update package lists and install GnuPG
#    GnuPG is required to securely add the aptly repository key.
echo "--- Updating package lists and installing GnuPG ---"
sudo apt update
sudo apt install -y gnupg

# 2. Add the aptly repository signing key
#    This key is used to verify the authenticity of the aptly packages.
echo "--- Adding aptly repository key ---"
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/aptly.gpg --keyserver-options http-proxy=$http_proxy --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 9E3E53F19C7DE460

# 3. Add the aptly repository to APT sources
echo "--- Adding aptly to APT sources ---"
echo "deb [signed-by=/usr/share/keyrings/aptly.gpg] https://repo.aptly.info/ stable main" | sudo tee /etc/apt/sources.list.d/aptly.list

# 4. Install aptly and the Nginx web server
echo "--- Installing aptly and Nginx ---"
sudo apt update
sudo apt install -y aptly nginx

# 5. Create mirrors for noble, updates, and security
echo "--- Creating aptly mirrors for Noble ---"
aptly mirror create -architectures=amd64 noble-main-universe http://archive.ubuntu.com/ubuntu/ noble main universe
aptly mirror create -architectures=amd64 noble-updates-main-universe http://archive.ubuntu.com/ubuntu/ noble-updates main universe
aptly mirror create -architectures=amd64 noble-security-main-universe http://security.ubuntu.com/ubuntu/ noble-security main universe

# 6. Download packages for all mirrors (this will take a long time)
echo "--- Updating mirrors (downloading packages) ---"
aptly mirror update noble-main-universe
aptly mirror update noble-updates-main-universe
aptly mirror update noble-security-main-universe

# 7. Create timestamped snapshots from the mirrors
echo "--- Creating snapshots ---"
TIMESTAMP=$(date +%Y%m%d-%H%M)
aptly snapshot create noble-main-$TIMESTAMP from mirror noble-main-universe
aptly snapshot create noble-updates-$TIMESTAMP from mirror noble-updates-main-universe
aptly snapshot create noble-security-$TIMESTAMP from mirror noble-security-main-universe

# 8. Merge all snapshots into a single, final snapshot
echo "--- Merging snapshots ---"
aptly snapshot merge -latest noble-complete-$TIMESTAMP noble-main-$TIMESTAMP noble-updates-$TIMESTAMP noble-security-$TIMESTAMP

# 9. Publish the final snapshot to be served
echo "--- Publishing final snapshot ---"
aptly publish snapshot -distribution="noble" noble-complete-$TIMESTAMP

# 10. Link the published repository to the Nginx web root
echo "--- Linking repository to web server ---"
# Remove old link if it exists to prevent errors on re-run
sudo rm -f /var/www/html/aptly
sudo ln -s ~/.aptly/public /var/www/html/aptly

echo "✅ Repository setup complete!"
echo "Your repository is now available at http://<your-mirror-server-ip>/aptly"
