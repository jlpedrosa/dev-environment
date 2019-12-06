#!/bin/bash

function fix_disk {
    
	echo "Arranging data disk"
    umount /dev/sdb1 && echo "Device mounted" || echo "Failed to umount"
    
    dd if=/dev/zero of=/dev/sdb bs=1024 count=8096  && echo "Disk wipped" || echo "Failed to wipe disk"
    
    parted -s /dev/sdb mktable gpt && echo "Created partition table" || echo "Failed to create partition table"
    
    echo "Creating partition"
    parted -s /dev/sdb mkpart primary ext4 0% 100%
    
    partprobe
    
    echo "Formatting disk"
    mkfs.ext4 /dev/sdb1
    
    echo "Mounting disk"
    mount /dev/sdb1
}

function create_links {

    HOME="/home/${real_user}" 
    echo "Creating folders and symlinks for ${real_user} and ${HOME}"
    
    rm -rf ${HOME}/go /var/lib/docker ${HOME}/projects
    
    mkdir /mnt/docker
    mkdir /mnt/go
    mkdir /mnt/projects
    chown ${real_user}:${real_user} /mnt/go /mnt/projects
    
    ln -s /mnt/go ${HOME}/go
    ln -s /mnt/docker /var/lib/docker
    ln -s /mnt/projects ${HOME}/projects
    
    chown -h ${real_user}:${real_user} ${HOME}/go ${HOME}/projects
    
}

function install_go {
    
	apt-get -y install unzip
    filename='go1.13.4.linux-amd64.tar.gz'
    wget "https://dl.google.com/go/${filename}"
    
    tar -C /usr/local -xzf ${filename}
    
    echo 'export GOPATH=$HOME/go' >>  ~/.bash_profile
	echo 'export GOROOT=/usr/local/go' >>  ~/.bash_profile
	echo 'export PATH=$GOPATH/bin:$GOROOT/bin:$PATH' >> ~/.bash_profile
}

function install_terraform {
    filename='terraform_0.12.16_linux_amd64.zip'
    wget "https://releases.hashicorp.com/terraform/0.12.16/${filename}"
    unzip ${filename}
    mv terraform /usr/local/bin
}

function install_az_cli {
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
}

function install_docker_repo {
    
    apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
    
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    
    add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
    stable"
}


function install_docker {
    apt-get -y install docker-ce docker-ce-cli containerd.io
}

function install_systools {
    apt-get -y install iftop iotop sysstat
}

function install_chrome {
    apt-get -y install fonts-liberation  libappindicator3-1 libasound2 libatk-bridge2.0-0 libatspi2.0-0 libgtk-3-0 libnspr4 libnss3 libx11-xcb1 xdg-utils libxss1
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    dpkg -i google-chrome*.deb
}

function install_all {
    
    apt-get update -y
    install_docker_repo
    apt-get update -y
    install_systools
    install_docker
    install_go
    install_terraform
    install_az_cli
    install_chrome
}

set -e

if [ "$1" != "" ]; then
    real_user="$1"
else
    echo "The script must be invoked with the username as first argument"
	exit 1
fi


fix_disk
create_links
install_all