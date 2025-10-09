#! /bin/bash
#
# Provisioning script for generic AlmaLinux server | OpsLinux

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
readonly PROVISIONING_SCRIPTS="/vagrant/provisioning/"
# Location of files to be copied to this server
readonly PROVISIONING_FILES="${PROVISIONING_SCRIPTS}/files/${HOSTNAME}"

export PROVISIONING_FILES PROVISIONING_SCRIPTS

# Settings for this host
nic=enp0s8
ip='192.168.76.254'
netmask='24'

#------------------------------------------------------------------------------
# "Imports"
#------------------------------------------------------------------------------

# Actions/settings common to all servers
source ${PROVISIONING_SCRIPTS}/common.sh

#------------------------------------------------------------------------------
# Provision server
#------------------------------------------------------------------------------

log "Starting server specific provisioning tasks on ${HOSTNAME}"

log "Cleanup software rpc / cockpit"
dnf -y remove rpcbind cockpit cockpit-ws

log "Set the EPEL release"
dnf -y install epel-release


log "DNF cleanup"
dnf -y clean dbcache
dnf -y clean all

#log "Configuring network interface"
#
## Check if the connection already exists
#if ! nmcli -f NAME connection show | grep -q "${nic}"; then
#  debug "❎ No connection for ${nic}, creating"
#  nmcli connection add \
#    type ethernet \
#    connection.id "${nic}" \
#    connection.interface-name "${nic}" \
#    ipv4.method manual \
#    ipv4.addresses "${ip}/${netmask}" \
#    ipv4.gateway ""
#
#  # allow interface to settle
#  sleep 1 
#else
#  debug "✅ Connection for ${nic} exists"
#fi
#
## Check if the interface has the correct IP address
#if ! ip -br -4 address show dev "${nic}" | grep -F -q "${ip}/${netmask}"; then
#  debug "❎ Bad IP address detected, fixing: $(ip -br -4 address show dev ${nic})"
#  nmcli connection modify "${nic}" \
#    ipv4.method manual \
#    ipv4.addresses "${ip}/${netmask}" \
#    ipv4.gateway ""
#  nmcli connection up "${nic}"
#else
#  debug "✅ Interface has correct IP address"
#fi

log "Network settings overview:"

ip -br address

log "Routing table"

ip route

log "DNS server(s)"

grep '^nameserver' /etc/resolv.conf

if systemctl is-active --quiet systemd-resolved; then
  resolvectl dns
fi
