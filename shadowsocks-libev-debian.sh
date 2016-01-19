#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===============================================================================================
#   System Required:  Debian or Ubuntu (32bit/64bit)
#   Description: Install Shadowsocks-libev server for Debian or Ubuntu
#   Author: Teddysun <i@teddysun.com>
#   Thanks: @m0d8ye <https://twitter.com/m0d8ye>
#   Intro:  https://teddysun.com/358.html
#   Mender: Mike<i@guochengjie.site><https://www.guochengjie.site/>
#===============================================================================================

clear
echo ""
echo "#############################################################"
echo "# Install Shadowsocks-libev server for Debian or Ubuntu     #"
echo "# Intro: https://teddysun.com/358.html                      #"
echo "# Author: Teddysun <i@teddysun.com>                         #"
echo "# Thanks: @m0d8ye <https://twitter.com/m0d8ye>              #"
echo "# Mender: Mike<i@guochengjie.site>                          #"
echo "#             <https://www.guochengjie.site/>               #"
echo "# What's different?                                         #"
echo "# 1.Add Udp support                                         #"
echo "# 2.You are able to choose the local port now.              #"
echo "#############################################################"
echo ""

# Install Shadowsocks-libev
function install_shadowsocks_libev(){
    rootness
    disable_selinux
    pre_install
    download_files
    config_shadowsocks
    install_libev
}

# Make sure only root can run our script
function rootness(){
if [[ $EUID -ne 0 ]]; then
   echo "Error:This script must be run as root!" 1>&2
   exit 1
fi
}

# Disable selinux
function disable_selinux(){
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi
}

# Pre-installation settings
function pre_install(){
    #Set shadowsocks-libev config password
    echo "Please input password for shadowsocks-libev:"
    read -p "(Default password: teddysun.com):" shadowsockspwd
    [ -z "$shadowsockspwd" ] && shadowsockspwd="teddysun.com"
    echo ""
    echo "---------------------------"
    echo "password = $shadowsockspwd"
    echo "---------------------------"
    echo ""
    #Set shadowsocks-libev config port
    while true
    do
    echo -e "Please input port for shadowsocks-libev [1-65535]:"
    read -p "(Default port: 8989):" shadowsocksport
    [ -z "$shadowsocksport" ] && shadowsocksport="8989"
    expr $shadowsocksport + 0 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ $shadowsocksport -ge 1 ] && [ $shadowsocksport -le 65535 ]; then
            echo ""
            echo "---------------------------"
            echo "port = $shadowsocksport"
            echo "---------------------------"
            echo ""
            break
        else
            echo "Input error! Please input correct numbers."
        fi
    else
        echo "Input error! Please input correct numbers."
    fi
    done
	# Set shadowsocks-libev local port
    while true
    do
    echo -e "Please input local port for shadowsocks-libev [1-65535]:"
    read -p "(Default port: 1080):" shadowsocksport
    [ -z "$shadowsockslocalport" ] && shadowsockslocalport="1080"
    expr $shadowsockslocalport + 0 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ $shadowsockslocalport -ge 1 ] && [ $shadowsockslocalport -le 65535 ]; then
            echo ""
            echo "---------------------------"
            echo "port = $shadowsockslocalport"
            echo "---------------------------"
            echo ""
            break
        else
            echo "Input error! Please input correct numbers."
        fi
    else
        echo "Input error! Please input correct numbers."
    fi
    done
    get_char(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }
    echo ""
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`
    # Update System
    apt-get -y update
    # Install necessary dependencies
    apt-get install -y wget unzip curl build-essential autoconf libtool libssl-dev
    # Get IP address
    echo "Getting Public IP address, Please wait a moment..."
    IP=$(curl -s -4 icanhazip.com)
    if [[ "$IP" = "" ]]; then
        IP=$(curl -s -4 ipinfo.io/ip)
    fi
    echo -e "Your main public IP is\t\033[32m$IP\033[0m"
    echo ""
    #Current folder
    cur_dir=`pwd`
    cd $cur_dir
}

# Download latest shadowsocks-libev
function download_files(){
    if [ -f shadowsocks-libev.zip ];then
        echo "shadowsocks-libev.zip [found]"
    else
        if ! wget --no-check-certificate https://github.com/shadowsocks/shadowsocks-libev/archive/master.zip -O shadowsocks-libev.zip;then
            echo "Failed to download shadowsocks-libev.zip"
            exit 1
        fi
    fi
    unzip shadowsocks-libev.zip
    if [ $? -eq 0 ];then
        cd $cur_dir/shadowsocks-libev-master/
        if ! wget --no-check-certificate https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-libev-debian; then
            echo "Failed to download shadowsocks-libev start script!"
            exit 1
        fi
    else
        echo ""
        echo "Unzip shadowsocks-libev failed! Please visit https://teddysun.com/358.html and contact."
        exit 1
    fi
}

# Config shadowsocks
function config_shadowsocks(){
    if [ ! -d /etc/shadowsocks-libev ];then
        mkdir /etc/shadowsocks-libev
    fi
    cat > /etc/shadowsocks-libev/config.json<<-EOF
{
    "server":"0.0.0.0",
    "server_port":${shadowsocksport},
    "local_address":"127.0.0.1",
    "local_port":${shadowsockslocalport},
    "password":"${shadowsockspwd}",
    "timeout":600,
    "method":"aes-256-cfb"
}
EOF
}

# Install 
function install_libev(){
    # Build and Install shadowsocks-libev
    if [ -s /usr/local/bin/ss-server ];then
        echo "shadowsocks-libev has been installed!"
        exit 0
    else
        ./configure
        make && make install
        if [ $? -eq 0 ]; then
            # Add run on system start up
            mv $cur_dir/shadowsocks-libev-master/shadowsocks-libev-debian /etc/init.d/shadowsocks
            chmod +x /etc/init.d/shadowsocks
            update-rc.d shadowsocks defaults
            # Run shadowsocks in the background
            /etc/init.d/shadowsocks start -u
            # Run success or not
            if [ $? -eq 0 ]; then
                echo "Shadowsocks-libev start success!"
            else
                echo "Shadowsocks-libev start failure!"
            fi
        else
            echo ""
            echo "Shadowsocks-libev install failed! Please visit https://teddysun.com/358.html and contact."
            exit 1
        fi
    fi
    cd $cur_dir
    # Delete shadowsocks-libev floder
    rm -rf $cur_dir/shadowsocks-libev-master/
    # Delete shadowsocks-libev zip file
    rm -f shadowsocks-libev.zip
    clear
    echo ""
    echo "Congratulations, shadowsocks-libev install completed!"
    echo -e "Your Server IP: \033[41;37m ${IP} \033[0m"
    echo -e "Your Server Port: \033[41;37m ${shadowsocksport} \033[0m"
    echo -e "Your Password: \033[41;37m ${shadowsockspwd} \033[0m"
    echo -e "Your Local IP: \033[41;37m 127.0.0.1 \033[0m"
    echo -e "Your Local Port: \033[41;37m ${shadowsockslocalport} \033[0m"
    echo -e "Your Encryption Method: \033[41;37m aes-256-cfb \033[0m"
	echo "We automatically open the udp port for you(the same as tcp port)"
    echo ""
    echo "Welcome to visit:https://teddysun.com/357.html"
	echo "Also the mender's blog:https://www.guochengjie.site/"
    echo "Enjoy it!"
    echo ""
    exit 0
}

# Uninstall Shadowsocks-libev
function uninstall_shadowsocks_libev(){
    printf "Are you sure uninstall Shadowsocks-libev? (y/n) "
    printf "\n"
    read -p "(Default: n):" answer
    if [ -z $answer ]; then
        answer="n"
    fi
    if [ "$answer" = "y" ]; then
        ps -ef | grep -v grep | grep -v ps | grep -i "ss-server" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            /etc/init.d/shadowsocks stop
        fi
        # remove auto start script
        update-rc.d -f shadowsocks remove
        # delete config file
        rm -rf /etc/shadowsocks-libev
        # delete shadowsocks
        rm -f /usr/local/bin/ss-local
        rm -f /usr/local/bin/ss-tunnel
        rm -f /usr/local/bin/ss-server
        rm -f /usr/local/bin/ss-redir
        rm -f /usr/local/lib/libshadowsocks.a
        rm -f /usr/local/lib/libshadowsocks.la
        rm -f /usr/local/include/shadowsocks.h
        rm -rf /usr/local/lib/pkgconfig
        rm -f /usr/local/share/man/man8/shadowsocks.8
        echo "Shadowsocks-libev uninstall success!"
    else
        echo "uninstall cancelled, Nothing to do"
    fi
}

# Initialization step
action=$1
[  -z $1 ] && action=install
case "$action" in
install)
    install_shadowsocks_libev
    ;;
uninstall)
    uninstall_shadowsocks_libev
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|uninstall}"
    ;;
esac
