#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Copyright 2013-2017 Aerospike, Inc.
#
# Portions may be licensed to Aerospike, Inc. under one or more contributor
# license agreements.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
# ------------------------------------------------------------------------------

OPT_LONG=0

if [ "$1" = "-long" ]
then
  OPT_LONG=1
fi

error() {
	echo 'error:' $* >&2
}

main() {

	local kernel=''
	local distro_id=''
	local distro_version=''
	local distro_long=''
	local distro_short=''

	# Make sure this script is running on Linux
	# The script is not designed to work on non-Linux
	# operating systems.
	kernel=$(uname -s | tr '[:upper:]' '[:lower:]')
	if [ "$kernel" != 'linux' ]
	then
		error "$kernel is not supported."
		exit 1
	fi

	if [ -f /etc/os-release ]
	then
		. /etc/os-release
		distro_id=${ID,,}
		distro_version=${VERSION_ID}
	elif [ -f /etc/issue ]
	then
		issue=$(cat /etc/issue | tr '[:upper:]' '[:lower:]')
		case "$issue" in
		*'centos'* )
			distro_id='centos'
			;;
        *'rocky'* )
                distro_id='rocky'
                ;;
		*'redhat'* )
			distro_id='redhat'
			;;
		*'debian'* )
			distro_id='debian'
			;;
		*'scientific'* )
			distro_id='scientific'
			;;
		*'amazon linux'* )
			distro_id='ami'
			;;
		* )
			error "/etc/issue contained an unsupported linux distibution: $issue"
			exit 1
			;;
		esac

		case "$distro_id" in
		'centos' | 'redhat' | 'scientific' | 'rocky' )
			local release=''
			if [ -f /etc/centos-release ]; then
				release=$(cat /etc/centos-release | tr '[:upper:]' '[:lower:]')
			elif [ -f /etc/redhat-release ]; then
				release=$(cat /etc/redhat-release | tr '[:upper:]' '[:lower:]')
            elif [ -f /etc/rocky-release ]; then
                    release=$(cat /etc/redhat-release | tr '[:upper:]' '[:lower:]')
            fi
			release_version=${release##*release}
			distro_version=${release_version%.*}
			;;
		'debian' )
			debian_version=$(cat /etc/debian_version | tr '[:upper:]' '[:lower:]')
			distro_version=${debian_version%%.*}
			;;
		'ami' )
			distro_version='ami'
			;;
		* )
			error "/etc/issue contained an unsupported linux distibution: $issue"
			exit 1
			;;
		esac
	fi

	distro_id=${distro_id//[[:space:]]/}
	distro_version=${distro_version//[[:space:]]/}

	case "$distro_id" in
	'centos' | 'redhat' | 'rhel' | 'scientific' | 'rocky' )
		distro_version=${distro_version%.*}
		distro_long="${distro_id}${distro_version}"
		distro_short="el${distro_version}"
		;;
	'fedora' )
		if [ "$distro_version" -gt "15" ]
		then
			distro_version=7
		elif [ "$distro_version" -gt "10" ]
		then
			distro_version=6
		else
			error "Unsupported linux distibution: $distro_id $distro_version"
			exit 1
		fi
		distro_long="centos${distro_version}"
		distro_short="el${distro_version}"
		;;
	'ubuntu' )
		distro_long="${distro_id}${distro_version}"
		distro_version=${distro_version%.*}
		distro_short="${distro_id}${distro_version}"
		;;
	'elementary' )
		case "$distro_version" in
		"0.4" )
			distro_version="16.04"
			;;
		* )
			error "Unsupported linux distibution version: $distro_id $distro_version"
			error "Guessing compatibility with Ubuntu 16.04"
			distro_version="16.04"
			;;
		esac
		distro_id="ubuntu"
		distro_long="${distro_id}${distro_version}"
		distro_version=${distro_version%.*}
		distro_short="${distro_id}${distro_version}"
		;;
	'linuxmint' )
		case "$distro_version" in
		"17"* )
			distro_version="14.04"
			;;
		"18"* )
			distro_version="16.04"
			;;
		* )
			error "Unsupported linux distibution version: $distro_id $distro_version"
			error "Guessing compatibility with Ubuntu 16.04"
			distro_version="16.04"
			;;
		esac
		distro_id="ubuntu"
		distro_long="${distro_id}${distro_version}"
		distro_version=${distro_version%.*}
		distro_short="${distro_id}${distro_version}"
		;;
	'amzn' | 'ami' )
		distro_long="ami"
		distro_short="ami"
		;;
	* )
		if [ "$ID_LIKE" ]
		then
			distro_id=$(echo "$ID_LIKE" | cut -d" " -f1)
			distro_version="_unknown"
		fi
		distro_long="${distro_id}${distro_version}"
		distro_short="${distro_id}${distro_version}"
		;;
	esac

	if [ "$OPT_LONG" = "1" ]
	then
		echo "${distro_long}"
	else
		echo "${distro_short}"
	fi
	exit 0
}

main