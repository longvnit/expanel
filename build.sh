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

do_make() {
	while
	echo "Trying to make ..."
	do
		make
		
		if [ $? -ne 0 ]; then
			printf "\nThe make has failed, would you like to try to make again? (yes/no): "
			read input
			until [ "${input}" = "yes" ] || [ "${input}" = "no" ]; do
				printf "\nPlease enter 'yes' or 'no': "
				read input
			done
			
			if [ "${input}" = "no" ]; then
				exit 0
			fi
		else
			break
		fi
	done
}

# $1=package name, $2=configure options
do_build() {
	if [ -z ${1} ] || [ -z ${2} ]; then
		echo "Exiting..."
		exit 0
	fi
	
	local EXT="tar.gz"
	if [ ! -n ${3} ]; then
		EXT=${3}
	fi
	
	local PACKAGE=${1}
	local FILE_NAME=${PACKAGE}.${EXT}
	local OPTS=${2}
	
	get_file ${FILE_NAME}
	
	if [ ! -d ${RESOURCE_PATH}/${PACKAGE} ]; then
		cd ${RESOURCE_PATH}
		tar zxvf ${RESOURCE_PATH}/${FILE_NAME}
		if [ ! -d ${RESOURCE_PATH}/${PACKAGE} ]; then
			echo "The tar has failed. Exiting..."
			exit 0
		fi 
	else 
		echo "${BOLD_PRE}${PACKAGE}${BOLD_SUB} already exist"
	fi
	
	cd ${RESOURCE_PATH}/${PACKAGE}
	
	echo "Configuring ${BOLD_PRE}${PACKAGE}${BOLD_SUB}...";
	
	./configure ${OPTS}
	
	echo "Done. Making ${BOLD_PRE}${PACKAGE}${BOLD_SUB}...";
	
	do_make
	
	echo "Installing ${BOLD_PRE}${PACKAGE}${BOLD_SUB}"
	
	make install
	
	echo "Done ${BOLD_PRE}${PACKAGE}${BOLD_SUB}"
}

# Make new build conf
build_autoconf() {
	local PACKAGE="autoconf-$(get_ver autoconf_ver)"
	do_build ${PACKAGE} "--prefix=/usr/local/"
}

build_automake() {
	local PACKAGE="autoconf-$(get_ver automake_ver)"
	do_build ${PACKAGE} "--prefix=/usr/local/"
}

build_libtool() {
	local PACKAGE="libtool-$(get_ver libtool_ver)"
	do_build ${PACKAGE} "--prefix=/usr/local/"
}

build_libjpeg() {
	local PACKAGE="libjpeg-$(get_ver autoconf_ver)"
	do_build ${PACKAGE} "--prefix=/usr/local/"
	
	# Fix path
	mkdir -p /usr/local/expanel/opt/libjpeg/bin
	mkdir -p /usr/local/expanel/opt/libjpeg/man/man1
}

build_libpng() {
	local PACKAGE="libpng-$(get_ver libpng_ver)"
	do_build ${PACKAGE} "--prefix=/usr/local/"
}


build_curl() {
	local PACKAGE="curl-$(get_ver curl_ver)"
	do_build ${PACKAGE} "--prefix=/usr/local/expanel/opt/curl"
}

build_pcre() {
	local PACKAGE="pcre-$(get_ver pcre_ver)"
	do_build ${PACKAGE} "--prefix=/usr/local/expanel/opt/pcre --enable-utf8 --enable-unicode-properties"
}

build_libcrypt() {
	local PACKAGE="pcre-$(get_ver pcre_ver)"
	do_build ${PACKAGE} "--prefix=/usr/local --enable-ltdl-install --disable-posix-threads"
}


build_libxml2() {
	local PACKAGE="libxml2-$(get_ver libxml2_ver)"
	do_build ${PACKAGE} "--prefix=/usr/local/expanel/opt/libxml2 --without-python"
}

build_mhash() {
	local PACKAGE="mhash-$(get_ver mhash_ver)"
	do_build ${PACKAGE} "--prefix=/usr/local/"
}

build_freetype() {
	local PACKAGE="freetype-$(get_ver freetype_ver)"
	do_build ${PACKAGE} "--prefix=/usr/local/"
}

build_icu() {
	local PACKAGE="icu-$(get_ver icu_ver)"
	do_build ${PACKAGE} "--prefix=/usr/local/expanel/opt/icu"
}

build_iconv() {
	local PACKAGE="iconv-$(get_ver iconv_ver)"
	do_build ${PACKAGE} "--prefix=/usr/local/"
}

build_zlib() {
	local PACKAGE="zlib-$(get_ver zlib_ver)"
	do_build ${PACKAGE} "--prefix=/usr/local/"
}

build_libevent() {

}

build_apache() {
	# Check exist
	if [ -d /usr/local/expanel/apache ]; then
		mv /usr/local/expanel/apache /usr/local/expanel/apache.bak
	fi
	
	local APACHE_VER="$(getVer apache_ver)"
	local PACKAGE=httpd-${APACHE_VER}
	local FILE_NAME=${PACKAGE}.tar.gz
	local CONF_NAME="configure.apache${APACHE_VER//./}"
	
	cd ${RESOURCE_PATH}
	
	if [ ! -d ${PACKAGE} ]; then
		if [ ! -e ${FILE_NAME} ]; then
			getFile ${FILE_NAME}
		fi
		if [ ! -e ${FILE_NAME} ]; then
			echo "Downloaded file ${FILE_NAME} does not exist or is empty after download";
			exit 0
		else
			tar zxvf ${FILE_NAME}
			if [ ! -d ${PACKAGE} ]; then
				echo "The tar has failed. Exiting..."
				exit 0
			fi	
		fi
		
	else 
		echo "${BOLD_PRE}${PACKAGE}${BOLD_SUB} already exist"
	fi
	
	cd ${PACKAGE}
	
	# Get PHP handler
	local PHP_HANDLER="$(getOpt php_handler)"
	if [ -z ${PHP_HANDLER} ]; then
		echo "You must configure PHP handler before. Exiting..."
		exit 0
	fi
	
	if [ ! -e ${BUILD_PATH}/custom/apache/${CONF_NAME}.${PHP_HANDLER} ]; then
		if [ ! -d ${BUILD_PATH}/custom/apache ]; then
			mkdir -p ${BUILD_PATH}/custom/apache
		fi
		
		wget ${WEB_RESOURCE}/custom/apache/${CONF_NAME}.${PHP_HANDLER} -O ${BUILD_PATH}/custom/apache/${CONF_NAME}.${PHP_HANDLER}
		
		if [ ! -s ${BUILD_PATH}/custom/apache/${CONF_NAME}.${PHP_HANDLER} ]; then
			echo "Downloaded file apache configure does not exist or is empty after download. Exiting...";
			exit 0
		fi
	fi
	
	sh ${BUILD_PATH}/custom/apache/${CONF_NAME}.${PHP_HANDLER}
		
	do_make
	
	echo "Installing ${BOLD_PRE}${PACKAGE}${BOLD_SUB}"
	
	make install
	
	echo "Done ${BOLD_PRE}${PACKAGE}${BOLD_SUB}"
	
}

build_apache_conf() {

}

build_nginx() {
	# Check exist
	if [ -d /usr/local/expanel/nginx ]; then
		mv /usr/local/expanel/nginx /usr/local/expanel/nginx.bak
	fi
	
	local NGINX_VER="$(getVer nginx_ver)"
	local PACKAGE=httpd-${NGINX_VER}
	local FILE_NAME=${PACKAGE}.tar.gz
	
	cd ${RESOURCE_PATH}
	
	if [ ! -d ${PACKAGE} ]; then
		if [ ! -e ${FILE_NAME} ]; then
			getFile ${FILE_NAME}
		fi
		if [ ! -e ${FILE_NAME} ]; then
			echo "Downloaded file ${FILE_NAME} does not exist or is empty after download";
			exit 0
		else
			tar zxvf ${FILE_NAME}
			if [ ! -d ${PACKAGE} ]; then
				echo "The tar has failed. Exiting..."
				exit 0
			fi	
		fi
		
	else 
		echo "${BOLD_PRE}${PACKAGE}${BOLD_SUB} already exist"
	fi
	
	cd ${PACKAGE}
	
	if [ ! -e ${BUILD_PATH}/custom/nginx/configure.nginx ]; then
		if [ ! -d ${BUILD_PATH}/custom/nginx ]; then
			mkdir -p ${BUILD_PATH}/custom/nginx
		fi
		
		wget ${WEB_RESOURCE}/custom/nginx/configure.nginx -O ${BUILD_PATH}/custom/nginx/configure.nginx
		
		if [ ! -s ${BUILD_PATH}/custom/nginx/configure.nginx ]; then
			echo "Downloaded file apache configure does not exist or is empty after download. Exiting...";
			exit 0
		fi
	fi
	
	sh ${BUILD_PATH}/custom/nginx/configure.nginx
		
	do_make
	
	echo "Installing ${BOLD_PRE}${PACKAGE}${BOLD_SUB}"
	
	make install
	
	echo "Done ${BOLD_PRE}${PACKAGE}${BOLD_SUB}"
}

build_php() {
	# Check exist
	if [ -d /usr/local/expanel/php ]; then
		mv /usr/local/expanel/php /usr/local/expanel/php.bak
	fi
	
	local PHP_VER="$(getVer php_ver)"
	local PACKAGE=httpd-${PHP_VER}
	local FILE_NAME=${PACKAGE}.tar.gz
	local CONF_NAME="configure.php${PHP_VER//./}"
	
	cd ${RESOURCE_PATH}
	
	if [ ! -d ${PACKAGE} ]; then
		if [ ! -e ${FILE_NAME} ]; then
			getFile ${FILE_NAME}
		fi
		if [ ! -e ${FILE_NAME} ]; then
			echo "Downloaded file ${FILE_NAME} does not exist or is empty after download";
			exit 0
		else
			tar zxvf ${FILE_NAME}
			if [ ! -d ${PACKAGE} ]; then
				echo "The tar has failed. Exiting..."
				exit 0
			fi	
		fi
		
	else 
		echo "${BOLD_PRE}${PACKAGE}${BOLD_SUB} already exist"
	fi
	
	cd ${PACKAGE}
	
	# Get PHP handler to compile PHP (DSO, FCGI)
	local PHP_HANDLER="$(getOpt apache_handler)"
	if [ -z ${PHP_HANDLER} ]; then
		echo "You must configure PHP handler before. Exiting..."
		exit 0
	fi
	
	if [ "${PHP_HANDLER}" = "dso" ]; then
		if [ ! -e /usr/local/expanel/apache/bin/apachectl ]; then
			build_apache
		fi
	fi
	
	if [ ! -e ${BUILD_PATH}/custom/php/${CONF_NAME}.${PHP_HANDLER} ]; then
		if [ ! -d ${BUILD_PATH}/custom/php ]; then
			mkdir -p ${BUILD_PATH}/custom/php
		fi
		
		wget ${WEB_RESOURCE}/custom/php/${CONF_NAME}.${PHP_HANDLER} -O ${BUILD_PATH}/custom/php/${CONF_NAME}.${PHP_HANDLER}
		
		if [ ! -s ${BUILD_PATH}/custom/php/${CONF_NAME}.${PHP_HANDLER} ]; then
			echo "Downloaded file apache configure does not exist or is empty after download. Exiting...";
			exit 0
		fi
	fi
	
	sh ${BUILD_PATH}/custom/php/${CONF_NAME}.${PHP_HANDLER}
		
	do_make
	
	echo "Installing ${BOLD_PRE}${PACKAGE}${BOLD_SUB}"
	
	make install
	
	echo "Done ${BOLD_PRE}${PACKAGE}${BOLD_SUB}"

}

build_php_conf() {
	if [ -d /usr/local/expanel/php ]; then
		build_php
	fi
	
	local PHP_HANDLER="$(get_opt php_handler)"
	
	if [ "${PHP_HANDLER}" = "dso" ]; then
		build_ruid2
	elif [ "${PHP_HANDLER}" = "fcgi" ]; then
		build_fcgi
	elif [ "${PHP_HANDLER}" = "php-fpm" ]; then
		build_fpm
	fi
}

build_fcgi() {
	if [ ! -e /usr/local/expanel/apache/bin/apxs ]; then
		build_apache
	fi
	
	if [ ! -e /usr/local/expanel/php/bin/php ]; then
		build_php
	fi
	
	local MOD_FCGI_VER="$(get_ver mod_fcgi_ver)"
	local PACKAGE="mod_fcgi-${MOD_RUID2_VER}"
	local FILE_NAME="${PACKAGE}.tar.gz"
	
	cd ${RESOURCE_PATH}
	
	if [ ! -d ${PACKAGE} ]; then
		if [ ! -e ${FILE_NAME} ]; then
			getFile ${FILE_NAME}
		fi
		if [ ! -e ${FILE_NAME} ]; then
			echo "Downloaded file ${FILE_NAME} does not exist or is empty after download";
			exit 0
		else
			tar zxvf ${FILE_NAME}
			if [ ! -d ${PACKAGE} ]; then
				echo "The unzip has failed. Exiting..."
				exit 0
			fi	
		fi
		
	else 
		echo "${BOLD_PRE}${PACKAGE}${BOLD_SUB} already exist"
	fi
	
	cd ${PACKAGE}
	
	APXS=/usr/local/expanel/apache/bin/apxs ./configure.apxs
	make
	
	if [ $? -ne 0 ]; then
		printf "\nThere was an error while trying to install ${PACKAGE}.\n";
		exit 0;
	fi
	
	make install
	
	# Configure
	# Step 1
	# Step 2
	# ...
}

build_ruid2() {
	if [ ! -e /usr/local/expanel/apache/bin/apxs ]; then
		build_apache
	fi
	
	if [ ! -e /usr/local/expanel/php/bin/php ]; then
		build_php
	fi
	
	local MOD_RUID2_VER="$(get_ver mod_ruid2_ver)"
	local PACKAGE="mod_ruid2-${MOD_RUID2_VER}"
	local FILE_NAME="${PACKAGE}.zip"
	
	cd ${RESOURCE_PATH}
	
	if [ ! -d ${PACKAGE} ]; then
		if [ ! -e ${FILE_NAME} ]; then
			getFile ${FILE_NAME}
		fi
		if [ ! -e ${FILE_NAME} ]; then
			echo "Downloaded file ${FILE_NAME} does not exist or is empty after download";
			exit 0
		else
			unzip ${FILE_NAME}
			if [ ! -d ${PACKAGE} ]; then
				echo "The unzip has failed. Exiting..."
				exit 0
			fi	
		fi
		
	else 
		echo "${BOLD_PRE}${PACKAGE}${BOLD_SUB} already exist"
	fi
	
	cd ${PACKAGE}
	
	# Get all the dependencies required to build
	
	if [ ! -e /lib/libcap.so ] && [ ! -e /lib64/libcap.so ] && [ ! -e /lib/x86_64-linux-gnu/libcap.so ] && [ ! -e /lib/i386-linux-gnu/libcap.so ]; then
		echo "Cannot find libcap.so.  Installing libcap";

		yum -y install libcap-devel
	fi
	
	if [ ! -e /usr/bin/bzip2 ] && [ ! -e /bin/bzip2 ]; then
		echo "Cannot find bzip2. Installing bzip2.";

		yum -y install bzip2
	fi
	
	/usr/local/expanel/apache/bin/apxs -a -i -l cap -c mod_ruid2.c
	
	if [ $? -ne 0 ]; then
		printf "\nThere was an error while trying to install ${PACKAGE}.\n";
		exit 0;
	fi
	
	# Configure
	# Step 1
	# Step 2
	# ...
}

build_fpm() {
	# Configure
	# Step 1
	# Step 2
	# ...
}

build_php_memcache() {

}

build_php_apc() {

}

build_php_zend() {

}

build_php_icube() {

}

build_mysql() {

}

build_mariadb() {

}

build_percona() {

}

build_memcache_server() {

}

rm -rf ${LOCK_FILE}
