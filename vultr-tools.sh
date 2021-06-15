#!/bin/bash

set -eo pipefail

function apt_safe() {
    RES=$(dpkg -i /dev/zero 2>&1 | grep "frontend lock" | wc -l)
	while [ "$RES" -ne 0 ] ;
	do
		echo "Waiting for apt lock"
		sleep 1
		RES=$(dpkg -i /dev/zero 2>&1 | grep "frontend lock" | wc -l)
	done

    apt install -y $@
}

function apt_update_safe() {
    RES=$(dpkg -i /dev/zero 2>&1 | grep "frontend lock" | wc -l)
	while [ "$RES" -ne 0 ] ;
	do
		echo "Waiting for apt lock"
		sleep 1
		RES=$(dpkg -i /dev/zero 2>&1 | grep "frontend lock" | wc -l)
	done

    apt update -y
}

function apt_upgrade_safe() {
    RES=$(dpkg -i /dev/zero 2>&1 | grep "frontend lock" | wc -l)
	while [ "$RES" -ne 0 ] ;
	do
		echo "Waiting for apt lock"
		sleep 1
		RES=$(dpkg -i /dev/zero 2>&1 | grep "frontend lock" | wc -l)
	done

    apt upgrade -y
}

function apt_clean_safe() {
    RES=$(dpkg -i /dev/zero 2>&1 | grep "frontend lock" | wc -l)
	while [ "$RES" -ne 0 ] ;
	do
		echo "Waiting for apt lock"
		sleep 1
		RES=$(dpkg -i /dev/zero 2>&1 | grep "frontend lock" | wc -l)
	done

    apt autoremove -y

    RES=$(dpkg -i /dev/zero 2>&1 | grep "frontend lock" | wc -l)
	while [ "$RES" -ne 0 ] ;
	do
		echo "Waiting for apt lock"
		sleep 1
		RES=$(dpkg -i /dev/zero 2>&1 | grep "frontend lock" | wc -l)
	done

    apt autoclean -y
}

function get_hostname() {
    HOSTNAME=$(curl --fail -s "http://169.254.169.254/latest/meta-data/hostname")
    echo "${HOSTNAME}"
}

function get_root_password() {
    ROOTPW=$(curl -H "Metadata-Token: vultr" --fail -s "http://169.254.169.254/v1/internal/root-password")
    echo "${ROOTPW}"
}

function get_userdata() {
    USERDATA=$(curl --fail -s "http://169.254.169.254/latest/user-data")
    echo "${USERDATA}"
}

function get_sshkeys() {
    KEYS=$(curl --fail -s "http://169.254.169.254/current/ssh-keys")
    echo "${KEYS}"
}

function get_var() {
    local val="$(curl --fail -s  http://169.254.169.254//v1/internal/app-${1} 2>/dev/null)"

	local __result=$1
	eval $__result="'${val}'"
}

function install_cloud_init
{
	if [ -f /etc/redhat-release ]; then
        BUILD="rhel"
		DIST="rpm"
    fi

    if [ "$(grep -c "ID=ubuntu" /etc/os-release)" != "0" ]; then
        BUILD="universal"
		DIST="deb";
    fi

    if [ "$(grep -c "ID=debian" /etc/os-release)" != "0" ]; then
        BUILD="debian10"
		DIST="deb";
    fi

    if [ "${DIST}" == "" ]; then
        echo "Undetected OS, please install from source!"
        exit 255
    fi


	RELEASE=$1

	if [ "${RELEASE}" == "" ]; then
		RELEASE="latest"
	fi

	if [ "${RELEASE}" != "latest" ] && [ "${RELEASE}" != "nightly" ]; then
		echo "${RELEASE} is an invalid release option. Allowed: latest, nightly"
        exit 255
	fi

	if [ "${DIST}" == "rpm" ]; then
		DIST="rpm"
	elif [ "${DIST}" == "deb" ]; then
		DIST="deb";
	fi

	wget https://ewr1.vultrobjects.com/cloud_init_beta/cloud-init_${BUILD}_${RELEASE}.${DIST} -O /tmp/cloud-init_${BUILD}_${RELEASE}.${DIST}

	if [ "${DIST}" == "rpm" ]; then
		yum install -y /tmp/cloud-init_${BUILD}_${RELEASE}.${DIST}
	elif [ "${DIST}" == "deb" ]; then
		apt_safe /tmp/cloud-init_${BUILD}_${RELEASE}.${DIST}
	fi

	rm -f /tmp/cloud-init_${BUILD}_${RELEASE}.${DIST}
}

function clean_system() {

    # Update and clean packages
    if [ -f /etc/redhat-release ]; then
        yum update -y
        yum clean all
    fi

    if [ "$(grep -c "debian" /etc/os-release)" != "0" ]; then
        apt_update_safe
        apt_upgrade_safe
        apt_clean_safe
    fi

    # Ensure temp exists
    mkdir /tmp
    chmod 1777 /tmp

    # Clear temp
    rm -rf /tmp/*
    rm -rf /var/tmp/*

    # Clear keys
    rm -f /root/.ssh/authorized_keys /etc/ssh/*key*
    touch /etc/ssh/revoked_keys
    chmod 600 /etc/ssh/revoked_keys

    # Clear logs
    find /var/log -mtime -1 -type f -exec truncate -s 0 {} \;
    rm -rf /var/log/*.gz
    rm -rf /var/log/*.[0-9]
    rm -rf /var/log/*.log
    rm -rf /var/log/lastlog
    rm -rf /var/log/wtmp

    # Clear old Cloud-Init data
    rm -rf /var/lib/cloud/instances/*

    # Clear history
    history -c
    echo "" > /root/.bash_history

    # Clear mloc
    /usr/bin/updatedb

    # Clear random seed
    rm -f /var/lib/systemd/random-seed

    # Clear machine ID
    rm -f /etc/machine-id
    touch /etc/machine-id

    # Zero empty space
    dd if=/dev/zero of=/zerofile
    sync
    rm -f /zerofile
    sync

    # Trim / if possible
    fstrim /

    # Clean Cloud-init
    cloud-init clean
}