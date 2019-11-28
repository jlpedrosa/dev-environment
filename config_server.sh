#!/bin/bash

function fix_disk {
	
	umount /dev/sdb1 && echo "Devide umounted" || echo "Failed to umount"

	dd if=/dev/zero of=/dev/sdb bs=1024 count=4096  && echo "Disk wipped" || echo "Failed to wipe disk"

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

	real_user=`logname`
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
	echo "go installed"
	echo 'export GOPATH=$HOME/go' >>  ~/.bash_profile
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
	apt -y install iftop iotop sysstat
}

function install_all {

	apt-get update
	#install_docker_repo

	apt-get update
	
	install_systools
	install_docker
	install_go
}

set -e 
 
#fix_disk
#create_links

install_all


