#! /bin/bash
#
# Provisioning script for OpsLinux "Debian GUI VM"

#------------------------------------------------------------------------------
# Bash settings
#------------------------------------------------------------------------------

# Enable "Bash strict mode"
set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # do not mask errors in piped commands

#------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------

# Location of provisioning scripts and files
export readonly PROVISIONING_SCRIPTS="/vagrant/provisioning/"
# Location of files to be copied to this server
export readonly PROVISIONING_FILES="${PROVISIONING_SCRIPTS}/files/${HOSTNAME}"

#------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------
# TODO: put all variable definitions here. Tip: make them readonly if possible.
readonly vm_user=hogent
readonly vm_pass=hogent25
# Establish the VMs CPU architecture
readonly cpu_arch=$( uname -r | cut -d- -f2 )
readonly vbox_version="7.2.2"

#------------------------------------------------------------------------------
# "Imports" - not used as common is for AlmaLinux systems (using dnf)
#------------------------------------------------------------------------------

# Actions/settings common to all servers
#source ${PROVISIONING_SCRIPTS}/common.sh

#------------------------------------------------------------------------------
# Helper functions - imported from common.sh
#------------------------------------------------------------------------------
# Three levels of logging are provided: log (for messages you always want to
# see), debug (for debug output that you only want to see if specified), and
# error (obviously, for error messages).

# Set to 'yes' if debug messages should be printed.
readonly debug_output='no'

# Usage: log [ARG]...
#
# Prints all arguments on the standard error stream
log() {
  printf '\e[0;33m[LOG]  %s\e[0m\n' "${*}"
}

# Usage: debug [ARG]...
#
# Prints all arguments on the standard error stream
debug() {
  if [ "${debug_output}" = 'yes' ]; then
    printf '\e[0;36m[DBG] %s\e[0m\n' "${*}"
  fi
}

# Usage: error [ARG]...
#
# Prints all arguments on the standard error stream
error() {
  printf '\e[0;31m[ERR] %s\e[0m\n' "${*}" 1>&2
}


#------------------------------------------------------------------------------
# Provision server
#------------------------------------------------------------------------------

log "Starting server specific provisioning tasks on ${HOSTNAME}"

log "Set a fixed kernel version"
# de kernel blijft vast op 6.12.38-1; geen kernel upgrades tijdens de lessen
apt-get -y purge linux-image-"${cpu_arch}"

log "Upgrade to latest apt" 
apt-get update
apt-get -y upgrade

log "Installing the MATE desktop env - without libreoffice/gimp"
apt-get -y install task-mate-desktop lightdm lightdm-gtk-greeter
apt-get -y purge libreoffice-common gimp

log "Remove some services - basically cleaning up TCP sockets"
apt-get -y purge rpcbind
apt-get -y purge cups cups-common
apt-get -y autoremove

log "Set the default desktop resolution"
grep 1920x1080 /etc/lightdm/lightdm.conf || \
sed -i '/^\[Seat:.*/a display-setup-script=sh -c -- "xrandr -s 1600x900"' \
	/etc/lightdm/lightdm.conf
systemctl restart lightdm

log "Adding a default user ${vm_user}"
apt-get -y install whois # mkpasswd is in this package
id -u "${vm_user}" &> /dev/null || useradd -m -g users -p $( mkpasswd -m sha-512 "${vm_pass}" ) -s /bin/bash "${vm_user}"
usermod -aG sudo "${vm_user}"

log "Preparing VBox Guest Additions install"
# the guest additions iso in in the non-free repo
echo 'deb http://httpredir.debian.org/debian/ trixie non-free' > /etc/apt/sources.list.d/vboxiso.list
apt-get update
apt-get -y install virtualbox-guest-additions-iso
apt-get -y install build-essential dkms linux-headers-$(uname -r)
# A dirty trick replacement to get the latest version, as Debian13 and VBox 7.2.2 are not alligned yet
wget -O /usr/share/virtualbox/VBoxGuestAdditions.iso https://download.virtualbox.org/virtualbox/"${vbox_version}"/VBoxGuestAdditions_"${vbox_version}".iso -o /root/wget.log
rm /root/wget.log

# Cleanup
apt clean

#log "Compiling VBox Guest Additions"
mountpoint -q /media/cdrom && umount /media/cdrom
mount -t iso9660 -o ro /usr/share/virtualbox/VBoxGuestAdditions.iso /media/cdrom
#/usr/sbin/VBoxService -V
[ "${cpu_arch}" == "amd64" ] && sh /media/cdrom/VBoxLinuxAdditions.run --nox11
[ "${cpu_arch}" == "arm64" ] && sh /media/cdrom/VBoxLinuxAdditions-arm64.run --nox11
# gives an exit code 2 on arm, no idea why
umount /media/cdrom
/usr/sbin/VBoxService -V

### Cleanup of the VM - Manual steps

##log "Compressing the VDI"
#cat /dev/zero > zero.fill; sync; sleep 1; sync; rm -f zero.fill

## Steps to compress the image afterwards
#VBoxManage clonehd debian-13.0-aarch64-disk001.vmdk debian-13.0-aarch64-disk001.vdi --format vdi
#VBoxManage modifyhd debian-13.0-aarch64-disk001.vdi --compact
#rm debian-13.0-aarch64-disk001.vmdk
#VBoxManage showvminfo linux_LinuxGUI_1761208634669_68109 | grep v1208634669_68109 --storagectl='VirtIO Controller' --port 0 --device 0 --medium debian-13.0-aarch64-disk001.vdi

