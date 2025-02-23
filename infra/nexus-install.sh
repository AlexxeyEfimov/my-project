#!/bin/bash

# Sonatype Nexus Installation Script
# Author: [Your Name]

# Variables
NEXUS_VERSION="3.58.1-02"  # Specify the desired Nexus version
NEXUS_TAR="nexus-${NEXUS_VERSION}-unix.tar.gz"
NEXUS_URL="https://download.sonatype.com/nexus/3/${NEXUS_TAR}"
NEXUS_HOME="/opt/nexus"
NEXUS_USER="nexus"
JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"  # Ensure this path is correct

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script as root."
  exit 1
fi

# Check if Java is installed
echo "Checking Java installation..."
if ! command -v java &> /dev/null; then
  echo "Java is not installed. Installing OpenJDK 11..."
  apt update
  apt install -y openjdk-11-jdk
else
  echo "Java is already installed."
fi

# Verify Java version
JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
if [[ "$JAVA_VERSION" < "11" ]]; then
  echo "Java version is too old. Please install Java 11 or higher."
  exit 1
else
  echo "Java version is compatible: $JAVA_VERSION"
fi

# Set JAVA_HOME if not already set
if [ -z "$JAVA_HOME" ]; then
  echo "Setting JAVA_HOME..."
  export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")
  echo "JAVA_HOME set to: $JAVA_HOME"
fi

# Create nexus user
echo "Creating ${NEXUS_USER} user..."
useradd -M -s /bin/false ${NEXUS_USER}

# Download and extract Nexus
echo "Downloading Nexus..."
wget ${NEXUS_URL} -P /tmp
if [ $? -ne 0 ]; then
  echo "Failed to download Nexus. Please check the URL or your internet connection."
  exit 1
fi

echo "Extracting Nexus..."
tar -xvzf /tmp/${NEXUS_TAR} -C /opt
mv /opt/nexus-${NEXUS_VERSION} ${NEXUS_HOME}

# Set permissions
echo "Setting permissions..."
chown -R ${NEXUS_USER}:${NEXUS_USER} ${NEXUS_HOME}
chown -R ${NEXUS_USER}:${NEXUS_USER} ${NEXUS_HOME}/../sonatype-work

# Configure nexus.rc
echo "Configuring nexus.rc..."
echo "run_as_user=${NEXUS_USER}" > ${NEXUS_HOME}/bin/nexus.rc

# Configure nexus.vmoptions
echo "Configuring nexus.vmoptions..."
cat > ${NEXUS_HOME}/bin/nexus.vmoptions <<EOL
-Xms2703m
-Xmx2703m
-XX:MaxDirectMemorySize=2703m
-Djava.util.prefs.userRoot=/opt/sonatype-work/nexus3
-Djava.home=${JAVA_HOME}
EOL

# Create systemd service
echo "Creating systemd service..."
cat > /etc/systemd/system/nexus.service <<EOL
[Unit]
Description=Nexus Service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=${NEXUS_USER}
Group=${NEXUS_USER}
ExecStart=${NEXUS_HOME}/bin/nexus start
ExecStop=${NEXUS_HOME}/bin/nexus stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd and start Nexus
echo "Starting Nexus..."
systemctl daemon-reload
systemctl enable nexus
systemctl start nexus

# Check status
echo "Checking Nexus status..."
systemctl status nexus

# Output information
echo "Installation complete!"
echo "Nexus is available at: http://<VM_IP>:8081"
echo "Admin password can be found here: ${NEXUS_HOME}/sonatype-work/nexus3/admin.password"