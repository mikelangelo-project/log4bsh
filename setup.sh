#!/bin/bash
#
# Copyright 2016 HLRS, University of Stuttgart
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#=============================================================================
#
#         FILE: setup.sh
#
#        USAGE: setup.sh [--uninstall] [--userspace] [--prefix=<dir>]
#
#  DESCRIPTION: Setup/uninstall script for log4bsh
#
#       AUTHOR: Nico Struckmann, struckmann@hlrs.de
#      COMPANY: HLRS, University of Stuttgart
#      VERSION: 0.1
#      CREATED: March 23rd, 2017
#     REVISION: -
#
#    CHANGELOG
#
#=============================================================================



#----------------------------------------------------------------------------#
#                                                                            #
#                               CONSTANTS                                    #
#                      (do not touch or override!)                           #
#                                                                            #
#----------------------------------------------------------------------------#

#
# log4bsh repo base dir
#
BASE_DIR=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd);

#
# Default installation dir
#
DEFAULT_PREFIX="/usr/share";



#----------------------------------------------------------------------------#
#                                                                            #
#                            INTERNAL VARIABLES                              #
#                        (do not touch or override!)                         #
#                                                                            #
#----------------------------------------------------------------------------#

#
# Custom installation path
#
PREFIX="";

#
# Indicates if log4bsh is to install in user space or system-wide
#
USERSPACE=false;

#
# Indicates whether to remove or install log4bsh
#
UNINSTALL=false



#----------------------------------------------------------------------------#
#                                                                            #
#                               FUNCTIONS                                    #
#                                                                            #
#----------------------------------------------------------------------------#


#---------------------------------------------------------
#
# Prints usage information and exits.
#
# Parameter
#  none
#
# Returns
#  nothing
#
usage() {
  echo "usage: $(basename $0) [--unistall] [--prefix=<install_dir>] [--userspace]";
  exit 1;
}


#---------------------------------------------------------
#
# Parses command line arguments.
#
# Parameter
#  $1: all command line arguments '$@'
#
# Returns
#  0 in case of success, exits on failure
#
parseArguments() {

  OPTS=$(getopt -l prefix: userspace -- "$@");
  [ $? != 0 ] && usage;

  eval set -- "$OPTS"

  while true; do
    case "$1" in

      --prefix*)
          PREFIX=${1#--prefix};
          PREFIX=${PREFIX#=};
          [ -z ${PREFIX-} ] && usage;
          shift;;

      --userspace)
          USERSPACE=true;
          shift;;

      --uninstall)
          UNINSTALL=true;
          shift;;

      --)
          # skip
          shift;;

      *)
          break;;

    esac
  done

  # userspace or system wide installation ?
  if $USERSPACE \
      && [ $(uid -u) -ne 0 ]; then
    echo "Cannot install log4bsh systemwide as user, please use root/sudo instead.";
    exit 1;
  fi

  # prefix provided ?
  if [ -z ${PREFIX-} ]; then
    PREFIX=$DEFAULT_PREFIX;
  fi

  # is it a valid dir ?
  if [ ! -d $PREFIX ] \
      && [ ! `mkdir -p $PREFIX` ]; then
    echo "Installation path '$PREFIX' is not a directory and connot be created."
    usage;
  fi

  return 0;
}


#---------------------------------------------------------
#
# Installs log4bsh including its config file.
#
# Parameter
#  none
#
# Returns
#  0, exists on error
#
copyFiles() {

  local destDir="$PREFIX/log4bsh";
  local destFile;

  # ensure we can read/write files
  if [ ! -r "$destDir" ] || [ ! -w "$destDir" ]; then
    echo "Check permissions of dir '$destDir', cannot read/write files.";
    exit 1;
  fi

  # copy log4bsh
  echo "Installing log4bsh in dir '$destDir'";
  cp $BASE_DIR/src/log4bsh.sh $destDir/;

  # success ?
  if [ $? -ne 0 ]; then #no
    echo "Error copying log4bsh.sh to '$destDir'.";
    exit 1;
  fi

  # user space installation ?
  if $USERSPACE; then
    destFile=~/.log4bsh.conf;
  else
    destFile=/etc/log4bsh.conf;
  fi

  # copy config file
  echo "Copying configuration file to '$destFile'";
  cp $BASE_DIR/src/log4bsh.conf.example $destFile;

  # success
  if [ $? -ne 0 ]; then # no
    echo "Error copying the config file to '$destDir'.";
    exit 1;
  fi

  return 0;
}


#---------------------------------------------------------
#
# Removes log4bsh.
#
# Parameter
#  none
#
# Returns
#  0, exists on error
#
removeFiles() {

  local destDir="$PREFIX/log4bsh";
  local destFile;

  # dir exists
  if [ ! -d "$destDir" ]; then
    echo "log4bsh installation dir '$destDir' does not exist.";
    exit 1;
  fi

  # ensure we can read/write log4bsh dir
  if [ ! -r "$destDir" ] || [ ! -w "$destDir" ]; then
    echo "Check permissions of dir '$destDir', cannot read/write files.";
    exit 1;
  fi

  # remove log4bsh
  echo "Removing log4bsh installation dir '$destDir'";
  rm -Rf "$destDir";

  # user space installation ?
  if $USERSPACE; then
    destFile=~/.log4bsh.conf;
  else
    destFile=/etc/log4bsh.conf;
  fi

  # ensure we can read/write the config file
  if [ -e "$destFile" ]; then
    if ([ ! -r "$destFile" ] || [ ! -w "$destFile" ]); then
      echo "Check permissions of dir '$destDir', cannot read/write files.";
      exit 1;
    fi
    # remove config file
    echo "Removing configuration file '$destFile'";
    rm -f "$destFile";
  else
    echo "Configuration file '$destFile' to remove not found.";
  fi

  return 0;
}


#---------------------------------------------------------
#
# Enables log4bsh.
#
# Parameter
#  none
#
# Returns
#  0
#
setProfile() {

  local profile;

  if $USER_SPACE; then
    profile=~/.bashrc;
  else
    profile=/etc/profile.d/99-log4bsh.sh;
  fi

  if [ -z "$(cat $profile | grep source | grep log4bsh.sh)" ]; then
    echo "source $PREFIX/log4bsh.sh" >> $profile;
  fi
  return 0;
}


#---------------------------------------------------------
#
# Central internal logging function.
#
# Parameter
#  none
#
# Returns
#  0
#
clearProfile() {

  if $USER_SPACE; then
    local profile=~/.bashrc;
    if [ -z "$(cat $profile | grep source | grep log4bsh.sh)" ]; then
      sed -E 's,source\ .*log4bsh.sh,,g' $profile;
    fi
  else
    rm -f /etc/profile.d/99-log4bsh.sh;
  fi

  return 0;
}



#----------------------------------------------------------------------------#
#                                                                            #
#                                  MAIN                                      #
#                                                                            #
#----------------------------------------------------------------------------#


# parse args
parseArguments $@;

# remove or install ?
if $UNINSTALL; then
  # remove
  removeFiles;
  clearProfile;
  echo "Uninstall done";
else
  # install
  copyFiles;
  setProfile;
  echo "Install done";
fi

# done
exit 0;
