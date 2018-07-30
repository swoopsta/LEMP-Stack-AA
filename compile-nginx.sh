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

# Variables - Check the URLs in the README for the most recent versions
NGINX_VER=1.15.2
NGINX_STABLE_VER=1.14.0
OPENSSL_VER=1.1.0h
HEADERMOD_VER=0.33
ZLIB_VER=1.2.11
NPS_VER=1.13.35.2

# Clear log file---------------------------------------------------------------
rm /tmp/nginx-compile.log
rm -rf /usr/local/src/nginx #debugging
clear
echo ""
echo "Welcome to the nginx-compile script."
echo ""
echo "What do you want to do?"
echo "   1) Install or update Nginx"
echo "   2) Uninstall Nginx"
echo "   3) Update the script"
echo "   4) Exit"
echo ""
while [[ $OPTION !=  "1" && $OPTION != "2" && $OPTION != "3" && $OPTION != "4" ]]; do
	read -p "Select an option [1-4]: " OPTION
done
case $OPTION in
	1)
		echo ""
		echo "This script will compile Nginx with optional modules"
		echo ""
		echo "Do you want to install Nginx stable or mainline?"
		echo "   1) Stable $NGINX_STABLE_VER"
		echo "   2) Mainline $NGINX_MAINLINE_VER"
		echo ""
		while [[ $NGINX_VER != "1" && $NGINX_VER != "2" ]]; do
			read -p "Select an option [1-2]: " NGINX_VER
		done
		case $NGINX_VER in
			1)
			NGINX_VER=$NGINX_STABLE_VER
			;;
			2)
			NGINX_VER=$NGINX_MAINLINE_VER
			;;
		esac
		echo ""
		echo "Please tell me which modules to install."
		echo "If you select none, Nginx will be installed with its default modules."
		echo ""
		echo "Modules to install :"
		while [[ $PAGESPEED != "y" && $PAGESPEED != "n" ]]; do
		read -p "       PageSpeed $NPS_VER [y/n]: " -e PAGESPEED
		done
		while [[ $BROTLI != "y" && $BROTLI != "n" ]]; do
			read -p "       Brotli [y/n]: " -e BROTLI
		done
		while [[ $HEADERMOD != "y" && $HEADERMOD != "n" ]]; do
			read -p "       Headers More $HEADERMOD_VER [y/n]: " -e HEADERMOD
		done
		while [[ $PCRE != "y" && $PCRE != "n" ]]; do
			read -p "       PCRE [y/n]: " -e PCRE
		done
		while [[ $ZLIB != "y" && $ZLIB != "n" ]]; do
			read -p "       zlib [y/n]: " -e ZLIB
		done
		while [[ $TCP != "y" && $TCP != "n" ]]; do
			read -p "       Cloudflare's TLS Dynamic Record Resizing patch [y/n]: " -e TCP
		done
		while [[ $CACHEPURGE != "y" && $CACHEPURGE != "n" ]]; do
			read -p "       ngx_cache_purge [y/n]: " -e CACHEPURGE
		done
		echo ""
		echo "Choose your OpenSSL implementation :"
		echo "   1) System's OpenSSL ($(openssl version | cut -c9-14))"
		echo "   2) OpenSSL $OPENSSL_VER from source"
		echo "   3) LibreSSL $LIBRESSL_VER from source "
		echo ""
		while [[ $SSL != "1" && $SSL != "2" && $SSL != "3" ]]; do
			read -p "Select an option [1-3]: " SSL
		done
		case $SSL in
		1)
		# Leave the installed version
		;;
		2)
			OPENSSL=y
		;;
		3)
			LIBRESSL=y
		;;
		esac
		echo ""
		read -n1 -r -p "Nginx is ready to be compiled, press any key to continue..."
		echo ""

		# Cleanup-----------------------------------------------------------------------
		# These directories & files should be deleted for debugging purposes
		rm -r /usr/local/src/nginx/ >> /tmp/nginx-compile.log 2>&1
		mkdir -p /usr/local/src/nginx/modules >> /tmp/nginx-compile.log 2>&1

		# Dependencies------------------------------------------------------------------
		clear
		echo -ne "    Installing and/or upgrading dependencies      [..]\r"
		apt update && apt upgrade -y >> /tmp/nginx-compile.log 2>&1
		apt install autotools-dev autoconf automake libtool build-essential checkinstall curl debhelper dh-systemd gcc git htop libbz2-dev libexpat-dev libgd2-noxpm-dev libgd2-xpm-dev libgeoip-dev libgoogle-perftools-dev libluajit-5.1-dev libmhash-dev libpam0g-dev libpcre3 libpcre3-dev libperl-dev libssl-dev libxslt1-dev make nano openssl po-debconf software-properties-common sudo tar unzip wget zlib1g zlib1g-dbg zlib1g-dev uuid-dev -y
		# Generate locales to compile with perl
		locale-gen en_US.UTF-8
		export LANG=en_US.UTF-8
		if [ $? -eq 0 ]; then
			echo -ne "     Installing and/or upgrading dependencies       [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "      Installing and/or upgrading dependencies      [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-compile.log"
			echo ""
			exit 1
		fi
		# PageSpeed---------------------------------------------------------------------
		if [[ "$PAGESPEED" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			# Download and extract of PageSpeed module
			echo -ne "       Downloading ngx_pagespeed      [..]\r"
			wget https://github.com/pagespeed/ngx_pagespeed/archive/v${NPS_VER}-stable.zip >> /tmp/nginx-compile.log 2>&1
			unzip v${NPS_VER}-stable.zip >> /tmp/nginx-compile.log 2>&1
			cd incubator-pagespeed-ngx-${NPS_VER}-stable
			psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_VER}.tar.gz
			[ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
			wget ${psol_url} >> /tmp/nginx-compile.log 2>&1
			tar -xzvf $(basename ${psol_url}) >> /tmp/nginx-compile.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading ngx_pagespeed      [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading ngx_pagespeed      [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-compile.log"
				echo ""
				exit 1
			fi
		fi

		#Brotli-------------------------------------------------------------------------
		if [[ "$BROTLI" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			echo -ne "       Downloading ngx_brotli         [..]\r"
			git clone https://github.com/eustas/ngx_brotli >> /tmp/nginx-compile.log 2>&1
			cd ngx_brotli
			git checkout v0.1.2 >> /tmp/nginx-compile.log 2>&1
			git submodule update --init >> /tmp/nginx-compile.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading ngx_brotli         [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading ngx_brotli         [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-compile.log"
				echo ""
				exit 1
			fi
		fi

		# More Headers------------------------------------------------------------------
		if [[ "$HEADERMOD" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			echo -ne "       Downloading ngx_headers_more   [..]\r"
			wget https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERMOD_VER}.tar.gz >> /tmp/nginx-compile.log 2>&1
			tar xaf v${HEADERMOD_VER}.tar.gz
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading ngx_headers_more   [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading ngx_headers_more   [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-compile.log"
				echo ""
				exit 1
			fi
		fi

		# PCRE-------------------------------------------------------------------------
		if [[ "$PCRE" = 'y' ]]; then
		cd /usr/local/src/nginx/modules
		echo -ne "       Downloading PCRE     [..]\r"
		wget https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VER}.tar.gz >> /tmp/nginx-compile.log 2>&1
		tar xzvf pcre-${PCRE_VER}.tar.gz
			if [ $? -eq 0 ]; then
			echo -ne "       Downloading PCRE      [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
			else
			echo -e "       Downloading PCRE      [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-compile.log"
			echo ""
			exit 1
			fi
		fi
	# Cache Purge------------------------------------------------------------------
		if [[ "$CACHEPURGE" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			echo -ne "       Downloading ngx_cache_purge    [..]\r"
			git clone https://github.com/FRiCKLE/ngx_cache_purge >> /tmp/nginx-compile.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading ngx_cache_purge    [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading ngx_cache_purge    [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-compile.log"
				echo ""
				exit 1
			fi
		fi
		# zlib--------------------------------------------------------------------------
		if [[ "$ZLIB" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			echo -ne "       Downloading zlib           [..]\r"
			wget http://www.zlib.net/zlib-${ZLIB_VER}.tar.gz >> /tmp/nginx-compile.log 2>&1
			tar xzvf zlib-${ZLIB_VER}.tar.gz
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading zlib           [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading zlib           [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-compile.log"
				echo ""
				exit 1
			fi
		fi
		# LibreSSL------------------------------------------------------------------
		if [[ "$LIBRESSL" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			mkdir libressl-${LIBRESSL_VER}
			cd libressl-${LIBRESSL_VER}
			# LibreSSL download
			echo -ne "       Downloading LibreSSL           [..]\r"
			wget -qO- http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VER}.tar.gz | tar xz --strip 1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading LibreSSL           [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading LibreSSL           [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-compile.log"
				echo ""
				exit 1
			fi
			echo -ne "       Configuring LibreSSL           [..]\r"
			./configure \
				LDFLAGS=-lrt \
				CFLAGS=-fstack-protector-strong \
				--prefix=/usr/local/src/nginx/modules/libressl-${LIBRESSL_VER}/.openssl/ \
				--enable-shared=no >> /tmp/nginx-compile.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Configuring LibreSSL           [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Configuring LibreSSL         [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-compile.log"
				echo ""
				exit 1
			fi
			# LibreSSL install
			echo -ne "       Installing LibreSSL            [..]\r"
			make install-strip -j $(nproc) >> /tmp/nginx-compile.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Installing LibreSSL            [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Installing LibreSSL            [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-compile.log"
				echo ""
				exit 1
			fi
		fi
# OpenSSL----------------------------------------------------------------------
		if [[ "$OPENSSL" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			echo -ne "       Downloading OpenSSL            [..]\r"
			wget https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz >> /tmp/nginx-compile.log 2>&1
			tar xaf openssl-${OPENSSL_VER}.tar.gz
			cd openssl-${OPENSSL_VER}
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading OpenSSL            [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading OpenSSL            [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-compile.log"
				echo ""
				exit 1
			fi
			echo -ne "       Configuring OpenSSL            [..]\r"
			./config >> /tmp/nginx-compile.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Configuring OpenSSL            [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Configuring OpenSSL          [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-compile.log"
				echo ""
				exit 1
			fi
		fi
		# Download and extract of Nginx source code-------------------------------------
		cd /usr/local/src/nginx/
		echo -ne "       Downloading Nginx              [..]\r"
		wget http://nginx.org/download/nginx-${NGINX_VER}.tar.gz
		tar -xzvf nginx-${NGINX_VER}.tar.gz
		cd nginx-${NGINX_VER}
		if [ $? -eq 0 ]; then
			echo -ne "       Downloading Nginx              [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Downloading Nginx              [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-compile.log"
			echo ""
			exit 1
		fi
		# Note:----------------------------------------------------------------------
		# As the default nginx.conf does not work
		# I'll download a clean and working conf from my GitHub.
		# I'll only do it only if it does not already exist (in case of update for instance)
		if [[ ! -e /etc/nginx/nginx.conf ]]; then
				mkdir -p /etc/nginx
				cd /etc/nginx
		wget https://raw.githubusercontent.com/swoopsta/LEMP-Stack-AA/master/conf/nginx.conf >> /tmp/nginx-compile.log 2>&1
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
		# Modified Configuration
		NGINX_MODULES="--without-http_ssi_module \
		--without-http_scgi_module \
		--without-http_uwsgi_module \
		--without-http_geo_module \
		--without-http_empty_gif_module \
		--without-http_browser_module \
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
		# LibreSSL
		if [[ "$LIBRESSL" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo --with-openssl=/usr/local/src/nginx/modules/libressl-${LIBRESSL_VER})
		fi

		# PCRE
		if [[ "$PCRE" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo --with-pcre=/usr/local/src/nginx/modules/pcre-${PCRE_VER})
		fi

		# PageSpeed
		if [[ "$PAGESPEED" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/incubator-pagespeed-ngx-${NPS_VER}-stable")
		fi

		# Brotli
		if [[ "$BROTLI" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/ngx_brotli")
		fi

		# More Headers
		if [[ "$HEADERMOD" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/headers-more-nginx-module-${HEADERMOD_VER}")
		fi

		# OpenSSL
		if [[ "$OPENSSL" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--with-openssl=/usr/local/src/nginx/modules/openssl-${OPENSSL_VER}")
		fi

		# Cache Purge
		if [[ "$CACHEPURGE" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/ngx_cache_purge")
		fi

		# Cloudflare's TLS Dynamic Record Resizing patch
		if [[ "$TCP" = 'y' ]]; then
			echo -ne "       TLS Dynamic Records support    [..]\r"
			wget https://raw.githubusercontent.com/cloudflare/sslconfig/master/patches/nginx__1.11.5_dynamic_tls_records.patch >> /tmp/nginx-compile.log 2>&1
			patch -p1 < nginx__1.11.5_dynamic_tls_records.patch >> /tmp/nginx-compile.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       TLS Dynamic Records support    [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       TLS Dynamic Records support    [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-compile.log"
				echo ""
				exit 1
			fi
		fi

		# Configure Nginx---------------------------------------------------------------
		echo -ne "       Configuring Nginx              [..]\r"
		./configure $NGINX_OPTIONS $NGINX_MODULES >> /tmp/nginx-compile.log 2>&1
		if [ $? -eq 0 ]; then
			echo -ne "       Configuring Nginx              [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Configuring Nginx              [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-compile.log"
			echo ""
			exit 1
		fi

		# Compile Nginx-----------------------------------------------------------------
		echo -ne "       Compiling Nginx                [..]\r"
		make -j $(nproc) >> /tmp/nginx-compile.log 2>&1
		if [ $? -eq 0 ]; then
			echo -ne "       Compiling Nginx                [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Compiling Nginx                [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-compile.log"
			echo ""
			exit 1
		fi

		# Let's build it now
		echo -ne "       Building Deb Package               [..]\r"
		checkinstall -y --pakdir=$HOME >> /tmp/nginx-compile.log 2>&1

		# remove debugging symbols
		strip -s /usr/sbin/nginx

		if [ $? -eq 0 ]; then
			echo -ne "       Building Nginx               [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Building Nginx               [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-compile.log"
			echo ""
			exit 1
		fi

		# Add an init script for systemd and logrotate
		# Using my systemd script and logrotate conf
		if [[ ! -e /lib/systemd/system/nginx.service ]]; then
			cd /lib/systemd/system/
			wget https://raw.githubusercontent.com/swoopsta/LEMP-Stack-AA/master/conf/nginx.service >> /tmp/nginx-compile.log 2>&1
			# Enable nginx start at boot
			systemctl enable nginx >> /tmp/nginx-compile.log 2>&1
		fi

		# Setup logrotate
		if [[ ! -e /etc/logrotate.d/nginx ]]; then
			cd /etc/logrotate.d/
			wget https://raw.githubusercontent.com/swoopsta/LEMP-Stack-AA/master/conf/nginx-logrotate -O nginx >> /tmp/nginx-compile.log 2>&1
		fi

		# Create Nginx cache directory
		if [[ ! -d /var/cache/nginx ]]; then
			mkdir -p /var/cache/nginx
		fi

		# Make sites directories per Nginx best practices
		if [[ ! -d /etc/nginx/sites-available ]]; then
			mkdir -p /etc/nginx/sites-available
		fi
		if [[ ! -d /etc/nginx/sites-enabled ]]; then
			mkdir -p /etc/nginx/sites-enabled
		fi

		# Restart Nginx
		echo -ne "       Restarting Nginx               [..]\r"
		systemctl restart nginx >> /tmp/nginx-compile.log 2>&1

		if [ $? -eq 0 ]; then
			echo -ne "       Restarting Nginx               [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Restarting Nginx               [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-compile.log"
			echo ""
			exit 1
		fi
		if [[ $(lsb_release -si) == "Debian" ]] || [[ $(lsb_release -si) == "Ubuntu" ]]
		then
			echo -ne "       Blocking nginx from APT        [..]\r"
			cd /etc/apt/preferences.d/
			echo -e "Package: nginx*\nPin: release *\nPin-Priority: -1" > nginx-block
			echo -ne "       Blocking nginx from APT        [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		fi
		# Removing temporary Nginx and modules files
		echo -ne "       Removing Nginx files           [..]\r"
		rm -r /usr/local/src/nginx >> /tmp/nginx-compile.log 2>&1
		echo -ne "       Removing Nginx files           [${CGREEN}OK${CEND}]\r"
		echo -ne "\n"
		# We're done !
		echo ""
		echo -e "       ${CGREEN}Installation successful !${CEND}"
		echo ""
		echo "       Installation log: /tmp/nginx-compile.log"
		echo ""
	exit
	;;
	2) # Uninstall Nginx
		while [[ $CONF !=  "y" && $CONF != "n" ]]; do
			read -p "       Remove configuration files ? [y/n]: " -e CONF
		done
		while [[ $LOGS !=  "y" && $LOGS != "n" ]]; do
			read -p "       Remove logs files ? [y/n]: " -e LOGS
		done
		# Stop Nginx
		echo -ne "       Stopping Nginx                 [..]\r"
		systemctl stop nginx
		if [ $? -eq 0 ]; then
			echo -ne "\n"
		else
			echo -e "       Stopping Nginx                 [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-compile.log"
			echo ""
			exit 1
		fi

		# Removing Nginx files and modules files
		echo -ne "       Removing Nginx files           [..]\r"
		rm -r /usr/local/src/nginx \
		/usr/sbin/nginx* \
		/etc/logrotate.d/nginx \
		/var/cache/nginx \
		/lib/systemd/system/nginx.service \
		/etc/systemd/system/multi-user.target.wants/nginx.service >> /tmp/nginx-compile.log 2>&1
		echo -ne "       Removing Nginx files           [${CGREEN}OK${CEND}]\r"
		echo -ne "\n"

		# Remove conf files
		if [[ "$CONF" = 'y' ]]; then
			echo -ne "       Removing configuration files   [..]\r"
			echo -ne "       Removing configuration files   [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		fi

		# Remove logs
		if [[ "$LOGS" = 'y' ]]; then
			echo -ne "       Removing log files             [..]\r"
			rm -r /var/log/nginx >> /tmp/nginx-compile.log 2>&1
			echo -ne "       Removing log files             [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		fi
		if [[ $(lsb_release -si) == "Debian" ]] || [[ $(lsb_release -si) == "Ubuntu" ]]
		then
			echo -ne "       Unblock nginx package from APT [..]\r"
			rm /etc/apt/preferences.d/nginx-block >> /tmp/nginx-compile.log 2>&1
			echo -ne "       Unblock nginx package from APT [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		fi
		# Finished
		echo ""
		echo -e "       ${CGREEN}Uninstallation successful !${CEND}"
		echo ""
		echo "       Installation log: /tmp/nginx-compile.log"
		echo ""
	exit
	;;
	3) # Update the script
		wget https://raw.githubusercontent.com/swoopsta/LEMP-Stack-AA/master/compile.sh -O compile.sh >> /tmp/nginx-compile.log 2>&1
		chmod +x compile.sh
		echo ""
		echo -e "${CGREEN}Update succcessful !${CEND}"
		./compile.sh
		exit
	;;
	4) # Exit
		exit
		;;
esac
