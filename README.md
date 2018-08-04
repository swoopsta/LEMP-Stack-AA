<p align="center">
<img src="https://www.adamayala.com/images/logo-100x100.png">
</p>

### **Nginx, PHP 7, MariaDB 10, FastCGI Cache, Brotli, HTTP2, PagespeedMod and CloudFlare For WordPress and other WebApps**

I wanted to build a customized LEMP stack that would work on a REALLY small VPS. 10gb/1gb RAM/1 VCPU & be able to handle 2000-3000 hits a day. It's more for a personal blog or resume. I also wanted a  LEMP Stack with customized compiled version of NGINX and custom configs (A constant work in progress) for the stack I use for all websites including WordPress. Using the latest versions of all available software. Development on a Google Compute Instance set to match most VPS's out there. All instructions are subject to change & are not guarantee to make your VPS explode. This repo assumes you are using a fresh install of Ubuntu 16.04 on a VPS. It also assumes you've taken steps to harden the install. I often check to see if the time zone is set correctly for timestamps. I also configure the locales (this is a must for anything compiled in Perl.) Following the instructions from your VPS provider is MUST DO. I'll have another repo soon to script this project for a staging environment once I've got this one tuned to my liking.

### **Initial Setup**

#### **GCC (Optional)**
I want to take advantage of a more up to date compiler than what Ubuntu might have available by default. This gives us access to CPU-specific optimizations as well as other security and performance improvements that will help Nginx during the compile process.

For this purpose-built server, we're I'm installing gcc-8 as it has significant performance optimizations for the Intel Skylake hardware that Google Compute instances use.

I've written a script to do this in case you don't want to do it manually.
```shell
wget https://raw.githubusercontent.com/swoopsta/Upgrading-GCC-on-Ubuntu-LTS--12.04--14.04--16.04/master/gcc-install.sh
chmod +x gcc-install.sh
sudo ./gcc-install.sh
```
Then test the version executed with the gcc command. You should see gcc version 8 is now as the default and an upgade will clean up.
```shell
gcc -v
apt update && apt upgrade -y
```
----------
### **Building Nginx**
I prefer using the **Mainline** version of Nginx rather than the **Stable** version. If you want the Stable version, you can choose it from the script.

I'm going to be compiling Nginx from source since I want to utilize some custom modules and use the latest version of LibreSSL or OpenSSL for HHTP2 support. This really depends on what the LEMP stack will be used for.

I've built a script to do the below so I need to download the latest versions of Nginx and the various Nginx modules I'm using. Before going any further, I'll want to check the links below to ensure that I'm downloading the latest version. Don't trust that the versions you see listed below are the latest releases. Make sure to change them in the compile-nginx.sh script in the variables section.

###### Nginx Server Software:
* [Nginx](http://nginx.org/en/download.html)
* [OpenSSL](https://www.openssl.org/source/)
* [LibreSSL](http://www.libressl.org/)
* [Headers More Module](https://github.com/openresty/headers-more-nginx-module/tags)
* [Nginx Cache Purge Module](http://labs.frickle.com/nginx_ngx_cache_purge/)
* [PCRE](https://ftp.pcre.org/pub/pcre/)
* [zlib](https://www.zlib.net/)
* [Google's PagespeedMod](https://github.com/pagespeed/ngx_pagespeed)
* [Brotli compression algorithm](https://github.com/eustas/ngx_brotli)
* [Cloudflares TLS Dynamic Records Resizing patch](https://github.com/cloudflare/sslconfig/blob/master/patches/nginx__1.11.5_dynamic_tls_records.patch)

###### Google's Brotli Compression & PagespeedMod
I'm using Brotli for compression. Brotli will take priority over gzip when enabled. CloudFlare supports Brotli so I'll take advantage of it. You can read more about Brotli at [https://github.com/google/brotli](https://github.com/google/brotli). I'm using a forked version that's more up to date. PagespeedMod is another Google project that I like to include because of it's flexibility.

###### Nginx Module Reference
Since we're compiling Nginx from source, we're going to be taking advantage of the fact that we can trim some default modules that I don't think I'll use to keep the footprint small and the RAM usage low. I'm constantly testing with Wordpress & Laravel so I want it as skinny as possible without using another fork. For your reference, we've included some helpful links that will get you up to speed on Nginx modules. If there's a module that you'd like to add to the Nginx build, you can add it to the compile-nginx.sh script.

* [Nginx: Default Modules](https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-open-source/#modules-built-by-default)
* [Nginx: Non-default Modules](https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-open-source/#modules_not_default)
* [Nginx: Third Party Modules](https://github.com/agile6v/awesome-nginx#third-modules)

##### Compiling Nginx
It's finally time to compile Nginx using the parts we've downloaded. If you're running version numbers that differ from the versions we had listed above, don't forget to change them inside the compile-nginx.sh script in the `Versions` section. The script is currently a work in progress. It will do its work in /usr/local/src/nginx/nginx-1.15.2 (version number).

Moving through the prompts, choose modules to include/exclude them from the package. To upgrade to the latest version, double check Nginx and module versions (as this document may not be up to date), then simply repeat the installation process above.

The script will install the SystemD service to handle bootup processing. If you feel the need to modify it use:
```
sudo nano /lib/systemd/system/nginx.service
```
In the future, you can restart Nginx by typing `sudo service nginx restart`.

Double check that we've got everything installed correctly by using the `nginx -Vv` command. This will also list all installed modules and your OpenSSL version.

----------

### **PHP 7**
I use PHP 7.2 so I'll have to install from Ondřej Surý's repository as the official Ubuntu repository does not have the most recent version. PHP 7.2 Does not have the mcrypt library in the repo. Some **WordPress** themes and plugins still use mcrypt. If you need it I suggest the following how-to: [Stack Overflow: Issue in installing php7.2-mcrypt](https://stackoverflow.com/questions/48275494/issue-in-installing-php7-2-mcrypt)
```
sudo add-apt-repository ppa:ondrej/php
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C
sudo apt update && sudo apt upgrade
sudo apt install php7.2 php7.2-fpm php7.2-mysql php7.2-gd php7.2-cli php7.2-xml php7.2-mbstring php7.2-soap php7.2-curl php7.2-opcache php-pear php7.2-common php-imagick php7.2-intl php7.2-json php7.2-readline php7.2-tidy php7.2-xmlrpc php7.2-xsl php7.2-zip
```
##### **Configuring PHP.ini**

With PHP 7.2 installed, I'm going to make some changes to  the **php.ini** config. Our goal here is to raise the timeouts and max file sizes for the site. In addition, you'll want to pay close attention to the `memory_limit` setting and set it accordingly. If you're not sure, `256M` is a very safe value.
```
sudo nano /etc/php/7.2/fpm/php.ini
```
Locate the settings below and change their values to reflect the higher values listed. You may need to adjust the values for your specific site.
```shell
user_ini.filename = # 173 Prevents overrides
max_execution_time = 120 # line 383
max_input_time = 120 # line 393
max_input_vars = 5000 # line 400
memory_limit = 256M # line 404
post_max_size = 64M # line 672
upload_max_filesize = 64M # line 825
date.timezone = America/Chicago # line 939 proper timestamps in OPCache
```
#### **PHP-FPM**
The changes we make for PHP-FPM are always going to be up to how many hits the site will take and the stability of the PHP-FPM daemon. There are several discussions on how best to tweak the ```/etc/php/7.2/fpm/pool.d/www.conf``` file. I find that there is a sweet spot on differing setups. I'll be working on keeping things running with a minimal hit on ram. The key here is whether or not to spawn children dynamically or on demand. My config works for me in low memory environments on SSDs. That said I'll change ```/etc/php/7.2/fpm/pool.d/www.conf``` with the following values. Make sure within the config the user is set to www-data in my current setup. Starting at about line 141 there's useful documentation about setting up a slow log for debugging purposes. If you're a geek tweaker like me you might take a try at turning these settings on to see exactly what PHP-FPM is doing.

``` shell
user = www-data #line 23
group = www-data #line 24
listen.owner = www-data # line 50
listen.group = www-data # line 51
pm = ondemand # line 102
pm.max_children = 50 # line 113
;pm.start_servers = 2 # line 118
;pm.min_spare_servers = 1 # line 123
;pm.max_spare_servers = 3 # line 128
pm.process_idle_timeout = 10s; #line 133
pm.max_requests = 500 # line 139
```
##### **PHP-FPM.CONF**
Per the great guide at [TweakedIO](http://www.tweaked.io/guide/nginx/) I like to change the php-fpm.conf to globally set PHP-FPM to restart upon random failure. I don't do this until I've debugged and examined/tested every setting. Open up ```/etc/php/7.2/fpm/php-fpm.conf```.
```shell
emergency_restart_threshold = 10 # line 48
emergency_restart_interval = 1m # line 56
process_control_timeout = 10s # line 62
```
Before we make other changes to PHP I always check to see if the basic configuration is good.
```shell
php-fpm7.2 -t
```
Hopefully you'll see the following. If not, wash, rinse repeat.
```shell
[04-Aug-2018 14:07:38] NOTICE: configuration file /etc/php/7.2/fpm/php-fpm.conf test is successful
```
##### **OPcache**
We're going to utilize OPcache to greatly increase the performance of PHP. Since OPcache stores scripts in memory, however, the needs of your site could greatly differ from the next person's site. To learn more about tuning OPCache for your specific needs, read [Fine-Tune Your Opcache Configuration to Avoid Caching Suprises](https://tideways.io/profiler/blog/fine-tune-your-opcache-configuration-to-avoid-caching-suprises). You can more learn about every available OPcache setting by visiting [PHP.net](http://php.net/manual/en/opcache.configuration.php.). We also want to follow best practices for [WordPress setups](https://github.com/ataylorme/WordPress-Hosting-Best-Practices-Documentation/blob/master/security/security.md#opcache-security). There are also some great tools to to monitor OPcache on GitHub.
* [A one-page opcache status page by rlerdorf](https://github.com/rlerdorf/opcache-status)
* [A clean, effective and responsive interface for Zend OPcache by amnuts](https://github.com/amnuts/opcache-gui)
* [GUI for PHP's OpCache by PeeHaa (my personal favorite)](https://github.com/PeeHaa/OpCacheGUI)

This is where I'll stray from most LEMP tutorials. You can make these changes in ```php.ini``` but since our modified PHP configuration is working I'll stay out of any PHP configs and work on the OPcache Module configs. Drop into ```/etc/php/7.2/mods-available``` and create a file named ```custom-opcache.ini```. Add the following:
```
opcache.validate_permission = On
opcache.validate_root = On
opcache.restrict_api = '/home'
opcache.memory_consumption=128
opcache.max_accelerated_files=8000 ; find this value by running find project/ -iname *.php|wc -l
opcache.enable_cli=1
opcache.validate_timestamps=0
; logs
opcache.error_log='/var/log/opcache.log'
opcache.log_verbosity_level=2
```
I'll symlink this config to the proper directories.
```shell
ln -s /etc/php/7.2/mods-available/custom-opcache.ini /etc/php/7.2/fpm/conf.d/99-custom-opcache.ini
ln -s /etc/php/7.2/mods-available/custom-opcache.ini /etc/php/7.2/cli/conf.d/99-custom-opcache.ini
```
Restart PHP and we're done.
```
sudo service php7.2-fpm restart
```
----------

### **MariaDB 10**
I'm using MariaDB instead of MySQL, as the performance is great with WordPress & it's more "open" and I'm an open source fanboy. I'm running the **Stable** release of MariaDB. You can find the latest version at [https://downloads.mariadb.org/](https://downloads.mariadb.org/).

##### **Add MariaDB Repo**
```shell
sudo curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
```
##### **Installing MariaDB**
```shell
sudo apt install mariadb-server-10.3
```
During the installation you will be prompted for a administrator (root) password. Key one in AND SAVE IT IN A SAFE PLACE. Before we start working with/on the database I start working on configuring it for my environment. It's a little tricky here since we don't have any data yet and a metric to measure as far as usage and size. I've gone through a several setups in my local lab using LXC containers and I've found a good starting point. Stop MariaDB.
```
systemctl stop mariadb.service
```
Jump into ```/etc/mysql/conf.d``` and create a file named ```custom-vps.cnf```. Add the following. I like to use versioning so I can keep backups of configs while testing.
```
# Version 1.0

[mysqld]
symbolic-links=0
skip-external-locking
key_buffer_size = 32K
max_allowed_packet = 4M
table_open_cache = 8
sort_buffer_size = 128K
read_buffer_size = 512K
read_rnd_buffer_size = 512K
net_buffer_length = 4K
thread_stack = 480K
innodb_file_per_table
max_connections=100
max_user_connections=50
wait_timeout=50
interactive_timeout=50
long_query_time=5
```
I start MariaDB back up and check to see if my configurations are enabled.
```
systemctl start mariadb.service
mysqld --verbose --help
```
##### **Optional-Tuning**
I've automated the building of this stack, but I recently started using [MySQLTuner-perl](https://github.com/major/MySQltuner-perl/) because of it's ease of use and security checks. It's an excellent project that's well maintained and it's a permanent part of my Dev/Ops toolkit. I tend to run it every time I login to one of my VPS's, and it's a part of Vagrant/DB setups.

##### **Securing MariaDB**
MariaDB includes a script that will perform some basic cleanup and security settings.
```
sudo mysql_secure_installation
```
##### **Log in to MariaDB**
Test to make sure things are working by logging into MySQL, then exiting.
```
sudo mysql -v -u root -p
```
You can exit MariaDB by typing `exit`.
