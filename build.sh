#/bin/bash
# This is script written by LongVNIT

EX_SCRIPT_VER=1.0.1
WORK_DIR=/usr/local/expanel/build
BUILD_CONF=${BUILD_DIR}/build.conf
LOCK_FILE=${BUILD_DIR}/.build

# Bolded text
BOLD_PRE="`tput -Txterm bold`"
BOLD_SUB="`tput -Txterm sgr0`"

# Secure script owner
if [ "$(id -u)" != "0" ]; then
	echo "You must be root to execute this script !!!"
	exit 0
fi

# Check process
if [ -e ${LOCK_FILE} ]; then
	echo "eXpanel build process is running !"
	exit 0
else
	touch ${LOCK_FILE}
fi

# Check WORK_DIR
if [ ! -d ${BUILD_DIR} ]; then
	mkdir -p ${BUILD_DIR}
fi

# Check build.conf
if [ ! -e ${BUILD_CONF} ]; then
	touch ${BUILD_CONF}
fi

# Secure folder
chown root.root ${WORK_DIR}
chmod 700 ${BUILD_DIR}

# Get conf
get_conf() 
{
	VALUE="`egrep "^$1=" ${BUILD_CONF} -m1 | cut -d= -f2`"
	echo ${VALUE}
}

# Set conf
set_conf() 
{
	# $1 Option, $2 Value
	if [ "$1" = "" ] || [ "$2" = "" ]; then
		echo "Please input conf"
	fi
	
	OLD_VALUE=`get_conf $1
	
	if [ "${OLD_VALUE}" = "" ]; then
		echo "Option doesn't exist !"
		exit 0
	fi
	
	perl -pi -e "s#$1=${OLD_VALUE}#$1=$2#" ${BUILD_CONF}
	
	echo "Changed ${BOLD_PRE}$1${BOLD_SUB} from ${OLD_VALUE} to $2"
}

# Make new build conf

# Build new conf
build_options()
{
echo -n "What mode should the default instance of PHP use? (mod_php/suphp/php-fpm/fastcgi): ";
        read php1type;
        until [ "${php1type}" = "mod_php" ] || [ "${php1type}" = "suphp" ] || [ "${php1type}" = "php-fpm" ] || [ "${php1type}" = "fastcgi" ]; do
                echo -n "Please enter 'mod_php', 'suphp', 'php-fpm' or 'fastcgi':"
                read php1type;
        done
}
