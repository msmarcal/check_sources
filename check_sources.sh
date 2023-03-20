#!/usr/bin/env bash
#       _               _
#   ___| |__   ___  ___| | __    ___  ___  _   _ _ __ ___ ___  ___
#  / __| '_ \ / _ \/ __| |/ /   / __|/ _ \| | | | '__/ __/ _ \/ __|
# | (__| | | |  __/ (__|   <    \__ \ (_) | |_| | | | (_|  __/\__ \
#  \___|_| |_|\___|\___|_|\_\___|___/\___/ \__,_|_|  \___\___||___/
#                          |_____|
#
# Checks Canonical package repositories and any third party resources required
# by inrastructure deployment
#
# Usage:
#   check_sources.sh [proxy URL]
#
# Depends on:
#  curl
#

###############################################################################
# Strict Mode
###############################################################################

# Treat unset variables and parameters other than the special parameters ‘@’ or
# ‘*’ as an error when performing parameter expansion. An 'unbound variable'
# error message will be written to the standard error, and a non-interactive
# shell will exit.
#
# Short form: set -u
set -o nounset

# Short form: set -e
set -o errexit

# Allow the above trap be inherited by all functions in the script.
#
# Short form: set -E
set -o errtrace

# Return value of a pipeline is the value of the last (rightmost) command to
# exit with a non-zero status, or zero if all commands in the pipeline exit
# successfully.
set -o pipefail

# Set $IFS to only newline and tab.
#
IFS=$'\n\t'

###############################################################################
# Environment
###############################################################################

# $_ME
#
# Set to the program's basename.
_ME=$(basename "${0}")

# Color definition
_GREEN='\033[0;32m'
_RED='\e[31m'
_RESET='\033[0m'

# List of resources
# shellcheck disable=SC2034
_HTTP=(
ubuntu-cloud.archive.canonical.com
nova.cloud.archive.ubuntu.com
cloud.archive.ubuntu.com
nova.clouds.archive.ubuntu.com
clouds.archive.ubuntu.com
cloud-images.ubuntu.com
keyserver.ubuntu.com
archive.ubuntu.com
security.ubuntu.com
usn.ubuntu.com
launchpad.net
api.launchpad.net
ppa.launchpad.net
ppa.launchpadcontent.net
jujucharms.com
jaas.ai
charmhub.io
api.charmhub.io
streams.canonical.com
public.apps.ubuntu.com
images.maas.io
)

# shellcheck disable=SC2034
_HTTPS=(
ubuntu-cloud.archive.canonical.com
nova.cloud.archive.ubuntu.com
cloud.archive.ubuntu.com
nova.clouds.archive.ubuntu.com
clouds.archive.ubuntu.com
cloud-images.ubuntu.com
keyserver.ubuntu.com
contracts.canonical.com
archive.ubuntu.com
security.ubuntu.com
usn.ubuntu.com
launchpad.net
api.launchpad.net
ppa.launchpad.net
ppa.launchpadcontent.net
jujucharms.com
jaas.ai
charmhub.io
api.charmhub.io
entropy.ubuntu.com
streams.canonical.com
public.apps.ubuntu.com
https://login.ubuntu.com
images.maas.io
api.jujucharms.com
api.snapcraft.io
landscape.canonical.com
livepatch.canonical.com
dashboard.snapcraft.io
)

###############################################################################
# Help
###############################################################################

# _print_help()
#
# Print the program help information.
function _print_help() {
  cat <<HEREDOC
      _               _
  ___| |__   ___  ___| | __    ___  ___  _   _ _ __ ___ ___  ___
 / __| '_ \\ / _ \\/ __| |/ /   / __|/ _ \\| | | | '__/ __/ _ \\/ __|
| (__| | | |  __/ (__|   <    \\__ \\ (_) | |_| | | | (_|  __/\\__ \\
 \\___|_| |_|\\___|\\___|_|\\_\\___|___/\\___/ \\__,_|_|  \\___\\___||___/
                         |_____|

Checks access to Canonical package repositories as well any third party
resources required by (PCB|K8s) infrastructure deployment

Usage:
  ${_ME} [proxy URL]
  ${_ME} -h | --help

Options:
  -h --help  Show this screen.
HEREDOC
}

###############################################################################
# Program Functions
###############################################################################

# _set_proxy()
#
# Description:
#  Export http{,s} variables
function _set_proxy() {
   export http_proxy="${1}"
   export https_proxy=$http_proxy
}

# _ok()
#
# Description:
#  Print green status code
function _ok() {
    printf "${_GREEN}[%s] %s${_RESET}\\n" "${1}" "OK"
}

# Description:
#  Print red status code
function _err() {
    printf "${_RED}[%s] %s${_RESET}\\n" "${1}" "ERR"
}

# Description:
#  Check http{,s} connection to the _HTTP and _HTTPS server arrays
function _check_http() {
  _PROTO=$(echo "$1" | tr "[:lower:]" "[:upper:]")
  printf "\\n[ Checking %s sources ]--------------------------------------\\n" \
     "${_PROTO}"
  _SOURCES="_${_PROTO}[@]"

  for _SOURCE in "${!_SOURCES}"; do
     printf "%s: %s - " "${1}" "${_SOURCE}"
     _RET=$( \
        curl -s -m 5 -o /dev/null \
        -w "%{http_code}" -I --insecure "$1"://"${_SOURCE}" || echo $?)

     # Print OK if the server replies with 2xx, 3xx or 4xx HTTP status codes
     if [[ "${_RET}" =~ ^2.*|^3.*|^4.* ]]
     then
        _ok "${_RET}"
     else
        _err "${_RET}"
     fi
  done
}


###############################################################################
# Main
###############################################################################

# _main()
#
# Description:
#   Entry point for the program, handling basic option parsing and dispatching.
function _main() {
  # Avoid complex option parsing when only one program option is expected.
  if [[ "${1:-}" =~ ^-h|--help$  ]]
  then
    _print_help
  else
     if [[ -n "${1:-}" ]]
     then 
        if [[ "${1}" =~ ^https?:\/\/.+:? ]]
        then
           printf "\\nChecking sources against %s proxy.\\n" "${1}"
           _set_proxy "${1}"
        else
           printf "\\nERROR: Invalid proxy URL: %s\\n" "${1}"
           _print_help
           exit 1
        fi
     fi
     _check_http "http"
     _check_http "https"
  fi
}

# Call `_main` after everything has been defined.
_main "$@"
