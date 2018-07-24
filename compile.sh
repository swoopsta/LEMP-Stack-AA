#!/bin/bash
# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
# Check root access------------------------------------------------------------
if [[ "$EUID" -ne 0 ]]; then
	echo -e "${CRED}Sorry, you need to run this as root${CEND}"
	exit 1
fi
#
# Variables--------------------------------------------------------------------
NGINX_MAINLINE_VER=1.15.2
OPENSSL_VER=1.1.1-pre8
HEADERMOD_VER=0.33
PCRE_VER=8.42
ZLIB_VER=1.2.11
NPS_VER=1.13.35.2

# Clear log file---------------------------------------------------------------
rm /tmp/nginx-autoinstall.log

clear
echo ""
echo "Welcome to the Nginx Compiling Script"
echo ""
echo "This script will build Nginx with some optional modules and create a deb package file"
echo ""
read -n1 -r -p "Nginx is ready to be compiled, press any key to continue..."
echo ""
# Cleanup-----------------------------------------------------------------------
# The directory should be deleted at the end of the script, but in case it fails
rm -r /usr/local/src/nginx/ >> /tmp/nginx-autoinstall.log 2>&1
mkdir -p /usr/local/src/nginx/modules >> /tmp/nginx-autoinstall.log 2>&1
# Dependencies------------------------------------------------------------------
echo -ne "       Installing dependencies      [..]\r"
apt update && apt upgrade >> /tmp/nginx-autoinstall.log 2>&1
apt install autotools-dev autoconf automake libtool build-essential checkinstall curl debhelper dh-systemd gcc git htop libbz2-dev libexpat-dev libgd2-noxpm-dev libgd2-xpm-dev libgeoip-dev libgoogle-perftools-dev libluajit-5.1-dev libmhash-dev libpam0g-dev libpcre3 libpcre3-dev libperl-dev libssl-dev libxslt1-dev make nano openssl po-debconf software-properties-common sudo tar unzip wget zlib1g zlib1g-dbg zlib1g-dev uuid-dev -y
export locale-gen en_US.UTF-8 >> /tmp/nginx-autoinstall.log 2>&1
export LANG=en_US.UTF-8-y >> /tmp/nginx-autoinstall.log 2>&1

if [ $? -eq 0 ]; then
	echo -ne "       Installing dependencies        [${CGREEN}OK${CEND}]\r"
	echo -ne "\n"
else
	echo -e "        Installing dependencies      [${CRED}FAIL${CEND}]"
	echo ""
	echo "Please look at /tmp/nginx-autoinstall.log"
	echo ""
	exit 1
fi

# PageSpeed---------------------------------------------------------------------
cd /usr/local/src/nginx/modules
# Download and extract of PageSpeed module
echo -ne "       Downloading ngx_pagespeed      [..]\r"
wget https://github.com/pagespeed/ngx_pagespeed/archive/v${NPS_VER}-stable.zip >> /tmp/nginx-autoinstall.log 2>&1
unzip v${NPS_VER}-stable.zip >> /tmp/nginx-autoinstall.log 2>&1
cd incubator-pagespeed-ngx-${NPS_VER}-stable
psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_VER}.tar.gz
[ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
wget ${psol_url} >> /tmp/nginx-autoinstall.log 2>&1
tar -xzvf $(basename ${psol_url}) >> /tmp/nginx-autoinstall.log 2>&1
if [ $? -eq 0 ]; then
	echo -ne "       Downloading ngx_pagespeed      [${CGREEN}OK${CEND}]\r"
	echo -ne "\n"
else
	echo -e "       Downloading ngx_pagespeed      [${CRED}FAIL${CEND}]"
	echo ""
	echo "Please look at /tmp/nginx-autoinstall.log"
	echo ""
	exit 1
fi
#Brotli-------------------------------------------------------------------------
# ngx_brotli module download
cd /usr/local/src/nginx/modules
echo -ne "       Downloading ngx_brotli         [..]\r"
git clone https://github.com/eustas/ngx_brotli >> /tmp/nginx-autoinstall.log 2>&1
cd ngx_brotli
git checkout v0.1.2 >> /tmp/nginx-autoinstall.log 2>&1
git submodule update --init >> /tmp/nginx-autoinstall.log 2>&1
if [ $? -eq 0 ]; then
	echo -ne "       Downloading ngx_brotli         [${CGREEN}OK${CEND}]\r"
	echo -ne "\n"
else
	echo -e "       Downloading ngx_brotli         [${CRED}FAIL${CEND}]"
	echo ""
	echo "Please look at /tmp/nginx-autoinstall.log"
	echo ""
	exit 1
fi
# More Headers------------------------------------------------------------------
cd /usr/local/src/nginx/modules
echo -ne "       Downloading ngx_headers_more   [..]\r"
wget https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERMOD_VER}.tar.gz >> /tmp/nginx-autoinstall.log 2>&1
tar xaf v${HEADERMOD_VER}.tar.gz
if [ $? -eq 0 ]; then
	echo -ne "       Downloading ngx_headers_more   [${CGREEN}OK${CEND}]\r"
	echo -ne "\n"
else
	echo -e "       Downloading ngx_headers_more   [${CRED}FAIL${CEND}]"
	echo ""
	echo "Please look at /tmp/nginx-autoinstall.log"
	echo ""
	exit 1
fi
# PCRE-------------------------------------------------------------------------
cd /usr/local/src/nginx/modules
echo -ne "       Downloading PCRE     [..]\r"
wget https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VER}.tar.gz >> /tmp/nginx-autoinstall.log 2>&1
tar xzvf pcre-${PCRE_VER}).tar.gz
if [ $? -eq 0 ]; then
	echo -ne "       Downloading PCRE      [${CGREEN}OK${CEND}]\r"
	echo -ne "\n"
else
	echo -e "       Downloading PCRE      [${CRED}FAIL${CEND}]"
	echo ""
	echo "Please look at /tmp/nginx-autoinstall.log"
	echo ""
	exit 1
fi
# Cache Purge------------------------------------------------------------------
cd /usr/local/src/nginx/modules
echo -ne "       Downloading ngx_cache_purge    [..]\r"
git clone https://github.com/FRiCKLE/ngx_cache_purge >> /tmp/nginx-autoinstall.log 2>&1
if [ $? -eq 0 ]; then
	echo -ne "       Downloading ngx_cache_purge    [${CGREEN}OK${CEND}]\r"
	echo -ne "\n"
else
	echo -e "       Downloading ngx_cache_purge    [${CRED}FAIL${CEND}]"
	echo ""
	echo "Please look at /tmp/nginx-autoinstall.log"
	echo ""
	exit 1
fi
# zlib--------------------------------------------------------------------------
cd /usr/local/src/nginx/modules
echo -ne "       Downloading zlib           [..]\r"
wget http://www.zlib.net/zlib-${ZLIB_VER}.tar.gz >> /tmp/nginx-autoinstall.log 2>&1
tar xzvf zlib-${ZLIB_VER}.tar.gz
if [ $? -eq 0 ]; then
	echo -ne "       Downloading zlib           [${CGREEN}OK${CEND}]\r"
	echo -ne "\n"
else
	echo -e "       Downloading zlib           [${CRED}FAIL${CEND}]"
	echo ""
	echo "Please look at /tmp/nginx-autoinstall.log"
	echo ""
	exit 1
fi
# OpenSSL----------------------------------------------------------------------
cd /usr/local/src/nginx/modules
# OpenSSL download
echo -ne "       Downloading OpenSSL            [..]\r"
wget https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz >> /tmp/nginx-autoinstall.log 2>&1
tar xaf openssl-${OPENSSL_VER}.tar.gz
cd openssl-${OPENSSL_VER}
if [ $? -eq 0 ]; then
	echo -ne "       Downloading OpenSSL            [${CGREEN}OK${CEND}]\r"
	echo -ne "\n"
else
	echo -e "       Downloading OpenSSL            [${CRED}FAIL${CEND}]"
	echo ""
	echo "Please look at /tmp/nginx-autoinstall.log"
	echo ""
	exit 1
fi
echo -ne "       Configuring OpenSSL            [..]\r"
./config >> /tmp/nginx-autoinstall.log 2>&1
if [ $? -eq 0 ]; then
	echo -ne "       Configuring OpenSSL            [${CGREEN}OK${CEND}]\r"
	echo -ne "\n"
else
	echo -e "       Configuring OpenSSL          [${CRED}FAIL${CEND}]"
	echo ""
	echo "Please look at /tmp/nginx-autoinstall.log"
	echo ""
	exit 1
fi
# Download and extract of Nginx source code-------------------------------------
cd /usr/local/src/nginx/
echo -ne "       Downloading Nginx              [..]\r"
wget -qO- http://nginx.org/download/nginx-${NGINX_VER}.tar.gz | tar zxf -
cd nginx-${NGINX_VER}
if [ $? -eq 0 ]; then
	echo -ne "       Downloading Nginx              [${CGREEN}OK${CEND}]\r"
	echo -ne "\n"
else
	echo -e "       Downloading Nginx              [${CRED}FAIL${CEND}]"
	echo ""
	echo "Please look at /tmp/nginx-autoinstall.log"
	echo ""
	exit 1
fi

cd /usr/local/src/nginx/nginx-${NGINX_VER}
# Modules configuration
# Common configuration
NGINX_OPTIONS="
--prefix=/etc/nginx \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/run/nginx.lock \
--http-client-body-temp-path=/var/cache/nginx/client_temp \
--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
--user=www-data \
--group=www-data \
--with-cc-opt=-Wno-deprecated-declarations"

NGINX_MODULES="--without-http_ssi_module \
--without-http_scgi_module \
--without-http_uwsgi_module \
--without-http_geo_module \
--without-http_empty_gif_module \
--without-mail_imap_module \
--without-mail_pop3_module \
--without-mail_smtp_module \
--with-threads \
--with-file-aio \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_auth_request_module \
--with-http_slice_module \
--with-http_stub_status_module \
--with-http_realip_module"
# Optional modules
# PCRE
NGINX_MODULES=$(echo $NGINX_MODULES; echo --with-pcre=/usr/local/src/nginx/modules/pcre-${PCRE_VER})
# PageSpeed
NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/incubator-pagespeed-ngx-${NPS_VER}-stable")
# Brotli
NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/ngx_brotli")
# More Headers
NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/headers-more-nginx-module-${HEADERMOD_VER}")
# zlib
NGINX_MODULES=$(echo $NGINX_MODULES; echo "--with-zlib=/usr/local/src/nginx/modules/zlib-${ZLIB_VER}")
# OpenSSL
NGINX_MODULES=$(echo $NGINX_MODULES; echo "--with-openssl=/usr/local/src/nginx/modules/openssl-${OPENSSL_VER}")
# Cache Purge
NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/ngx_cache_purge")
# Cloudflare's TLS Dynamic Record Resizing patch
echo -ne "       TLS Dynamic Records support    [..]\r"
wget https://raw.githubusercontent.com/cloudflare/sslconfig/master/patches/nginx__1.11.5_dynamic_tls_records.patch >> /tmp/nginx-autoinstall.log 2>&1
patch -p1 < nginx__1.11.5_dynamic_tls_records.patch >> /tmp/nginx-autoinstall.log 2>&1
if [ $? -eq 0 ]; then
	echo -ne "       TLS Dynamic Records support    [${CGREEN}OK${CEND}]\r"
	echo -ne "\n"
else
	echo -e "       TLS Dynamic Records support    [${CRED}FAIL${CEND}]"
	echo ""
	echo "Please look at /tmp/nginx-autoinstall.log"
	echo ""
	exit 1
fi
# Configure Nginx---------------------------------------------------------------
echo -ne "       Configuring Nginx              [..]\r"
./configure $NGINX_OPTIONS $NGINX_MODULES >> /tmp/nginx-autoinstall.log 2>&1
if [ $? -eq 0 ]; then
	echo -ne "       Configuring Nginx              [${CGREEN}OK${CEND}]\r"
	echo -ne "\n"
else
	echo -e "       Configuring Nginx              [${CRED}FAIL${CEND}]"
	echo ""
	echo "Please look at /tmp/nginx-autoinstall.log"
	echo ""
	exit 1
fi
# Compile Nginx-----------------------------------------------------------------
echo -ne "       Compiling Nginx                [..]\r"
make -j $(nproc) >> /tmp/nginx-autoinstall.log 2>&1
if [ $? -eq 0 ]; then
	echo -ne "       Compiling Nginx                [${CGREEN}OK${CEND}]\r"
	echo -ne "\n"
else
	echo -e "       Compiling Nginx                [${CRED}FAIL${CEND}]"
	echo ""
	echo "Please look at /tmp/nginx-autoinstall.log"
	echo ""
	exit 1
fi
# Then we build a deb package
echo -ne "       Building Deb Package               [..]\r"
checkinstall >> /tmp/nginx-autoinstall.log 2>&1

# Remove debugging symbols
strip -s /usr/sbin/nginx
#if [ $? -eq 0 ]; then
# Nginx installation from source does not add an init script for systemd and logrotate
# Using the official systemd script and logrotate conf from nginx.org
#if [[ ! -e /lib/systemd/system/nginx.service ]]; then
#cd /lib/systemd/system/
#wget https://raw.githubusercontent.com/Angristan/nginx-autoinstall/master/conf/nginx.service >> /tmp/nginx-autoinstall.log 2>&1
# Enable nginx start at boot
#systemctl enable nginx >> /tmp/nginx-autoinstall.log 2>&1
#fi

#if [[ ! -e /etc/logrotate.d/nginx ]]; then
#cd /etc/logrotate.d/
#wget https://raw.githubusercontent.com/Angristan/nginx-autoinstall/master/conf/nginx-logrotate -O nginx >> /tmp/nginx-autoinstall.log 2>&1
#fi

# Nginx's cache directory is not created by default
#if [[ ! -d /var/cache/nginx ]]; then
#	mkdir -p /var/cache/nginx
#fi

# We add sites-* folders as some use them. /etc/nginx/conf.d/ is the vhost folder by defaultnginx
#if [[ ! -d /etc/nginx/sites-available ]]; then
#	mkdir -p /etc/nginx/sites-available
#fi
#if [[ ! -d /etc/nginx/sites-enabled ]]; then
#	mkdir -p /etc/nginx/sites-enabled
#fi
# Restart Nginx
#echo -ne "       Restarting Nginx               [..]\r"
#systemctl restart nginx >> /tmp/nginx-autoinstall.log 2>&1
#if [ $? -eq 0 ]; then
#	echo -ne "       Restarting Nginx               [${CGREEN}OK${CEND}]\r"
#	echo -ne "\n"
#else
#	echo -e "       Restarting Nginx               [${CRED}FAIL${CEND}]"
#	echo ""
#	echo "Please look at /tmp/nginx-autoinstall.log"
#	echo ""
#	exit 1
#fi

#if [[ $(lsb_release -si) == "Debian" ]] || [[ $(lsb_release -si) == "Ubuntu" ]]
#	then
#	echo -ne "       Blocking nginx from APT        [..]\r"
#	cd /etc/apt/preferences.d/
#	echo -e "Package: nginx*\nPin: release *\nPin-Priority: -1" > nginx-block
#	echo -ne "       Blocking nginx from APT        [${CGREEN}OK${CEND}]\r"
#	echo -ne "\n"
#fi
# Removing temporary Nginx and modules files
#		echo -ne "       Removing Nginx files           [..]\r"
#		rm -r /usr/local/src/nginx >> /tmp/nginx-autoinstall.log 2>&1
#		echo -ne "       Removing Nginx files           [${CGREEN}OK${CEND}]\r"
#		echo -ne "\n"

		# We're done !
#		echo ""
#		echo -e "       ${CGREEN}Installation successful !${CEND}"
#		echo ""
		echo "       Installation log: /tmp/nginx-autoinstall.log"
#		echo ""
#	exit
#	;;
#	2) # Uninstall Nginx
#		while [[ $CONF !=  "y" && $CONF != "n" ]]; do
#			read -p "       Remove configuration files ? [y/n]: " -e CONF
#		done
#		while [[ $LOGS !=  "y" && $LOGS != "n" ]]; do
#			read -p "       Remove logs files ? [y/n]: " -e LOGS
#		done
		# Stop Nginx
#		echo -ne "       Stopping Nginx                 [..]\r"
#		systemctl stop nginx
#		if [ $? -eq 0 ]; then
##			echo -ne "\n"
	#	else
	#		echo -e "       Stopping Nginx                 [${CRED}FAIL${CEND}]"
#			echo ""
#			echo "Please look at /tmp/nginx-autoinstall.log"
#			echo ""
#			exit 1
#		fi
		# Removing Nginx files and modules files
#		echo -ne "       Removing Nginx files           [..]\r"
#		rm -r /usr/local/src/nginx \
#		/usr/sbin/nginx* \
#		/etc/logrotate.d/nginx \
#		/var/cache/nginx \
#		/lib/systemd/system/nginx.service \
#		/etc/systemd/system/multi-user.target.wants/nginx.service >> /tmp/nginx-autoinstall.log 2>&1

#		echo -ne "       Removing Nginx files           [${CGREEN}OK${CEND}]\r"
#		echo -ne "\n"

		# Remove conf files
#		if [[ "$CONF" = 'y' ]]; then
#			echo -ne "       Removing configuration files   [..]\r"
##			echo -ne "       Removing configuration files   [${CGREEN}OK${CEND}]\r"
	#		echo -ne "\n"
	#	fi

		# Remove logs
#		if [[ "$LOGS" = 'y' ]]; then
#			echo -ne "       Removing log files             [..]\r"
#			rm -r /var/log/nginx >> /tmp/nginx-autoinstall.log 2>&1
#			echo -ne "       Removing log files             [${CGREEN}OK${CEND}]\r"
#			echo -ne "\n"
#		fi

#		if [[ $(lsb_release -si) == "Debian" ]] || [[ $(lsb_release -si) == "Ubuntu" ]]
#		then
#			echo -ne "       Unblock nginx package from APT [..]\r"
#			rm /etc/apt/preferences.d/nginx-block >> /tmp/nginx-autoinstall.log 2>&1
#			echo -ne "       Unblock nginx package from APT [${CGREEN}OK${CEND}]\r"
#			echo -ne "\n"
#		fi

		# We're done !
#		echo ""
#		echo -e "       ${CGREEN}Uninstallation successful !${CEND}"
#		echo ""
#		echo "       Installation log: /tmp/nginx-autoinstall.log"
#		echo ""

#	exit
#	;;
#	3) # Update the script
#		wget https://raw.githubusercontent.com/Angristan/nginx-autoinstall/master/nginx-autoinstall.sh -O nginx-autoinstall.sh >> /tmp/nginx-autoinstall.log 2>&1
#		chmod +x nginx-autoinstall.sh
#		echo ""
#		echo -e "${CGREEN}Update succcessful !${CEND}"
##		./nginx-autoinstall.sh
	#	exit
#	;;
#	4) # Exit
#		exit
#	;;

#esac
