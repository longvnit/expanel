#/bin/bash
# This is script written by LongVNIT

# Define

SCRIPT_VER=1.0.1
BUILD_PATH=/Users/longnt/expanel
RESOURCE_PATH=${BUILD_PATH}/resources
RESOURCE_VER=${RESOURCE_PATH}/.ver
BUILD_OPTS=${BUILD_PATH}/.conf
LOCK_FILE=${BUILD_PATH}/.lock

# Define
WEB_RESOURCE=http://203.162.53.110

# Bolded text
BOLD_PRE="`tput -Txterm bold`"
BOLD_SUB="`tput -Txterm sgr0`"

# Secure script owner
if [ "$(id -u)" != "0" ]; then
	echo "You must be root to execute this script"
	#exit 0
fi

# Check process
if [ -e ${LOCK_FILE} ]; then
	echo "eXpanel build process is running"
	#exit 0
else
	touch ${LOCK_FILE}
fi

# Check BUILD_PATH
if [ ! -d ${BUILD_PATH} ]; then
	mkdir -p ${BUILD_PATH}
fi

# Check RESOURCE_PATH
if [ ! -d ${RESOURCE_PATH} ]; then
	mkdir -p ${RESOURCE_PATH}
fi

# Check build.conf
if [ ! -e ${BUILD_OPTS} ]; then
	touch ${BUILD_OPTS}
fi

# Secure folder
#chown root:root ${WORK_DIR}
chmod 700 ${BUILD_PATH}

ask_yesno() {
	if [ -z "${1}" ]; then
		return
	fi
	
	printf "\n${1} (yes,no): ";
	read answer
	echo ${answer}
	until [ "${answer}" = "yes" ] || [ "${answer}" = "no" ]; do
		printf "\nPlease enter 'yes' or 'no': "
		read answer
	done
	echo ${answer}
}

get_file() {
	if [ -n ${1} ]; then
		if [ -s ${RESOURCE_PATH}/$1 ]; then
			echo "File ${BOLD_PRE}$1${BOLD_SUB} already exist"
		else
			printf "Downloading \t\t ${BOLD_PRE}$1${BOLD_SUB}...\n"
			wget ${WEB_RESOURCE}/resources/$1 -O ${RESOURCE_PATH}/$1
			if [ ! -s ${RESOURCE_PATH}/$1 ]; then
				echo "Downloaded file ${1} does not exist or is empty after download";
			fi
		fi
	else
		echo "Please enter file name" 
	fi
}

# Get version
get_ver() 
{
	local value="$(egrep "^${1}=" ${RESOURCE_VER} -m1 | cut -d= -f2)"
	echo ${value}
}

# Get conf
get_opt() 
{
	local value="$(egrep "^${1}=" ${BUILD_OPTS} -m1 | cut -d= -f2)"
	echo ${value}
}

# Set conf
set_opt() 
{
	# $1 Option, $2 Value
	if [ -z ${1} ] || [ -z ${2} ]; then
		echo "Please input option name"
	fi
	
	local OLD_VALUE=$(get_opt ${1})
	
	if [ -z ${OLD_VALUE} ]; then
		echo "Option doesn't exist"
		exit 0
	fi
	
	perl -pi -e "s#${1}=${OLD_VALUE}#${1}=${2}#" ${BUILD_OPTS}
	
	echo "Changed ${BOLD_PRE}${1}${BOLD_SUB} from ${BOLD_PRE}${OLD_VALUE}${BOLD_SUB} to ${BOLD_PRE}${2}${BOLD_SUB}"
}

# Make new build conf
build_autoconf()
{
	local AUTOCONF_VER="$(get_ver autoconf_ver)"
	get_file autoconf-${AUTOCONF_VER}.tar.gz
	
	if [ ! -d ${RESOURCE_PATH}/autoconf-${AUTOCONF_VER} ]; then
		tar zxvf ${RESOURCE_PATH}/autoconf-${AUTOCONF_VER}.tar.gz
		if [ ! -d ${RESOURCE_PATH}/autoconf-${AUTOCONF_VER} ]; then
			echo "The tar has failed. Exiting..."
			exit 0
		fi 
	else 
		echo "${BOLD_PRE}autoconf-${AUTOCONF_VER}${BOLD_SUB} already exist"
	fi
	
	cd ${RESOURCE_PATH}/autoconf-${AUTOCONF_VER}
	
	echo "Configuring ${BOLD_PRE}autoconf-${AUTOCONF_VER}${BOLD_SUB}...";
	./configure --prefix=/usr/local
	echo "Done. Making ${BOLD_PRE}autoconf-${AUTOCONF_VER}${BOLD_SUB}...";
	while
	echo "Trying to make ..."
	do
		make
		
		if [ $? -ne 0 ]; then
			printf "\nThe make has failed, would you like to try to make again? (yes/no): "
			read yesno
			until [ "${yesno}" = "yes" ] || [ "${yesno}" = "no" ]; do
				printf "\nPlease enter 'yes' or 'no': "
				read yesno
			done
			
			if [ "${yesno}" = "no" ]; then
				exit 0
			fi
		else
			break
		fi
	done
	echo "Make complete"
	echo "Installing ${BOLD_PRE}autoconf-${AUTOCONF_VER}${BOLD_SUB}"
	
	make install
	
	echo "Done ${BOLD_PRE}autoconf-${AUTOCONF_VER}${BOLD_SUB}"
}

build_automake()
{
	wget 
	tar zxvf
	./configure --prefix=/usr/local
	make 
	make install
}

build_libtool()
{
	wget
	tar zxvf
	./configure --prefix=/usr/local
	make
	make install
}

build_libjpeg()
{
	wget
	tar zxvf
	./configure --prefix=/usr/local
	make
	make install
	# Fix
	mkdir -p /usr/local/expanel/opt/libjpeg/bin
	mkdir -p /usr/local/expanel/opt/libjpeg/man/man1
}

build_libpng()
{
	wget
	tar zxvf
	./configure --prefix=/usr/local
	make
	make install
}


build_curl()
{
	wget 
	tar zxvf
	./configure --prefix=/usr/local/expanel/opt/curl
}

build_pcre()
{
	wget
	tar zxvf
	./configure --prefix=/usr/local/expanel/opt/pcre --enable-utf8 --enable-unicode-properties
}

build_libcrypt()
{
	wget
	tar zxvf
	./configure --prefix=/usr/local --enable-ltdl-install --disable-posix-threads
}



build_libxml2()
{
	wget 
	tar zxvf 
	./configure --prefix=/usr/local/expanel/opt/libxml2 --without-python
	make
	make install
	
}

#build_apache() {
#}

#build_nginx() {
#}

#build_php() {
#}

#build_mysql() {
#}

#build_mariadb() {
#}

# Build new conf
build_options()
{
echo "What mode should the default instance of PHP use? (mod_php/suphp/php-fpm/fastcgi): ";
        read php1type;
        until [ "${php1type}" = "mod_php" ] || [ "${php1type}" = "suphp" ] || [ "${php1type}" = "php-fpm" ] || [ "${php1type}" = "fastcgi" ]; do
                echo "Please enter 'mod_php', 'suphp', 'php-fpm' or 'fastcgi':"
                read php1type;
        done
}

rm -rf ${LOCK_FILE}
