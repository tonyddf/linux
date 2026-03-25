#!/usr/bin/env bash

# ┌────────────────────────────────────────────────────────────────────────────┐
# │ Script Name:    wp-get.sh                                                  │
# │ Description:    Perform HTTP requests in Monarch's Web Platform            │
# │                                                                            │
# │ Author:         Martijn Ophoeff <Martijn.Ophoeff@TenneT.eu>                │
# │ Created:        2025-12-23                                                 │
# │ Last Updated:   2026-02-10                                                 │
# │ Version:        1.1.0                                                      │
# │ Usage:          ./wp-get.sh <OPTIONS>                                      │
# │                                                                            │
# │ Notes:          none			                               │
# │ Dependencies:   none                                                       │
# │                                                                            │
# │ Ver:   Date:       Author:     Description:                                │
# │ 1.0.0  2025-12-23  Martijn     Initial version                             │
# │ 1.1.0  2026-02-10  Tony        Added help and options                      │
# │ 1.2.0  2026-02-23  Tony        Added temporary file creation for cookies   │
# │ 1.3.0  2026-02-26  Tony        Added verbose option and examples           │
# └────────────────────────────────────────────────────────────────────────────┘

# Define the usage function
usage() {
	cat <<EOF
Usage: $( basename ${0} )
			[ -H | --hostname ] <remote server>
			[ -e | --endpoint ] <endpoint>
			[ -P | --password-file ] <password file>
			[ -s | --password-stdin ]
			[ -u | --user ] <user>
			[ -v | --verbose ]

The script allows a user with administrator rights to perform a HTTP GET operation
locally or through SSH connection to a remote server to a certain SwaggerUI
endpoint.

First, the script either runs in the localhost or establishes a SSH connection to
the declared remote server, authenticates to its Web Platform via the
authentication URL (displayed below) and saves a temporary cookie in directory /tmp/
to perform further HTTP GET operations.
  - authentication --> https://\$\{HOSTNAME\}:8443/platform/users/v1/login/v2?createCookie=true

Then, the script is able to re-use the cookie to perform a HTTP GET operation
to the specified SwaggerUI endpoint.

To determine which SwaggerUI endpoint to use, the user may decide to manually
authenticate through \"ttps://\$\{HOSTNAME\}:8443\" and access the URL's for the
endpoints, displayed below. This way a list of available HTTP GET operations become
visible.
  - Monarch's SCIM 	--> https://\$\{HOSTNAME\}:8443/swagger-ui/index.html?root=monarch/api/scim
  - Web Platform	--> https://\$\{HOSTNAME\}:8443/swagger-ui/index.html?root=platform

The endpoints must follow the following expression, so they must start with a slash:
  https://\$\{HOSTNAME\}:8443<endpoint>

Some available endpoints are:

  Get all Monarch groups		/monarch/api/scim/v2/Groups
  Get a single Monarch group		/monarch/api/scim/v2/Groups/<group id>
  Get all Monarch users			/monarch/api/scim/v2/Users
  Get a single Monarch user		/monarch/api/scim/v2/Users/<user id>

  Get all Web Platform groups		/platform/api/scim/v2/Groups
  Get a single Web Platform group	/platform/api/scim/v2/Groups/<user id>
  Get all Web Platform users		/platform/api/scim/v2/Users
  Get a single Web Platform user	/platform/api/scim/v2/Users/<user id>

Bear in mind:
  - A host can be declared, and if the localhost differs from it, a SSH session
    is established
  - A different user can be declared to both establish the SSH connection and
    authenticate into Web Platform
  - A password can be passed via standard input or a file containing the password
    can be declared (either option must be chosen for the script to run)
  - A SwaggerUI endpoint can be declared to perform the HTTP GET operation

OPTIONS:
  -h, --help			Display this help and exit
  -e, --endpoint		SwaggerUI endpoint to perform the HTTP GET request
  -H, --hostname		Hostname where HTTP requests will be established
  -P, --password-file		Read password from file
  -s, --password-stdin		Read password from standard input
  -u, --user			Execute SSH and HTTP actions as provided user
  -v, --verbose			Execute all SSH and HTTP actions with verbose mode

EXIT CODES:
  1				Failed to parse options
  2				Hostname field is empty
  3				User field is empty
  4				Password field is empty
  5				SwaggerUI endpoint field is empty
  6				SSH connection failed with exit code 255
  7				HTTP authentication failed with exit code #
  8				HTTP GET request failed with exit code #

Examples:
  List all Web Platform users in remote host, prompt for password
  $( basename ${0} ) --hostname=<remote server> --password-stdin
    --endpoint=/platform/api/scim/v2/Users

  List all Web Platform users in remote host with a different username,
  providing password via standard input
  printf '<secret password>' | $( basename ${0} ) --username=<different user>
    --hostname=<remote server> --password-stdin --endpoint=/platform/api/scim/v2/Users
EOF
}

# Parse command-line options
OPTS=$( getopt \
	--options e:,h,H:,P:,s,u:,v: \
	--longoptions endpoint:,help,hostname:,password-file:,password-stdin,user:,verbose \
	-- "${@}" )

if [[ $? -ne 0 ]]
then
	echo "ERROR: failed to parse options" >&2
	usage
	exit 1
fi

# Reorganize positional parameters
eval set -- "${OPTS}"

# Default variables
# Users in Monarch and Web Platform are by default composed by only the number
# part of the user
SUI_ENDPOINT=""
SUI_HOSTNAME="${HOSTNAME}"
SUI_PASSWORD=""
SUI_USER=$( echo "${USER}" | grep --only-matching --extended-regexp "[0-9]+" )
VERBOSE=""
COOKIE_JAR=$(mktemp)
# Ensure cleanup of the cookie on exit
trap 'rm --force "${COOKIE_JAR}"' EXIT


# Extract options and flags
while true
do
	case "${1}" in
		-h | --help )
			usage
			exit 0
			;;
		-e | --endpoint )
			SUI_ENDPOINT="${2}"
			shift 2
			;;
		-H | --hostname )
			SUI_HOSTNAME="${2}"
			shift 2
			;;
		-P | --password-file )
			SUI_PASSWORD=$(<"${2}")
			shift 2
			;;
		-s | --password-stdin )
			# If not a pipe, prompt for password
			if [[ -t 0 ]]
			then
				read -s -p "Enter password: " SUI_PASSWORD
				echo ""
			# If in a pipe, read from standard input
			else
				read -s -r SUI_PASSWORD
			fi
			shift 1
			;;
		-u | --user )
			SUI_USER="${2}"
			shift 2
			;;
		-v | --verbose )
			VERBOSE="-v"
			shift 1
			;;
		-- )
			shift
			break
			;;
		* )
			break
			;;
	esac
done


# Fail script if any input is empty
if [[ -z ${SUI_HOSTNAME} ]]
then
	echo "ERROR: hostname field is empty, please supply a hostname" 2>&1
	exit 2
elif [[ -z ${SUI_USER} ]]
then
	echo "ERROR: user field is empty, please supply a user" 2>&1
	exit 3
elif [[ -z ${SUI_PASSWORD} ]]
then
	echo "ERROR: password field is empty for user ${SUI_USER}, please supply a password" 2>&1
	exit 4
elif [[ -z ${SUI_ENDPOINT} ]]
then
	echo "ERROR: SwaggerUI endpoint field is empty, please provide a SwaggerUI endpoint" 2>&1
	exit 5
fi


# Define URL's
URL_AUTHENTICATION="https://${SUI_HOSTNAME}:8443/platform/users/v1/login/v2?createCookie=true"
URL_ENDPOINT="https://${SUI_HOSTNAME}:8443${SUI_ENDPOINT}"

# The code must fail immediately if an SSH connection is initialized but unsuccessful, therefore
# 1. Disable pseudo-terminal allocation
# 2. Force non-interactive mode
# 3. Add connection timeout (seconds)
# 4. Fail if host key is unknown
# 5. Force failures if server stops responding
# If return code is 1-254 the remote command failed, if 255 there is a SSH-level failure
SSH="ssh \
	-T \
	${VERBOSE} \
	-o BatchMode=yes \
	-o ConnectTimeout=5 \
	-o StrictHostKeyChecking=yes \
	-o ServerAliveInterval=5 \
	-o ServerAliveCountMax=1"


# If provided host does not match localhost, perform a test SSH connection and catch the result
if [[ "${HOSTNAME}" != "${SUI_HOSTNAME}" ]]
then
	SSH_TEST=$(${SSH} ${SUI_HOSTNAME} true 2>&1)
	SSH_TEST_RC=$?
	
	# Any SSH error exits with code 255
	if [[ ${SSH_TEST_RC} -eq 255 ]]
	then
		# Output errors
		echo "ERROR: SSH connection failed with exit code 255" 2>&1
		echo "${SSH_TEST}"
		exit 6
	fi
fi


# The login hash has the composition SUI_USER:SUI_PASSWORD
SUI_HASH=$( printf "${SUI_USER}:${SUI_PASSWORD}" | base64 )

# Execute HTTP authentication request locally, or remotely using SSH
if [[ "${HOSTNAME}" == "${SUI_HOSTNAME}" ]]
then
	SUI_AUTHENTICATION=$( \
		curl \
			${VERBOSE} \
			--request POST \
			--silent \
			--show-error \
			--insecure \
			--max-time 5 \
			--cookie-jar ${COOKIE_JAR} \
			--header "Authorization: Basic ${SUI_HASH}" \
		${URL_AUTHENTICATION} 2>&1 )
else
	SUI_AUTHENTICATION=$( \
		${SSH} ${SUI_HOSTNAME} bash -s <<-EOF
			curl \
				${VERBOSE} \
				--request POST \
				--silent \
				--show-error \
				--insecure \
				--max-time 5 \
				--cookie-jar ${COOKIE_JAR} \
				--header "Authorization: Basic ${SUI_HASH}" \
				${URL_AUTHENTICATION} 2>&1
			EOF
			)
fi

SUI_AUTHENTICATION_RC=$?

# If authentication fails, output error
if [[ ${SUI_AUTHENTICATION_RC} -ne 0 ]]
then
	echo "ERROR: authentication failed with RC=${SUI_AUTHENTICATION_RC}" 2>&1
	echo "${SUI_AUTHENTICATION}"
	exit 7
fi

# Perform the HTTP GET request
if [[ "${HOSTNAME}" == "${SUI_HOSTNAME}" ]]
then
	SUI_ENDPOINT=$( \
		curl \
			${VERBOSE} \
			--request GET \
			--silent \
			--show-error \
			--insecure \
			--max-time 20 \
			--cookie-jar ${COOKIE_JAR} \
			--cookie ${COOKIE_JAR} \
			--header "Accept: application/json" \
		${URL_ENDPOINT} 2>&1 )
else
	SUI_ENDPOINT=$( \
		${SSH} ${SUI_HOSTNAME} bash -s <<-EOF
			curl \
				${VERBOSE} \
				--request GET \
				--silent \
				--show-error \
				--insecure \
				--max-time 20 \
				--cookie-jar ${COOKIE_JAR} \
				--cookie ${COOKIE_JAR} \
				--header "Accept: application/json" \
			${URL_ENDPOINT} 2>&1
			EOF
			)
fi

SUI_ENDPOINT_RC=$?

# If HTTP GET request fails, output error
if [[ ${SUI_ENDPOINT_RC} -ne 0 ]]
then
	echo "ERROR: HTTP GET request failed with RC=${SUI_ENDPOINT_RC}" 2>&1
	echo "${SUI_ENDPOINT}" 2>&1
	exit 8
else
	echo "${SUI_ENDPOINT}"
	exit 0
fi
