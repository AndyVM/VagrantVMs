#! /bin/bash
#
# Provisioning script for virtual router / CN1 providing ...
# * a router via NAT of the host
# * a DHCP server to be bridged to a Cisco switch

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

# Set to 'yes' if debug messages should be printed.
readonly debug_output='yes'

#------------------------------------------------------------------------------
# Helper functions
#------------------------------------------------------------------------------
# Three levels of logging are provided: log (for messages you always want to
# see), debug (for debug output that you only want to see if specified), and
# error (obviously, for error messages).

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

log "Installing and enabling DNSmasq / network 3.0/24"
apt update
apt -y install dnsmasq tcpdump
#cp /vagrant/provisioning/cn1rout/dhcp-eth1.conf /etc/dnsmasq.d/dhcp-eth1.conf
cat << _EOF_ > /etc/dnsmasq.d/dhcp-eth1.conf
interface=eth1
dhcp-range=192.168.3.10,192.168.3.99,255.255.255.0,1h
dhcp-option=option:router,192.168.3.254
dhcp-option=option:dns-server,1.1.1.1
dhcp-authoritative
### Add your MAC address to this list!
#MAC Windows Laptop AVMaele
dhcp-host=A4:4C:C8:49:49:C8,ignore
_EOF_
systemctl enable dnsmasq
systemctl restart dnsmasq

log "enable routing"
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/98-IPv4routing.conf
service procps force-reload

log "set-up NAT"
#cp /vagrant/provisioning/cn1rout/nftables.conf /etc/nftables.conf
cat << _EOF_ > /etc/nftables.conf
#!/usr/sbin/nft -f

flush ruleset

table ip nat {
        chain postrouting {
                type nat hook postrouting priority 100; policy accept;
                ip saddr 192.168.3.0/24 oif eth0 snat 10.0.2.15
        }
}
_EOF_
sudo systemctl restart nftables
