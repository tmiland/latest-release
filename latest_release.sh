#!/usr/bin/env bash
version='1.0.0'
# Repo name
REPO_NAME="tmiland/latest-release"
# Script name
SCRIPT_NAME="Latest Release.sh"
# Set update check
UPDATE_SCRIPT='check'
## Uncomment for debugging purpose
#set -o errexit
#set -o pipefail
#set -o nounset
#set -o xtrace
SCRIPT_FILENAME=$(basename $0)
cd - > /dev/null
sfp=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || greadlink -f "${BASH_SOURCE[0]}" 2>/dev/null)
if [ -z "$sfp" ]; then sfp=${BASH_SOURCE[0]}; fi
SCRIPT_DIR=$(dirname "${sfp}")
# Icons used for printing
ARROW='➜'
DONE='✔'
ERROR='✗'
WARNING='⚠'
# Colors used for printing
RED='\033[0;31m'
BLUE='\033[0;34m'
BBLUE='\033[1;34m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
##
# Download files
##
download_file () {
  declare -r url=$1
  declare -r tf=$(mktemp)
  local dlcmd=''
  dlcmd="wget -O $tf"
  $dlcmd "${url}" &>/dev/null && echo "$tf" || echo '' # return the temp-filename (or empty string on error)
}
##
# Open files
##
open_file () { #expects one argument: file_path

  if [ "$(uname)" == 'Darwin' ]; then
    open "$1"
  elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    xdg-open "$1"
  else
    echo -e "${RED}${ERROR} Error: Sorry, opening files is not supported for your OS.${NC}"
  fi
}
# Get latest release tag from GitHub
get_latest_release_tag() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
  grep '"tag_name":' |
  sed -n 's/[^0-9.]*\([0-9.]*\).*/\1/p'
}

RELEASE_TAG=$(get_latest_release_tag ${REPO_NAME})

# Get latest release download url
get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
  grep '"browser_download_url":' |
  sed -n 's#.*\(https*://[^"]*\).*#\1#;p'
}

LATEST_RELEASE=$(get_latest_release ${REPO_NAME})

# Get latest release notes
get_latest_release_note() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
  grep '"body":' |
  sed -n 's/.*"\([^"]*\)".*/\1/;p'
}

RELEASE_NOTE=$(get_latest_release_note ${REPO_NAME})

# Get latest release title
get_latest_release_title() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
  grep -m 1 '"name":' |
  sed -n 's/.*"\([^"]*\)".*/\1/;p'
}

RELEASE_TITLE=$(get_latest_release_title ${REPO_NAME})

##
# Header
##
header () {
  echo -e "${GREEN}\n"
  echo ' ╔═══════════════════════════════════════════════════════════════════╗'
  echo ' ║                        '${SCRIPT_NAME}'                          ║'
  echo ' ║            Check for latest release from a GitHub repo            ║'
  echo ' ║                      Maintained by @tmiland                       ║'
  echo ' ║                          version: '${version}'                           ║'
  echo ' ╚═══════════════════════════════════════════════════════════════════╝'
  echo -e "${NC}"
}
# Update banner
show_update_banner () {
  header
  echo "Welcome to the ${SCRIPT_NAME} script."
  echo ""
  echo "There is a newer version of ${SCRIPT_NAME} available."
  echo ""
  echo ""
  echo -e "${GREEN}${DONE} New version:${NC} "${RELEASE_TAG}" - ${RELEASE_TITLE}"
  echo ""
  echo -e "${ORANGE}${ARROW} Notes:${NC}\n"
  echo -e "${BLUE}${RELEASE_NOTE}${NC}"
  echo ""
}
##
# Returns the version number of ${SCRIPT_NAME} file on line 2
##
get_updater_version () {
  echo $(sed -n '2 s/[^0-9.]*\([0-9.]*\).*/\1/p' "$1")
}
##
# Update invidious_update.sh
##
# Default: Check for update, if available, ask user if they want to execute it
update_updater () {
  echo -e "${GREEN}${ARROW} Checking for updates...${NC}"
  # Get tmpfile from github
  declare -r tmpfile=$(download_file "$LATEST_RELEASE")
  if [[ $(get_updater_version "${SCRIPT_DIR}/$SCRIPT_FILENAME") < "${RELEASE_TAG}" ]]; then
    if [ $UPDATE_SCRIPT = 'check' ]; then
      show_update_banner
      echo -e "${RED}${ARROW} Do you want to update [Y/N?]${NC}"
      read -p "" -n 1 -r
      echo -e "\n\n"
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        mv "${tmpfile}" "${SCRIPT_DIR}/${SCRIPT_FILENAME}"
        chmod u+x "${SCRIPT_DIR}/${SCRIPT_FILENAME}"
        "${SCRIPT_DIR}/${SCRIPT_FILENAME}" "$@" -d
        exit 1 # Update available, user chooses to update
      fi
      if [[ $REPLY =~ ^[Nn]$ ]]; then
        return 1 # Update available, but user chooses not to update
      fi
    fi
  else
    echo -e "${GREEN}${DONE} No update available.${NC}"
    return 0 # No update available
  fi
}
##
# Ask user to update yes/no
##
if [ $# != 0 ]; then
  while getopts ":ud" opt; do
    case $opt in
      u)
        UPDATE_SCRIPT='yes'
        ;;
      d)
        UPDATE_SCRIPT='no'
        ;;
      \?)
        echo -e "${RED}\n ${ERROR} Error! Invalid option: -$OPTARG${NC}" >&2
        usage
        ;;
      :)
        echo -e "${RED}${ERROR} Error! Option -$OPTARG requires an argument.${NC}" >&2
        exit 1
        ;;
    esac
  done
fi

update_updater $@
cd "$CURRDIR"
