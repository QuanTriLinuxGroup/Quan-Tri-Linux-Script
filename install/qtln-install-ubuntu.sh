#!/bin/bash

# Install neccessary packages
# Version: 0.1

#----------------------------------------------------------#
#                  Variables&Functions                     #
#----------------------------------------------------------#

memory=$(grep 'MemTotal' /proc/meminfo |tr ' ' '\n' |grep [0-9])
arch=$(uname -i)
os='ubuntu'
release="$(lsb_release -s -r)"
codename="$(lsb_release -s -c)"
VERSION='ubuntu'
QTLINUX='/usr/local/qtlinux'

# Defining software pack for all distros
software="nginx apache2 apache2.2-common apache2-suexec-custom apache2-utils
    apparmor-utils awstats bc  bsdmainutils bsdutils clamav-daemon
    cron curl dnsutils dovecot-imapd dovecot-pop3d e2fslibs e2fsprogs exim4
    exim4-daemon-heavy expect flex ftp git idn imagemagick
    libapache2-mod-fcgid libapache2-mod-php libapache2-mod-rpaf
    libapache2-mod-ruid2 lsof mc mysql-client mysql-common mysql-server
    ntpdate php-cgi php-common php-curl php-fpm php-mysql
    spamassassin sudo vim-common vsftpd webalizer whois zip net-tools"

# bind9 roundcube-core roundcube-mysql roundcube-plugins 

# Fix for old releases
if [[ ${release:0:2} -lt 16 ]]; then
    software=$(echo "$software" |sed -e "s/php /php5 /g")
    software=$(echo "$software" |sed -e "s/php-/php5-/g")
fi

help() {
    echo "Usage: $0 [OPTIONS]
    -a, --apache            Install Apache          [yes|no]    default: yes
    -n, --nginx             Install Nginx           [yes|no]    default: yes
    -v, --vsftpd            Install vsftpd          [yes|no]    default: no
    -m, --mysql             Install MySQL           [yes|no]    default: yes
    -w, --phpfpm            Install PHP-FPM         [yes|no]    default: no
    -z, --phpmyadmin        Install phpMyAdmin      [yes|no]    default: no
    -e, --exim              Install Exim            [yes|no]    default: no
    -d, --dovecot           Install Dovecot         [yes|no]    default: no
    -l, --clamav            Install ClamAV          [yes|no]    default: no
    -s, --spamassassin      Install SpamAssassin    [yes|no]    default: no
    -c, --csf               Install CSF             [yes|no]    default: yes
    -i, --interactive       Interactive Install     [yes|no]    defautl: no

    Example: 
        # Interactive install
        bash $0 -y

        # Install PHP-FPM
        bash $0 --php-fpm yes

        # Install email services
        bash $0 --exim yes --dovecot yes --clamav yes --spamassassin yes
"
    exit 1
}

# function to set default value for variable
set_default_value() {
    eval variable=\$$1
    if [[ -z "$variable" ]]; then
        eval $1=$2
    fi

    if [[ "$variable" != "yes" ]] && [[ $variable != "no" ]]; then
        eval $1=$2
    fi
}

check_result() {
    if [[ $1 -ne 0 ]]; then
        echo "Error: $2"
        exit $1
    fi
}

gen_pass() {
    password=$(cat /dev/urandom | tr -dc 'A-Za-z0-9@$%^*-=,.' | head -c 16)
    echo "$password"
}

#-------------------------------------------------#
#                   Verification                  #
#-------------------------------------------------#

# translate long option to short option to compatible with getopts

args=""
for arg in "$@"; do
    case $arg in
        --apache)           args="${args}-a " ;;
        --nginx)            args="${args}-n " ;;
        --vsftpd)           args="${args}-v " ;;
        --mysql)            args="${args}-m " ;;
        --phpfpm)           args="${args}-w " ;;
        --phpmyadmin)       args="${args}-z " ;;
        --exim)             args="${args}-e " ;;
        --dovecot)          args="${args}-d " ;;
        --clamav)           args="${args}-l " ;;
        --spamassassin)     args="${args}-s " ;;
        --csf)              args="${args}-c " ;;
        --interactive)      args="${args}-i " ;;
        *)                  args="${args}${arg} " ;;
    esac
done

# evaluate $args into positional argument to use with getops
eval set -- "$args"

# parse arguments
while getopts "a:n:v:m:w:z:e:d:l:s:c:i:" option; do
    case $option in
        a)  apache=$OPTARG ;;
        n)  nginx=$OPTARG ;;
        v)  vsftpd=$OPTARG ;;
        m)  mysql=$OPTARG ;;
        w)  phpfpm=$OPTARG ;;
        z)  phpmyadmin=$OPTARG ;;
        e)  exim=$OPTARG ;;
        d)  dovecot=$OPTARG ;;
        l)  clamav=$OPTARG ;;
        s)  spamassassin=$OPTARG ;;
        c)  csf=$OPTARG ;;
        i)  interactive=$OPTARG ;;
        h)  help ;;
        *)  help ;;
    esac
done

# set default value for software stack
set_default_value 'apache'  'yes'
set_default_value 'nginx'   'yes'
set_default_value 'vsftpd'  'no'
set_default_value 'mysql'   'yes'
set_default_value 'phpfpm'  'no'
set_default_value 'phpmyadmin' 'no'
set_default_value 'exim'    'no'
set_default_value 'dovecot' 'no'
set_default_value 'clamav'  'no'
set_default_value 'spamassassin''no'
set_default_value 'csf'     'yes'
set_default_value 'interactive' 'no'

# check software conflict
if [[ "$exim" == "no" ]]; then
    dovecot="no"
    clamav="no"
    spamassassin="no"
fi

# confirm script is running with root user
if [[ "x$(id -u)" != "x0" ]]; then
    check_result 1 "Script can be run executed only by root"
fi

# check installed packet
tmpfile=$(mktemp -p /tmp)
dpkg --get-selections > $tmpfile

for pkg in mysql-server apache2 nginx; do
    if [[ ! -z "$(grep $pkg $tmpfile)" ]]; then
        conflicts="$pkg $conflicts"
    fi
done
rm -f $tmpfile

# if [[ ! -z "$conflicts" ]]; then
#     echo
#     echo "#----------------------------------------#"
#     echo "Following packages are already installed"
#     echo "$conflicts"
#     echo "Please remove it before install"
#     echo "#----------------------------------------#"
#     echo
#     check_result 1 "Script should run install on clean server"
# fi

#-------------------------------------------------#
#                   Brief Info                    #
#-------------------------------------------------#

# Printing nice ASCII logo
clear
echo 'Quản Trị Linux Script'
echo -e "\n\n"

echo 'The following software will be installed on your system:'

# Web stack
if [ "$nginx" = 'yes' ]; then
    echo '   - Nginx Web Server'
fi
if [ "$apache" = 'yes' ] && [ "$nginx" = 'no' ] ; then
    echo '   - Apache Web Server'
fi
if [ "$apache" = 'yes' ] && [ "$nginx"  = 'yes' ] ; then
    echo '   - Reverse Proxy (as backend)'
fi
if [ "$phpfpm"  = 'yes' ]; then
    echo '   - PHP-FPM Application Server'
fi


# Mail stack
if [ "$exim" = 'yes' ]; then
    echo -n '   - Exim Mail Server'
    if [ "$clamd" = 'yes'  ] ||  [ "$spamassassin" = 'yes' ] ; then
        echo -n ' + '
        if [ "$clamd" = 'yes' ]; then
            echo -n 'ClamAV'
        fi
        if [ "$spamassassin" = 'yes' ]; then
            echo -n 'SpamAssassin'
        fi
    fi
    echo
    if [ "$dovecot" = 'yes' ]; then
        echo '   - Dovecot POP3/IMAP Server'
    fi
fi

# Database stack
if [ "$mysql" = 'yes' ]; then
    echo '   - MySQL Database Server'
fi

# FTP stack
if [ "$vsftpd" = 'yes' ]; then
    echo '   - Vsftpd FTP Server'
fi

# Firewall stack
if [ "$csf" = 'yes' ]; then
    echo -n '   - CSF Firewall'
fi
echo -e "\n\n"

# Asking for confirmation to proceed
if [ "$interactive" = 'yes' ]; then
    read -p 'Would you like to continue [y/n]: ' answer
    if [ "$answer" != 'y' ] && [ "$answer" != 'Y'  ]; then
        echo 'Goodbye'
        exit 1
    fi

    # Asking to set FQDN hostname
    if [ -z "$servername" ]; then
        read -p "Please enter FQDN hostname [$(hostname -f)]: " servername
    fi
fi

# Set hostname if it wasn't set
if [ -z "$servername" ]; then
    servername=$(hostname -f)
fi

# Set FQDN if it wasn't set
mask1='(([[:alnum:]](-?[[:alnum:]])*)\.)'
mask2='*[[:alnum:]](-?[[:alnum:]])+\.[[:alnum:]]{2,}'
if ! [[ "$servername" =~ ^${mask1}${mask2}$ ]]; then
    if [ ! -z "$servername" ]; then
        servername="$servername.example.com"
    else
        servername="example.com"
    fi
    echo "127.0.0.1 $servername" >> /etc/hosts
fi


# Defining backup directory
qtlinux_backups="/root/qtlinux_install_backups/$(date +%s)"
echo "Installation backup directory: $qtlinux_backups"

# Printing start message and sleeping for 5 seconds
echo -e "\n\n\n\nInstallation will take about 15 minutes ...\n"
sleep 5


#----------------------------------------------------------#
#                      Checking swap                       #
#----------------------------------------------------------#

# Checking swap on small instances
if [ -z "$(swapon -s)" ] && [ $memory -lt 1000000 ]; then
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile   none    swap    sw    0   0" >> /etc/fstab
fi


#----------------------------------------------------------#
#                   Install repository                     #
#----------------------------------------------------------#

# Updating system
apt-get -y upgrade
check_result $? 'apt-get upgrade failed'

# Checking universe repository
if [[ ${release:0:2} -gt 16 ]]; then
    if [ -z "$(grep universe /etc/apt/sources.list)" ]; then
        add-apt-repository -y universe
    fi
fi

# Installing nginx repo
apt=/etc/apt/sources.list.d
echo "deb http://nginx.org/packages/mainline/ubuntu/ $codename nginx" \
    > $apt/nginx.list
wget http://nginx.org/keys/nginx_signing.key -O /tmp/nginx_signing.key
apt-key add /tmp/nginx_signing.key

#----------------------------------------------------------#
#                         Backup                           #
#----------------------------------------------------------#

# Creating backup directory tree
mkdir -p $qtlinux_backups
cd $qtlinux_backups
mkdir nginx apache2 php vsftpd exim4 dovecot clamd
mkdir spamassassin mysql

# Backup nginx configuration
service nginx stop > /dev/null 2>&1
cp -r /etc/nginx/* $qtlinux_backups/nginx >/dev/null 2>&1

# Backup Apache configuration
service apache2 stop > /dev/null 2>&1
cp -r /etc/apache2/* $qtlinux_backups/apache2 > /dev/null 2>&1
rm -f /etc/apache2/conf.d/* > /dev/null 2>&1

# Backup PHP-FPM configuration
service php7.0-fpm stop > /dev/null 2>&1
service php5-fpm stop > /dev/null 2>&1
service php-fpm stop > /dev/null 2>&1
cp -r /etc/php7.0/* $qtlinux_backups/php/ > /dev/null 2>&1
cp -r /etc/php5/* $qtlinux_backups/php/ > /dev/null 2>&1
cp -r /etc/php/* $qtlinux_backups/php/ > /dev/null 2>&1

# Backup Vsftpd configuration
service vsftpd stop > /dev/null 2>&1
cp /etc/vsftpd.conf $qtlinux_backups/vsftpd > /dev/null 2>&1

# Backup Exim configuration
service exim4 stop > /dev/null 2>&1
cp -r /etc/exim4/* $qtlinux_backups/exim4 > /dev/null 2>&1

# Backup ClamAV configuration
service clamav-daemon stop > /dev/null 2>&1
cp -r /etc/clamav/* $qtlinux_backups/clamav > /dev/null 2>&1

# Backup SpamAssassin configuration
service spamassassin stop > /dev/null 2>&1
cp -r /etc/spamassassin/* $qtlinux_backups/spamassassin > /dev/null 2>&1

# Backup Dovecot configuration
service dovecot stop > /dev/null 2>&1
cp /etc/dovecot.conf $qtlinux_backups/dovecot > /dev/null 2>&1
cp -r /etc/dovecot/* $qtlinux_backups/dovecot > /dev/null 2>&1

# Backup MySQL/MariaDB configuration and data
service mysql stop > /dev/null 2>&1
killall -9 mysqld > /dev/null 2>&1
mv /var/lib/mysql $qtlinux_backups/mysql/mysql_datadir > /dev/null 2>&1
cp -r /etc/mysql/* $qtlinux_backups/mysql > /dev/null 2>&1
mv -f /root/.my.cnf $qtlinux_backups/mysql > /dev/null 2>&1
if [ "$release" = '16.04' ] && [ -e '/etc/init.d/mysql' ]; then
    mkdir -p /var/lib/mysql > /dev/null 2>&1
    chown mysql:mysql /var/lib/mysql
    mysqld --initialize-insecure
fi

#----------------------------------------------------------#
#                     Package Excludes                     #
#----------------------------------------------------------#

# Excluding packages
if [ "$release" != "15.04" ] && [ "$release" != "15.04" ]; then
    software=$(echo "$software" | sed -e "s/apache2.2-common//")
fi

if [ "$nginx" = 'no'  ]; then
    software=$(echo "$software" | sed -e "s/^nginx//")
fi
if [ "$apache" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/apache2 //")
    software=$(echo "$software" | sed -e "s/apache2-utils//")
    software=$(echo "$software" | sed -e "s/apache2-suexec-custom//")
    software=$(echo "$software" | sed -e "s/apache2.2-common//")
    software=$(echo "$software" | sed -e "s/libapache2-mod-ruid2//")
    software=$(echo "$software" | sed -e "s/libapache2-mod-rpaf//")
    software=$(echo "$software" | sed -e "s/libapache2-mod-fcgid//")
    software=$(echo "$software" | sed -e "s/libapache2-mod-php7.0//")
    software=$(echo "$software" | sed -e "s/libapache2-mod-php5//")
    software=$(echo "$software" | sed -e "s/libapache2-mod-php//")
fi
if [ "$phpfpm" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/php7.0-fpm//")
    software=$(echo "$software" | sed -e "s/php5-fpm//")
    software=$(echo "$software" | sed -e "s/php-fpm//")
fi
if [ "$vsftpd" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/vsftpd//")
fi
if [ "$exim" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/exim4 //")
    software=$(echo "$software" | sed -e "s/exim4-daemon-heavy//")
    software=$(echo "$software" | sed -e "s/dovecot-imapd//")
    software=$(echo "$software" | sed -e "s/dovecot-pop3d//")
    software=$(echo "$software" | sed -e "s/clamav-daemon//")
    software=$(echo "$software" | sed -e "s/spamassassin//")
fi
if [ "$clamd" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/clamav-daemon//")
fi
if [ "$spamassassin" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/spamassassin//")
fi
if [ "$dovecot" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/dovecot-imapd//")
    software=$(echo "$software" | sed -e "s/dovecot-pop3d//")
fi
if [ "$mysql" = 'no' ]; then
    software=$(echo "$software" | sed -e 's/mysql-server//')
    software=$(echo "$software" | sed -e 's/mysql-client//')
    software=$(echo "$software" | sed -e 's/mysql-common//')
    software=$(echo "$software" | sed -e 's/php7.0-mysql//')
    software=$(echo "$software" | sed -e 's/php5-mysql//')
    software=$(echo "$software" | sed -e 's/php-mysql//')
    software=$(echo "$software" | sed -e 's/phpMyAdmin//')
    software=$(echo "$software" | sed -e 's/phpmyadmin//')
fi

#----------------------------------------------------------#
#                     Install packages                     #
#----------------------------------------------------------#

# Updating system
apt-get update

# Disabling daemon autostart on apt-get install
echo -e '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d
chmod a+x /usr/sbin/policy-rc.d

# Installing apt packages
# apt-get -y install $software
# check_result $? "apt-get install failed"

# Restoring autostart policy
rm -f /usr/sbin/policy-rc.d


#----------------------------------------------------------#
#                     Configure system                     #
#----------------------------------------------------------#

# Enabling SSH password auth
sed -i "s/rdAuthentication no/rdAuthentication yes/g" /etc/ssh/sshd_config
service ssh restart

# Disabling AWStats cron
rm -f /etc/cron.d/awstats

# Registering /usr/sbin/nologin
if [ -z "$(grep nologin /etc/shells)" ]; then
    echo "/usr/sbin/nologin" >> /etc/shells
fi

# Configuring NTP
echo '#!/bin/sh' > /etc/cron.daily/ntpdate
echo "$(which ntpdate) -s ntp.ubuntu.com" >> /etc/cron.daily/ntpdate
chmod 775 /etc/cron.daily/ntpdate
ntpdate -s ntp.ubuntu.com

#----------------------------------------------------------#
#                     Configure qtlinux                      #
#----------------------------------------------------------#

# Building directory tree and creating some blank files for qtlinux
mkdir -p $QTLINUX/conf $QTLINUX/log $QTLINUX/ssl $QTLINUX/data/ips \
    $QTLINUX/data/users $QTLINUX/data/sessions
touch $QTLINUX/log/system.log $QTLINUX/log/nginx-error.log $QTLINUX/log/auth.log
chmod 750 $QTLINUX/conf $QTLINUX/data/users $QTLINUX/data/ips $QTLINUX/log
chmod 660 $QTLINUX/log/*
rm -f /var/log/qtlinux
ln -s $QTLINUX/log /var/log/qtlinux
chmod 770 $QTLINUX/data/sessions

# Generating qtlinux configuration
rm -f $QTLINUX/conf/qtlinux.conf 2>/dev/null
touch $QTLINUX/conf/qtlinux.conf
chmod 660 $QTLINUX/conf/qtlinux.conf

# Web stack
if [ "$apache" = 'yes' ] && [ "$nginx" = 'no' ] ; then
    echo "WEB_SYSTEM='apache2'" >> $QTLINUX/conf/qtlinux.conf
    echo "WEB_RGROUPS='www-data'" >> $QTLINUX/conf/qtlinux.conf
    echo "WEB_PORT='80'" >> $QTLINUX/conf/qtlinux.conf
    echo "WEB_SSL_PORT='443'" >> $QTLINUX/conf/qtlinux.conf
    echo "WEB_SSL='mod_ssl'"  >> $QTLINUX/conf/qtlinux.conf
    echo "STATS_SYSTEM='webalizer,awstats'" >> $QTLINUX/conf/qtlinux.conf
fi
if [ "$apache" = 'yes' ] && [ "$nginx"  = 'yes' ] ; then
    echo "WEB_SYSTEM='apache2'" >> $QTLINUX/conf/qtlinux.conf
    echo "WEB_RGROUPS='www-data'" >> $QTLINUX/conf/qtlinux.conf
    echo "WEB_PORT='8080'" >> $QTLINUX/conf/qtlinux.conf
    echo "WEB_SSL_PORT='8443'" >> $QTLINUX/conf/qtlinux.conf
    echo "WEB_SSL='mod_ssl'"  >> $QTLINUX/conf/qtlinux.conf
    echo "PROXY_SYSTEM='nginx'" >> $QTLINUX/conf/qtlinux.conf
    echo "PROXY_PORT='80'" >> $QTLINUX/conf/qtlinux.conf
    echo "PROXY_SSL_PORT='443'" >> $QTLINUX/conf/qtlinux.conf
    echo "STATS_SYSTEM='webalizer,awstats'" >> $QTLINUX/conf/qtlinux.conf
fi
if [ "$apache" = 'no' ] && [ "$nginx"  = 'yes' ]; then
    echo "WEB_SYSTEM='nginx'" >> $QTLINUX/conf/qtlinux.conf
    echo "WEB_PORT='80'" >> $QTLINUX/conf/qtlinux.conf
    echo "WEB_SSL_PORT='443'" >> $QTLINUX/conf/qtlinux.conf
    echo "WEB_SSL='openssl'"  >> $QTLINUX/conf/qtlinux.conf
    if [ "$phpfpm" = 'yes' ]; then
        echo "WEB_BACKEND='php-fpm'" >> $QTLINUX/conf/qtlinux.conf
    fi
    echo "STATS_SYSTEM='webalizer,awstats'" >> $QTLINUX/conf/qtlinux.conf
fi

# FTP stack
if [ "$vsftpd" = 'yes' ]; then
    echo "FTP_SYSTEM='vsftpd'" >> $QTLINUX/conf/qtlinux.conf
fi

# Mail stack
if [ "$exim" = 'yes' ]; then
    echo "MAIL_SYSTEM='exim4'" >> $QTLINUX/conf/qtlinux.conf
    if [ "$clamd" = 'yes'  ]; then
        echo "ANTIVIRUS_SYSTEM='clamav-daemon'" >> $QTLINUX/conf/qtlinux.conf
    fi
    if [ "$spamassassin" = 'yes' ]; then
        echo "ANTISPAM_SYSTEM='spamassassin'" >> $QTLINUX/conf/qtlinux.conf
    fi
    if [ "$dovecot" = 'yes' ]; then
        echo "IMAP_SYSTEM='dovecot'" >> $QTLINUX/conf/qtlinux.conf
    fi
fi

# Cron daemon
echo "CRON_SYSTEM='cron'" >> $QTLINUX/conf/qtlinux.conf

# Backups
echo "BACKUP_SYSTEM='local'" >> $QTLINUX/conf/qtlinux.conf

# Version
echo "VERSION='0.1'" >> $QTLINUX/conf/qtlinux.conf


# Configuring server hostname
$QTLINUX/bin/v-change-sys-hostname $servername 2>/dev/null

# Generating SSL certificate
$QTLINUX/bin/v-generate-ssl-cert $(hostname) $email 'US' 'California' \
     'San Francisco' 'qtlinux Control Panel' 'IT' > /tmp/qtlinux.pem

# Parsing certificate file
crt_end=$(grep -n "END CERTIFICATE-" /tmp/qtlinux.pem |cut -f 1 -d:)
key_start=$(grep -n "BEGIN RSA" /tmp/qtlinux.pem |cut -f 1 -d:)
key_end=$(grep -n  "END RSA" /tmp/qtlinux.pem |cut -f 1 -d:)

# Adding SSL certificate
cd $QTLINUX/ssl
sed -n "1,${crt_end}p" /tmp/qtlinux.pem > certificate.crt
sed -n "$key_start,${key_end}p" /tmp/qtlinux.pem > certificate.key
chown root:mail $QTLINUX/ssl/*
chmod 660 $QTLINUX/ssl/*
rm /tmp/qtlinux.pem

# Adding nologin as a valid system shell
if [ -z "$(grep nologin /etc/shells)" ]; then
    echo "/usr/sbin/nologin" >> /etc/shells
fi


#----------------------------------------------------------#
#                     Configure Nginx                      #
#----------------------------------------------------------#

if [ "$nginx" = 'yes' ]; then
    rm -f /etc/nginx/conf.d/*.conf
    # cp -f $QTLINUXcp/nginx/nginx.conf /etc/nginx/
    # cp -f $QTLINUXcp/nginx/status.conf /etc/nginx/conf.d/
    # cp -f $QTLINUXcp/nginx/phpmyadmin.inc /etc/nginx/conf.d/
    # cp -f $QTLINUXcp/nginx/webmail.inc /etc/nginx/conf.d/
    # cp -f $QTLINUXcp/logrotate/nginx /etc/logrotate.d/
    echo > /etc/nginx/conf.d/qtlinux.conf
    mkdir -p /var/log/nginx/domains
    update-rc.d nginx defaults
    service nginx start
    check_result $? "nginx start failed"
fi


#----------------------------------------------------------#
#                    Configure Apache                      #
#----------------------------------------------------------#

if [ "$apache" = 'yes'  ]; then
    # cp -f $QTLINUXcp/apache2/apache2.conf /etc/apache2/
    # cp -f $QTLINUXcp/apache2/status.conf /etc/apache2/mods-enabled/
    # cp -f  $QTLINUXcp/logrotate/apache2 /etc/logrotate.d/
    a2enmod rewrite
    a2enmod suexec
    a2enmod ssl
    a2enmod actions
    a2enmod ruid2
    mkdir -p /etc/apache2/conf.d
    echo > /etc/apache2/conf.d/qtlinux.conf
    echo "# Powered by qtlinux" > /etc/apache2/sites-available/default
    echo "# Powered by qtlinux" > /etc/apache2/sites-available/default-ssl
    echo "# Powered by qtlinux" > /etc/apache2/ports.conf
    echo -e "/home\npublic_html/cgi-bin" > /etc/apache2/suexec/www-data
    touch /var/log/apache2/access.log /var/log/apache2/error.log
    mkdir -p /var/log/apache2/domains
    chmod a+x /var/log/apache2
    chmod 640 /var/log/apache2/access.log /var/log/apache2/error.log
    chmod 751 /var/log/apache2/domains
    update-rc.d apache2 defaults
    service apache2 start
    check_result $? "apache2 start failed"
else
    update-rc.d apache2 disable >/dev/null 2>&1
    service apache2 stop >/dev/null 2>&1
fi


#----------------------------------------------------------#
#                     Configure PHP-FPM                    #
#----------------------------------------------------------#

if [ "$phpfpm" = 'yes' ]; then
    pool=$(find /etc/php* -type d \( -name "pool.d" -o -name "*fpm.d" \))
    # cp -f $QTLINUXcp/php-fpm/www.conf $pool/
    php_fpm=$(ls /etc/init.d/php*-fpm* |cut -f 4 -d /)
    ln -s /etc/init.d/$php_fpm /etc/init.d/php-fpm > /dev/null 2>&1
    update-rc.d $php_fpm defaults
    service $php_fpm start
    check_result $? "php-fpm start failed"
fi


#----------------------------------------------------------#
#                     Configure PHP                        #
#----------------------------------------------------------#

ZONE=$(timedatectl 2>/dev/null|grep Timezone|awk '{print $2}')
if [ -z "$ZONE" ]; then
    ZONE='UTC'
fi
for pconf in $(find /etc/php* -name php.ini); do
    sed -i "s%;date.timezone =%date.timezone = $ZONE%g" $pconf
    sed -i 's%_open_tag = Off%_open_tag = On%g' $pconf
done


#----------------------------------------------------------#
#                    Configure Vsftpd                      #
#----------------------------------------------------------#

if [ "$vsftpd" = 'yes' ]; then
    # cp -f $QTLINUXcp/vsftpd/vsftpd.conf /etc/
    touch /var/log/vsftpd.log
    chown root:adm /var/log/vsftpd.log
    chmod 640 /var/log/vsftpd.log
    touch /var/log/xferlog
    chown root:adm /var/log/xferlog
    chmod 640 /var/log/xferlog
    update-rc.d vsftpd defaults
    service vsftpd start
    check_result $? "vsftpd start failed"

fi

#----------------------------------------------------------#
#                  Configure MySQL/MariaDB                 #
#----------------------------------------------------------#

if [ "$mysql" = 'yes' ]; then
    mycnf="my-small.cnf"
    if [ $memory -gt 1200000 ]; then
        mycnf="my-medium.cnf"
    fi
    if [ $memory -gt 3900000 ]; then
        mycnf="my-large.cnf"
    fi

    # Configuring MySQL/MariaDB
    # cp -f $QTLINUXcp/mysql/$mycnf /etc/mysql/my.cnf
    if [ "$release" != '16.04' ]; then
        mysql_install_db
    fi
    if [ "$release" == '18.04' ]; then
        mkdir /var/lib/mysql
        chown mysql:mysql /var/lib/mysql
        mysqld --initialize-insecure
    fi
    update-rc.d mysql defaults
    service mysql start
    check_result $? "mysql start failed"

    # Securing MySQL/MariaDB installation
    mpass=$(gen_pass)
    mysqladmin -u root password $mpass
    echo -e "[client]\npassword='$mpass'\n" > /root/.my.cnf
    chmod 600 /root/.my.cnf
    mysql -e "DELETE FROM mysql.user WHERE User=''"
    mysql -e "DROP DATABASE test" >/dev/null 2>&1
    mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
    mysql -e "DELETE FROM mysql.user WHERE user='' OR password='';"
    mysql -e "FLUSH PRIVILEGES"

    # Configuring phpMyAdmin
    if [ "$apache" = 'yes' ]; then
        # cp -f $QTLINUXcp/pma/apache.conf /etc/phpmyadmin/
        ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf.d/phpmyadmin.conf
    fi
    if [[ ${release:0:2} -ge 18 ]]; then
        mysql < /usr/share/phpmyadmin/sql/create_tables.sql
        p=$(grep dbpass /etc/phpmyadmin/config-db.php |cut -f 2 -d "'")
        mysql -e "GRANT ALL ON phpmyadmin.*
            TO phpmyadmin@localhost IDENTIFIED BY '$p'"
    else
        # cp -f $QTLINUXcp/pma/config.inc.php /etc/phpmyadmin/
    fi
    chmod 777 /var/lib/phpmyadmin/tmp
fi

#----------------------------------------------------------#
#                      Configure Exim                      #
#----------------------------------------------------------#

if [ "$exim" = 'yes' ]; then
    gpasswd -a Debian-exim mail
    # cp -f $QTLINUXcp/exim/exim4.conf.template /etc/exim4/
    # cp -f $QTLINUXcp/exim/dnsbl.conf /etc/exim4/
    # cp -f $QTLINUXcp/exim/spam-blocks.conf /etc/exim4/
    touch /etc/exim4/white-blocks.conf

    if [ "$spamd" = 'yes' ]; then
        sed -i "s/#SPAM/SPAM/g" /etc/exim4/exim4.conf.template
    fi
    if [ "$clamd" = 'yes' ]; then
        sed -i "s/#CLAMD/CLAMD/g" /etc/exim4/exim4.conf.template
    fi

    chmod 640 /etc/exim4/exim4.conf.template
    rm -rf /etc/exim4/domains
    mkdir -p /etc/exim4/domains

    rm -f /etc/alternatives/mta
    ln -s /usr/sbin/exim4 /etc/alternatives/mta
    update-rc.d -f sendmail remove > /dev/null 2>&1
    service sendmail stop > /dev/null 2>&1
    update-rc.d -f postfix remove > /dev/null 2>&1
    service postfix stop > /dev/null 2>&1

    update-rc.d exim4 defaults
    service exim4 start
    check_result $? "exim4 start failed"
fi


#----------------------------------------------------------#
#                     Configure Dovecot                    #
#----------------------------------------------------------#

if [ "$dovecot" = 'yes' ]; then
    gpasswd -a dovecot mail
    if [[ ${release:0:2} -ge 18 ]]; then
        cp -r /usr/local/qtlinux/install/debian/9/dovecot /etc/
        if [ -z "$(grep yes /etc/dovecot/conf.d/10-mail.conf)" ]; then
            echo "namespace inbox {" >> /etc/dovecot/conf.d/10-mail.conf
            echo "  inbox = yes" >> /etc/dovecot/conf.d/10-mail.conf
            echo "}" >> /etc/dovecot/conf.d/10-mail.conf
            echo "first_valid_uid = 1000" >> /etc/dovecot/conf.d/10-mail.conf
            echo "mbox_write_locks = fcntl" >> /etc/dovecot/conf.d/10-mail.conf
        fi
    else
        # cp -rf $QTLINUXcp/dovecot /etc/
    fi
    # cp -f $QTLINUXcp/logrotate/dovecot /etc/logrotate.d/
    chown -R root:root /etc/dovecot*
    update-rc.d dovecot defaults
    service dovecot start
    check_result $? "dovecot start failed"
fi


#----------------------------------------------------------#
#                     Configure ClamAV                     #
#----------------------------------------------------------#

if [ "$clamd" = 'yes' ]; then
    gpasswd -a clamav mail
    gpasswd -a clamav Debian-exim
    # cp -f $QTLINUXcp/clamav/clamd.conf /etc/clamav/
    /usr/bin/freshclam
    update-rc.d clamav-daemon defaults
    service clamav-daemon start
    check_result $? "clamav-daemon start failed"
fi


#----------------------------------------------------------#
#                  Configure SpamAssassin                  #
#----------------------------------------------------------#

if [ "$spamd" = 'yes' ]; then
    update-rc.d spamassassin defaults
    sed -i "s/ENABLED=0/ENABLED=1/" /etc/default/spamassassin
    service spamassassin start
    check_result $? "spamassassin start failed"
    unit_files="$(systemctl list-unit-files |grep spamassassin)"
    if [[ "$unit_files" =~ "disabled" ]]; then
        systemctl enable spamassassin
    fi
fi


#----------------------------------------------------------#
#                   Configure Roundcube                    #
#----------------------------------------------------------#

if [ "$exim" = 'yes' ] && [ "$mysql" = 'yes' ]; then
    if [ "$apache" = 'yes' ]; then
        # cp -f $QTLINUXcp/roundcube/apache.conf /etc/roundcube/
        ln -s /etc/roundcube/apache.conf /etc/apache2/conf.d/roundcube.conf
    fi

    if [[ ${release:0:2} -ge 18 ]]; then
        r=$(grep dbpass= /etc/roundcube/debian-db.php |cut -f 2 -d "'")
        sed -i "s/default_host.*/default_host'] = 'localhost';/" \
            /etc/roundcube/config.inc.php
        sed -i "s/^);/'password');/" /etc/roundcube/config.inc.php
    else
        r="$(gen_pass)"
        # cp -f $QTLINUXcp/roundcube/main.inc.php /etc/roundcube/
        # cp -f  $QTLINUXcp/roundcube/db.inc.php /etc/roundcube/
        sed -i "s/%password%/$r/g" /etc/roundcube/db.inc.php
    fi

    if [ "$release" = '16.04' ]; then
        # TBD: should be fixed in config repo
        mv /etc/roundcube/db.inc.php /etc/roundcube/debian-db-roundcube.php
        mv /etc/roundcube/main.inc.php /etc/roundcube/config.inc.php
        chmod 640 /etc/roundcube/debian-db-roundcube.php
        chown root:www-data /etc/roundcube/debian-db-roundcube.php
    fi

    # cp -f $QTLINUXcp/roundcube/qtlinux.php \
    #     /usr/share/roundcube/plugins/password/drivers/
    # cp -f $QTLINUXcp/roundcube/config.inc.php /etc/roundcube/plugins/password/

    mysql -e "CREATE DATABASE roundcube"
    mysql -e "GRANT ALL ON roundcube.*
        TO roundcube@localhost IDENTIFIED BY '$r'"
    mysql roundcube < /usr/share/dbconfig-common/data/roundcube/install/mysql

    chmod 640 /etc/roundcube/debian-db*
    chown root:www-data /etc/roundcube/debian-db*
    touch /var/log/roundcube/errors
    chmod 640 /var/log/roundcube/errors
    chown www-data:adm /var/log/roundcube/errors

    php5enmod mcrypt 2>/dev/null
    phpenmod mcrypt 2>/dev/null
    if [ "$apache" = 'yes' ]; then
        service apache2 restart
    fi
    if [ "$nginx" = 'yes' ]; then
        service nginx restart
    fi
fi


# #----------------------------------------------------------#
# #                   Configure Admin User                   #
# #----------------------------------------------------------#

# # Deleting old admin user
# if [ ! -z "$(grep ^admin: /etc/passwd)" ] && [ "$force" = 'yes' ]; then
#     chattr -i /home/admin/conf > /dev/null 2>&1
#     userdel -f admin >/dev/null 2>&1
#     chattr -i /home/admin/conf >/dev/null 2>&1
#     mv -f /home/admin  $qtlinux_backups/home/ >/dev/null 2>&1
#     rm -f /tmp/sess_* >/dev/null 2>&1
# fi
# if [ ! -z "$(grep ^admin: /etc/group)" ]; then
#     groupdel admin > /dev/null 2>&1
# fi

# # Adding qtlinux admin account
# $QTLINUX/bin/v-add-user admin $vpass $email default System Administrator
# check_result $? "can't create admin user"
# $QTLINUX/bin/v-change-user-shell admin bash
# $QTLINUX/bin/v-change-user-language admin $lang

# # Configuring system IPs
# $QTLINUX/bin/v-update-sys-ip

# # Get main IP
# ip=$(ip addr|grep 'inet '|grep global|head -n1|awk '{print $2}'|cut -f1 -d/)

# # Configuring firewall
# if [ "$iptables" = 'yes' ]; then
#     $QTLINUX/bin/v-update-firewall
# fi

# # Get public IP
# pub_ip=$(curl -s qtlinuxcp.com/what-is-my-ip/)
# if [ ! -z "$pub_ip" ] && [ "$pub_ip" != "$ip" ]; then
#     echo "$QTLINUX/bin/v-update-sys-ip" >> /etc/rc.local
#     $QTLINUX/bin/v-change-sys-ip-nat $ip $pub_ip
#     ip=$pub_ip
# fi

# # Configuring MySQL/MariaDB host
# if [ "$mysql" = 'yes' ]; then
#     $QTLINUX/bin/v-add-database-host mysql localhost root $mpass
#     $QTLINUX/bin/v-add-database admin default default $(gen_pass) mysql
# fi

# # Configuring PostgreSQL host
# if [ "$postgresql" = 'yes' ]; then
#     $QTLINUX/bin/v-add-database-host pgsql localhost postgres $ppass
#     $QTLINUX/bin/v-add-database admin db db $(gen_pass) pgsql
# fi

# # Adding default domain
# $QTLINUX/bin/v-add-domain admin $servername

# # Adding cron jobs
# command="sudo $QTLINUX/bin/v-update-sys-queue disk"
# $QTLINUX/bin/v-add-cron-job 'admin' '15' '02' '*' '*' '*' "$command"
# command="sudo $QTLINUX/bin/v-update-sys-queue traffic"
# $QTLINUX/bin/v-add-cron-job 'admin' '10' '00' '*' '*' '*' "$command"
# command="sudo $QTLINUX/bin/v-update-sys-queue webstats"
# $QTLINUX/bin/v-add-cron-job 'admin' '30' '03' '*' '*' '*' "$command"
# command="sudo $QTLINUX/bin/v-update-sys-queue backup"
# $QTLINUX/bin/v-add-cron-job 'admin' '*/5' '*' '*' '*' '*' "$command"
# command="sudo $QTLINUX/bin/v-backup-users"
# $QTLINUX/bin/v-add-cron-job 'admin' '10' '05' '*' '*' '*' "$command"
# command="sudo $QTLINUX/bin/v-update-user-stats"
# $QTLINUX/bin/v-add-cron-job 'admin' '20' '00' '*' '*' '*' "$command"
# command="sudo $QTLINUX/bin/v-update-sys-rrd"
# $QTLINUX/bin/v-add-cron-job 'admin' '*/5' '*' '*' '*' '*' "$command"
# service cron restart

# # Building initital rrd images
# $QTLINUX/bin/v-update-sys-rrd

# # Enabling file system quota
# if [ "$quota" = 'yes' ]; then
#     $QTLINUX/bin/v-add-sys-quota
# fi

# # Enabling softaculous plugin
# if [ "$softaculous" = 'yes' ]; then
#     $QTLINUX/bin/v-add-qtlinux-softaculous
# fi

# # Starting qtlinux service
# update-rc.d qtlinux defaults
# service qtlinux start
# check_result $? "qtlinux start failed"
# chown admin:admin $QTLINUX/data/sessions

# # Adding notifications
# $QTLINUX/upd/add_notifications.sh

# # Adding cronjob for autoupdates
# $QTLINUX/bin/v-add-cron-qtlinux-autoupdate


#----------------------------------------------------------#
#                   qtlinux Access Info                      #
#----------------------------------------------------------#

# Comparing hostname and IP
host_ip=$(host $servername| head -n 1 |awk '{print $NF}')
if [ "$host_ip" = "$ip" ]; then
    ip="$servername"
fi

# EOF
