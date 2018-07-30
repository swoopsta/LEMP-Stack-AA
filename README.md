<p align="center">
<img src="https://www.adamayala.com/images/logo-100x100.png">
</p>
### **Nginx, PHP 7, MariaDB 10, FastCGI Cache, Brotli, HTTP2, PagespeedMod and CloudFlare For WordPress and other WebApps**

A LEMP Stack with customized compiled version of NGINX and custom configs (A constant work in progress) for the stack I use for all websites including WordPress. Using the latest versions of all available software. Development is in an LXC container on my home lab but the end product will but put on a Google Compute Instance so all instructions are subject to change. This repo assumes you are using a fresh install of Ubuntu 16.04 on a VPS. It also assumes you've taken steps to harden the install. I often check to see if the time zone is set correctly for timestamps. I also configure the locales (this is a must for anything compiled in Perl.) Following the instructions from your VPS provider is MUST DO.

#### **Initial Setup**

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

I've built a script to do the below so I need to download the latest versions of Nginx and the various Nginx modules I'm using. Before going any further, I'll want to check the links below to ensure that I'm downloading the latest version. Don't trust that the versions you see listed below are the latest releases. Make sure to change them in the compile.sh script in the variables section.

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
Since we're compiling Nginx from source, we're going to be taking advantage of the fact that we can trim some default modules that I don't think I'll use. For your reference, we've included some helpful links that will get you up to speed on Nginx modules. If there's a module that you'd like to add to the Nginx build, you can add it to the compile.sh script.

* [Nginx: Default Modules](https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-open-source/#modules-built-by-default)
* [Nginx: Non-default Modules](https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-open-source/#modules_not_default)
* [Nginx: Third Party Modules](https://github.com/agile6v/awesome-nginx#third-modules)

##### Compiling Nginx
It's finally time to compile Nginx using the parts we've downloaded. If you're running version numbers that differ from the versions we had listed above, don't forget to change them inside the compile.sh script in the Variables section. The script is currently a work in progress. It will do its work in /usr/local/src/nginx/nginx-1.15.2 (version number).

I like using `checkinstall` command rather than make. It tells the server to package our compiled source into a more easily managed .deb package file. Moving through the prompts, you can tell it not to list the installation files, and yes to exclude them from the package. Since Nginx updates quite frequently, doing this allows us to easily upgrade later on. To upgrade to the latest version, double check Nginx and module versions (as this document may not be up to date), then simply repeat the installation process above. Restart Nginx and you should be running the latest version.

The script will install the SystemD service to handle bootup processing. If you feel the need to modify it use:
```
sudo nano /lib/systemd/system/nginx.service
```
In the future, you can restart Nginx by typing `sudo service nginx restart`.

Double check that we've got everything installed correctly by using the `nginx -Vv` command. This will also list all installed modules and your OpenSSL version.

##### **Creating Directories and Setting Permissions**
Here we're going to ensure that the right folders are in place for our config.
```
sudo mkdir -p /var/www/html
sudo mkdir -p /var/lib/nginx/fastcgi
sudo mkdir -p /etc/nginx/ssl
sudo mkdir -p /etc/nginx/conf.d
sudo mkdir -p /var/cache/nginx
sudo mkdir -p /var/log/domains
sudo chown -hR www-data:www-data /var/log/domains
```
----------

### **PHP 7**
With Nginx out of the way, it's time to install PHP 7.2. We're going to be using Ondřej Surý's repository for this, as the official Ubuntu repository does not have what we're looking for.
```
sudo add-apt-repository ppa:ondrej/php
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C
sudo apt update && sudo apt upgrade
sudo apt install php7.2 php7.2-cli php7.2-common php7.2-curl php7.2-fpm php7.2-gd php-imagick php7.2-intl php7.2-json php7.2-mbstring php7.2-mysql php7.2-opcache php-pear php7.2-readline php7.2-soap php7.2-tidy php7.2-xml php7.2-xmlrpc php7.2-xsl php7.2-zip
```
##### **Configuring PHP.ini**

With PHP 7.2 installed, we'll want to make some changes to the **php.ini** configuration file. Our goal here is to raise the timeouts and max file sizes for the site. In addition, you'll want to pay close attention to the `memory_limit` setting and set it accordingly. If you're not sure, `256M` is a very safe value.
```
sudo nano /etc/php/7.2/fpm/php.ini
```
Locate the settings below and change their values to reflect the higher values listed. You may need to adjust the values for your specific site.
```
upload_max_filesize = 32M
post_max_size = 32M
memory_limit = 256M
max_execution_time = 120
max_input_vars = 10000
max_input_time = 120
```
Keep **php.ini** open since we'll still need it in the next section below.

##### **OPcache**
We're going to utilize OPcache to greatly increase the performance of PHP. Since OPcache stores scripts in memory, however, the needs of your site could greatly differ from the next person's site. To learn more about tuning OPCache for your specific needs, read [Fine-Tune Your Opcache Configuration to Avoid Caching Suprises](https://tideways.io/profiler/blog/fine-tune-your-opcache-configuration-to-avoid-caching-suprises). You can more learn about every available OPcache setting by visiting [PHP.net](http://php.net/manual/en/opcache.configuration.php.).

Still editing **php.ini**, look for the lines below. Remember that you'll need to uncomment the lines by removing the `;`.
```
opcache.enable = 1
opcache.enable_cli = 1
opcache.interned_strings_buffer = 16
opcache.max_accelerated_files = 10000
opcache.memory_consumption = 128
opcache.revalidate_freq = 300
opcache.save_comments = 0
```
Restart PHP and we're done.
```
sudo service php7.2-fpm restart
```
----------

### **MariaDB 10**
We're using MariaDB instead of MySQL, as the performance is great with WordPress. We're running the **Stable** release of MariaDB. You can find the latest version at [https://downloads.mariadb.org/](https://downloads.mariadb.org/).

##### **Add MariaDB Repo**
```
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu xenial main'
```
##### **Installing MariaDB**
At the end of this installation, MariaDB will ask you to set your password. Don't lose this!
```
sudo apt update && sudo apt install mariadb-server -y
```
Make sure that MariaDB has upgraded to the latest release by running this again.
```
sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y
```
##### **Securing MariaDB**
MariaDB includes some test users and databases that we don't want to be using in a live production environment. Now that MariaDB is installed, run this command. Since we've already set the admin password, we can hit `N` to the first option. You'll want to hit `Y` to the rest of the questions.
```
sudo mysql_secure_installation
```
##### **Log in to MariaDB**
Test to make sure things are working by logging into MySQL, then exiting.
```
sudo mysql -v -u root -p
```
You can exit MariaDB by typing `exit`.

----------

### **Making Things Work**
We're going to take a moment to move some files and verify that things are working.

#### **.conf Files**
Now it's time to move [nginx.conf](https://raw.githubusercontent.com/VisiStruct/LEMP-Server-Xenial-16.04/master/nginx.conf), [wpsecurity.conf](https://raw.githubusercontent.com/VisiStruct/LEMP-Server-Xenial-16.04/master/wpsecurity.conf), and [fileheaders.conf](https://raw.githubusercontent.com/VisiStruct/LEMP-Server-Xenial-16.04/master/fileheaders.conf) into **/etc/nginx**.
```
sudo wget https://raw.githubusercontent.com/VisiStruct/LEMP-Server-Xenial-16.04/master/nginx.conf -O /etc/nginx/nginx.conf
sudo wget https://raw.githubusercontent.com/VisiStruct/LEMP-Server-Xenial-16.04/master/wpsecurity.conf -O /etc/nginx/wpsecurity.conf
sudo wget https://raw.githubusercontent.com/VisiStruct/LEMP-Server-Xenial-16.04/master/fileheaders.conf -O /etc/nginx/fileheaders.conf
```
You'll also want to move [default.conf](https://raw.githubusercontent.com/VisiStruct/LEMP-Server-Xenial-16.04/master/conf.d/default.conf "/etc/nginx/conf.d/default.conf") into **/etc/nginx/conf.d**.
```
sudo wget https://raw.githubusercontent.com/VisiStruct/LEMP-Server-Xenial-16.04/master/conf.d/default.conf -O /etc/nginx/conf.d/default.conf
```
Then restart PHP and Nginx.
```
sudo service nginx restart && sudo service php7.2-fpm restart
```
#### **Get Your PHP Installation Info**
Now we're going to write a very basic php file that will display the information related to our PHP installation. This lets us verify that PHP 7 is working correctly. In addition, you can use this to reference your server's PHP configuration settings in the future. We're going to send it straight to your server's default folder, which will be **/var/www/html**. By contrast, domains will be using **/var/www/yourdomain.com/html**.
```
sudo echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php
```

Point your browser to http://ipa.ddr.ess/phpinfo.php.

----------

### **phpMyAdmin**
Since phpMyAdmin is already available through the default Ubuntu 16.04 repos, this part is really easy. We're pointing our phpMyAdmin location to **/var/www/html**, which will make it available at your server's IP address. Alter the lines below to reflect a different location, such as a behind a domain.
```
sudo apt install phpmyadmin -y
sudo update-rc.d -f apache2 remove
sudo ln -s /usr/share/phpmyadmin /var/www/html
```
Point your browser to http://ipa.ddr.ess/phpmyadmin.

----------

### **WordPress**
From this point on in the tutorial, any time you see `yourdomain.com` you'll want to alter that text to whatever your domain actually is.

##### **Creating a MySQL Database**
We're going to create the database by command line because we're cool. You can also do this directly though phpMyAdmin if you're not as cool. Replace the `database`, `user`, and `password` variables in the code below.
```
sudo mysql -u root -p
CREATE DATABASE database;
CREATE USER 'user'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON database.* TO 'user'@'localhost';
FLUSH PRIVILEGES;
exit
```
##### **Install WordPress**
We're going to create a few directories needed for WordPress, set the permissions, and download WordPress. We're also going to just remove the Hello Dolly plugin, because obviously.
```
sudo mkdir -p /var/www/yourdomain.com/html						
cd /var/www/yourdomain.com/html
sudo wget http://wordpress.org/latest.tar.gz
sudo tar -xzvf latest.tar.gz
sudo mv wordpress/* .
sudo rmdir /var/www/yourdomain.com/html/wordpress
sudo rm -f /var/www/yourdomain.com/html/wp-content/plugins/hello.php
sudo mkdir -p /var/www/yourdomain.com/html/wp-content/uploads
```
If you're transferring a site over, it's time to upload any files you might have (themes, plugins, uploads, etc, wp-config, etc). You'll want to do this before assigning permissions to the directories. If not, proceed to the next step.

##### **Secure WordPress**
Once you're done uploading files, we'll want to secure WordPress' directory and file permissions.
```
sudo find /var/www/yourdomain.com/html/ -type d -exec chmod 755 {} \;
sudo find /var/www/yourdomain.com/html/ -type f -exec chmod 644 {} \;
sudo chown -hR www-data:www-data /var/www/yourdomain.com/html/
```
##### **Install Nginx Site File**
Now that we've got the directory structure of your domain squared away, we'll need to enable it in Nginx.

Add [yourdomain.com.conf](https://raw.githubusercontent.com/VisiStruct/LEMP-Server-Xenial-16.04/master/conf.d/yourdomain.com.conf) to **/etc/nginx/conf.d**. This folder may hold as many virtual domains as you'd like, just make a new file with a different name for each domain you want to host. Once that is done, edit the contents of the file to change all instances of `yourdomain.com` to your actual domain name.
```
sudo wget https://raw.githubusercontent.com/VisiStruct/LEMP-Server-Xenial-16.04/master/conf.d/yourdomain.com.conf -O /etc/nginx/conf.d/yourdomain.com.conf
sudo nano /etc/nginx/conf.d/yourdomain.com.conf
```
----------

### **Self-Signed SSL Certificate**
Now we're going to generate a self-signed SSL certificate. Since we're using CloudFlare anyway, we're going to use a *FREE* SSL certificate through them. You'll need to set CloudFlare's SSL certificate status to `Full` for this to work.
```
sudo openssl req -x509 -nodes -days 365000 -newkey rsa:2048 -keyout /etc/nginx/ssl/yourdomain.com.key -out /etc/nginx/ssl/yourdomain.com.crt
cd /etc/nginx/ssl
sudo openssl dhparam -out yourdomain.com.pem 2048
sudo service nginx restart && sudo service php7.2-fpm restart
```
----------

### **FastCGI Cache Conditional Purging**

You'll want a way to purge the cache when you make changes to the site, such as editing a post, changing a menu, or deleting a comment.

##### **Nginx Cache WordPress Plugin**

We like RTCamp's Nginx Helper Plugin. You'll want to go to the WordPress Dashboard, then Settings/ Nginx Helper. Turn on purging, and select the conditions you want to trigger the purge. Finally, select the timestamp option at the bottom to display your page's build time in the source code.

Download: [Nginx Helper](https://wordpress.org/plugins/nginx-helper/)

----------

### **Checking FastCGI Cache**
It's always a good idea to make sure that what you think is working is in fact actually working. Since we don't want to serve cached versions of every page on the site, inside [yourdomain.com.conf](https://raw.githubusercontent.com/VisiStruct/LEMP-Server-Xenial-16.04/master/conf.d/yourdomain.com.conf), we've added rules that prevent certain pages from being cached. To help shed light on things a bit, we've added the line `add_header X-Cached $upstream_cache_status;`. This will tell us with certainty whether or not the page being served is the cached version.

We can check the status of any page by viewing the headers that are sent along when you visit it. To do this, you can use a variety of methods. You can use the `CURL` command inside your terminal by typing `curl -I https://yourdomain.com`. Extensions exist for Firefox and Chrome that will make things a bit easier. We prefer the [HTTP Headers](https://chrome.google.com/webstore/detail/http-headers/nioieekamcpjfleokdcdifpmclkohddp "HTTP Headers for Google Chrome") Chrome extension.

You'll encounter 4 different messages based on the cache type. `X-Cached: HIT`, `X-Cached: MISS`, `X-Cached: EXPIRED`, or `X-Cached: BYPASS`.

###### X-Cached: HIT
You're being served a cached version of the page.

###### X-Cached: MISS
The server did not have a cached copy of that page, so you're being fed a live version instead. Initially all pages will show as `X-Cached: MISS`. Once they've been visited, Nginx will store a copy of that code for future visitors.

###### X-Cached: EXPIRED
The version that was stored on the server is too old, and you're seeing a live version instead.

###### X-Cached: BYPASS
We've told Nginx skip caching a page if it matches a set of criteria. For example, we don't want to cache any page beginning with `WP-`, or any page visited by a logged in user or recent commenter. Depending on the nature of your site, there may be additional things you'll want to set to avoid being cached.

----------

### **Final Thoughts**

The common theme when designing this server config is *complex simplicity*. Throughout the build, we've utilized cool, performance enhancing features like OPcache and Nginx FastCGI Cache, all while keeping things clean and running smoothly. However, we've intentionally left out some of the more complex Nginx performance features related to how it handles threads.

If you're ready to take your Nginx performance to the next level, we'd highly recommend viewing [this guide on Nginx performance](https://www.nginx.com/blog/thread-pools-boost-performance-9x/). Happy reading!

----------

### **Done!**
*Naturally, this tutorial is always subject to change, and could include mistakes or vulnerabilities that might result in damage to your site by malicious parties. We make no guarantee of the performance, and encourage you to read and thoroughly understand each setting and command before you enable it on a live production site.*

If we've helped you, or you've given up and want to hire a consultant to set this up for you, visit us at **[VisiStruct.com](https://VisiStruct.com "VisiStruct.com")**.
