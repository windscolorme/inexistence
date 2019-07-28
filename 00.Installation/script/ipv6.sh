#!/bin/bash
#
# https://github.com/Aniverse/inexistence
# Author: Aniverse
#
script_update=2019.07.28
script_version=r21013
################################################################################################

usage_guide() {
s=/usr/local/bin/ipv66;rm -f $s;nano $s;chmod 755 $s
bash <(wget -qO- https://github.com/Aniverse/inexistence/raw/master/00.Installation/script/ipv6.sh) -m online-netplan -6 XXX -d XXX -s 56 ; }

################################################################################################ Get options

reboot=no

OPTS=$(getopt -o m:d:s:6:r --long "mode:,ipv6:,duid:,subnet:,reboot" -- "$@")
[ ! $? = 0 ] && { echo -e "Invalid option" ; exit 1 ; }
eval set -- "$OPTS"

while true; do
  case "$1" in
    -m | --mode   ) mode="$2"   ; shift 2 ;;
    -6 | --ipv6   ) IPv6="$2"   ; shift 2 ;;
    -d | --duid   ) DUID="$2"   ; shift 2 ;;
    -s | --subnet ) subnet="$2" ; shift 2 ;;
    -r | --reboot ) reboot=yes  ; shift   ;;
     * ) break ;;
  esac
done

################################################################################################ Colors

black=$(tput setaf 0)   ; red=$(tput setaf 1)          ; green=$(tput setaf 2)   ; yellow=$(tput setaf 3);  bold=$(tput bold)
blue=$(tput setaf 4)    ; magenta=$(tput setaf 5)      ; cyan=$(tput setaf 6)    ; white=$(tput setaf 7) ;  normal=$(tput sgr0)
on_black=$(tput setab 0); on_red=$(tput setab 1)       ; on_green=$(tput setab 2); on_yellow=$(tput setab 3)
on_blue=$(tput setab 4) ; on_magenta=$(tput setab 5)   ; on_cyan=$(tput setab 6) ; on_white=$(tput setab 7)
shanshuo=$(tput blink)  ; wuguangbiao=$(tput civis)    ; guangbiao=$(tput cnorm) ; jiacu=${normal}${bold}
underline=$(tput smul)  ; reset_underline=$(tput rmul) ; dim=$(tput dim)
standout=$(tput smso)   ; reset_standout=$(tput rmso)  ; title=${standout}
baihuangse=${white}${on_yellow}; bailanse=${white}${on_blue} ; bailvse=${white}${on_green}
baiqingse=${white}${on_cyan}   ; baihongse=${white}${on_red} ; baizise=${white}${on_magenta}
heibaise=${black}${on_white}   ; heihuangse=${on_yellow}${black}
CW="${bold}${baihongse} ERROR ${jiacu}";ZY="${baihongse}${bold} ATTENTION ${jiacu}";JG="${baihongse}${bold} WARNING ${jiacu}"

################################################################################################

SysSupport=0
DISTRO=$(awk -F'[= "]' '/PRETTY_NAME/{print $3}' /etc/os-release)
CODENAME=$(cat /etc/os-release | grep VERSION= | tr '[A-Z]' '[a-z]' | sed 's/\"\|(\|)\|[0-9.,]\|version\|lts//g' | awk '{print $2}')
[[ $DISTRO == Ubuntu ]] && osversion=$(grep Ubuntu /etc/issue | head -1 | grep -oE  "[0-9.]+")
[[ $DISTRO == Debian ]] && osversion=$(cat /etc/debian_version)
[[ $CODENAME =~ (xenial|bionic|jessie|stretch|) ]] && SysSupport=1
[[ $SysSupport == 0 ]] && echo -e "${red}Your system is not supported!${normal}" && exit 1
type=ifdown
[[ -f /etc/netplan/01-netcfg.yaml ]] && [[ $CODENAME == bionic ]] && type=netplan
[[ $type == ifdown ]] && [[ -z $(which ifdown) ]] && { echo -e "${green}Installing ifdown ...${normal}" ; apt-get install ifupdown -y ; }

[[ -z $(which ifconfig) ]] && { echo -e "${green}Installing ifconfig ...${normal}" ; apt-get install net-tools -y  ; }
[[ -z $(which ifconfig) ]] && { echo -e "${red}Error: No ifconfig!${normal}"  ; exit 1 ; }

################################################################################################

function isValidIpAddress() { echo $1 | grep -qE '^[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?$' ; }
function isInternalIpAddress() { echo $1 | grep -qE '(192\.168\.((\d{1,2})|(1\d{2})|(2[0-4]\d)|(25[0-5]))\.((\d{1,2})$|(1\d{2})$|(2[0-4]\d)$|(25[0-5])$))|(172\.((1[6-9])|(2\d)|(3[0-1]))\.((\d{1,2})|(1\d{2})|(2[0-4]\d)|(25[0-5]))\.((\d{1,2})$|(1\d{2})$|(2[0-4]\d)$|(25[0-5])$))|(10\.((\d{1,2})|(1\d{2})|(2[0-4]\d)|(25[0-5]))\.((\d{1,2})|(1\d{2})|(2[0-4]\d)|(25[0-5]))\.((\d{1,2})$|(1\d{2})$|(2[0-4]\d)$|(25[0-5])$))' ; }

#serveripv4=$( ip route get 8.8.8.8 | awk '{print $3}' )
#isInternalIpAddress "$serveripv4" && serveripv4=$( wget -t1 -T6 -qO- v4.ipv6-test.com/api/myip.php )
serveripv4=$( wget -t1 -T6 -qO- v4.ipv6-test.com/api/myip.php )
isValidIpAddress "$serveripv4" || serveripv4=$( wget -t1 -T6 -qO- checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//' )
isValidIpAddress "$serveripv4" || serveripv4=$( wget -t1 -T7 -qO- ipecho.net/plain )
isValidIpAddress "$serveripv4" || {
unset serveripv4
echo -e "${CW} Failed to detect your public IPv4 address, please write your public IPv4 address: ${normal}"
while [[ -z $serveripv4 ]]; do
    read -e serveripv4
    isInternalIpAddress "$serveripv4" && { echo -e "${CW} This is INTERNAL IPv4 address, not PUBLIC IPv4 address, please write your public IPv4: ${normal}" ; unset serveripv4 ; }
    isValidIpAddress "$serveripv4" || { echo -e "${CW} This is not a valid public IPv4 address, please write your public IPv4: ${normal}" ; unset serveripv4 ; }
done ; }

interface=$(ip route get 8.8.8.8 | awk '{print $5}')
sysctl -w net.ipv6.conf.$interface.autoconf=0 > /dev/null
ik_ipv6="2a00:c70:1:${serveripv4//./:}:1"
ik_way6="${ik_ipv6/${serveripv4##*.}::1}"
AAA=$( echo $serveripv4 | awk -F '.' '{print $1}' )
BBB=$( echo $serveripv4 | awk -F '.' '{print $2}' )
CCC=$( echo $serveripv4 | awk -F '.' '{print $3}' )
DDD=$( echo $serveripv4 | awk -F '.' '{print $4}' )

################################################################################################

function check_var() {
    [[ -z $IPv6 ]] && echo "${red}No IPv6${normal}" && exit 1
    [[ -z $DUID ]] && echo "${red}No DUID${normal}" && exit 1
    [[ -z $subnet ]] && echo "${red}No subnet${normal}" && exit 1
}

# Ikoula 独服（/etc/network/interfaces）
function ikoula_interfaces() {
    if [[ ! $(grep -q "iface $interface inet6 static" /etc/network/interfaces) ]] || [[ $force == 1 ]] ; then
        file_backup
        [[ $force == 1 ]] && interfaces_file_clean
        cat << EOF >> /etc/network/interfaces
### Added by IPv6_Script ###
iface $interface inet6 static
address 2a00:c70:1:$AAA:$BBB:$CCC:$DDD:1
netmask 96
gateway 2a00:c70:1:$AAA:$BBB:$CCC::1
### IPv6_Script END ###
EOF
        systemctl_restart
    fi
}

function ikoula_interfaces2() {
    file_backup
    cat << EOF > /etc/network/interfaces
# Network configuration file
# Auto generated by Ikoula

iface lo inet loopback
auto lo

auto $interface
	iface eth0 inet static
	address $AAA.$BBB.$CCC.$DDD
	netmask 255.255.255.00
	broadcast $AAA.$BBB.$CCC.255
	network $AAA.$BBB.$CCC.0
	gateway $AAA.$BBB.$CCC.1
	dns-nameservers 213.246.36.14 213.246.33.144 80.93.83.11

	### Added by IPv6_Script ###
	iface $interface inet6 static
	address 2a00:c70:1:$AAA:$BBB:$CCC:$DDD:1
	netmask 96
	gateway 2a00:c70:1:$AAA:$BBB:$CCC::1
	### IPv6_Script END ###
EOF
    systemctl_restart
}




# Ikoula 独服，Ubuntu 18.04 系统（netplan）
function ikoula_netplan() {
    file_backup
    cat << EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    $interface:
      dhcp4: no
      dhcp6: no
      accept-ra: no
      addresses: [$AAA.$BBB.$CCC.$DDD/24, '2400:c70:1:$AAA:$BBB:$CCC:$DDD:1/96']
      gateway4: $AAA.$BBB.$CCC.1
      gateway6: 2a00:c70:1:$AAA:$BBB:$CCC::1
      nameservers:
        addresses: [213.246.36.14,213.246.33.144,80.93.83.11]
EOF
    netplan apply
}


################################################################################################


function online_interfaces_file_mod() {
    cat << EOF >> /etc/network/interfaces
### Added by IPv6_Script ###
iface $interface inet6 static
address $IPv6
netmask $subnet
accept_ra 1
pre-up dhclient -cf /etc/dhcp/dhclient6.conf -pf /run/dhclient6.$interface.pid -6 -P $interface
pre-down dhclient -x -pf /run/dhclient6.$interface.pid
### IPv6_Script END ###
EOF
}

# Online／OneProvider Paris 独服，Ubuntu 16.04，Debian 8/9/10
function online_interfaces() {
    file_backup
    if [[ ! $(grep -q "iface $interface inet6 static" /etc/network/interfaces) ]]; then
        interfaces_file_clean
        online_interface_file_mod
    fi
    cat << EOF > /etc/dhcp/dhclient6.conf
interface \"$interface\" {
send dhcp6.client-id $DUID;
request;
}
EOF
    systemctl_restart
}




# Online／OneProvider Paris 独服，Ubuntu 18.04 系统（netplan）
function online_netplan() {
    check_var
    file_backup

    cat << EOF > /etc/dhcp/dhclient6.conf
interface "$interface" {
  send dhcp6.client-id $DUID;
  request;
}
EOF
    cat << EOF > /etc/systemd/system/dhclient.service
[Unit]
Description=dhclient for sending DUID IPv6
Wants=network.target
Before=network.target
[Service]
Type=forking
ExecStart=/sbin/dhclient -cf /etc/dhcp/dhclient6.conf -6 -P -v $interface
[Install]
WantedBy=multi-user.target
EOF
    cat << EOF > /etc/systemd/system/dhclient-netplan.service
[Unit]
Description=redo netplan apply after dhclient
Wants=dhclient.service
After=dhclient.service
Before=network.target
[Service]
Type=oneshot
ExecStart=/usr/sbin/netplan apply
[Install]
WantedBy=dhclient.service
EOF
    cat << EOF >> /etc/netplan/01-netcfg.yaml
      dhcp6: no
      accept-ra: yes
      addresses:
      - $IPv6/$subnet
EOF

    systemctl daemon-reload
    systemctl start dhclient.service
    systemctl start dhclient-netplan.service
    systemctl enable dhclient.service
    systemctl enable dhclient-netplan.service
}


function dibbler_install() {
    dpkg-query -W -f='${Status}' build-essential 2>/dev/null | grep -q "ok installed" && apt-get install -y build-essential
    wget https://netix.dl.sourceforge.net/project/dibbler/dibbler/1.0.1/dibbler-1.0.1.tar.gz
    tar zxvf dibbler-1.0.1.tar.gz
    cd dibbler-1.0.1
    ./configure
    make
    make install
}


function online_dibbler_action() {
    mkdir -p /var/lib/dibbler    /etc/dibbler/
    echo "$DUID" > /var/lib/dibbler/client-duid
    cat << EOF > /etc/dibbler/client.conf
log-level 7
duid-type duid-ll
inactive-mode

iface $interface {
pd
}
EOF
    file_backup
    interfaces_file_clean
    cat << EOF >> /etc/network/interfaces
### Added by IPv6_Script ###
iface eth0 inet6 static
address $IPv6
netmask $subnet
### IPv6_Script END ###
EOF
    cat << EOF > /etc/systemd/system/dibbler-client.service
[Unit]
Description=Dibbler Client
After=networking.service

[Service]
Type=simple
ExecStart=/usr/local/sbin/dibbler-client start

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable dibbler-client.service
}


function online_dibbler() {
    check_var
    dibbler_install
    online_dibbler_action
}



###########################################################################



function file_backup() {
    mkdir -p /log/script
    if [[ $type == netplan ]]; then
        cp -f   /etc/netplan/01-netcfg.yaml  /log/script/netcfg.yaml.$(date "+%Y.%m.%d.%H.%M.%S").bak
    elif [[ $type == ifdown ]]; then
        cp -f   /etc/network/interfaces      /log/script/interfaces.$(date "+%Y.%m.%d.%H.%M.%S").bak
    fi
}

function interfaces_file_clean() {
    while grep -q "IPv6_Script" /etc/network/interfaces ; do
        sed -i '$d' /etc/network/interfaces
    done
}

function systemctl_restart() {
    systemctl restart networking.service || echo -e "\n${red}systemctl restart networking.service FAILED${normal}"
}

function ipv6_test() {
    echo -ne "\n${bold}Testing IPv6 connectivity ... ${normal}"
    IPv6_test=$(ping6 -c 5 ipv6.google.com | grep 'received' | awk -F',' '{ print $2 }' | awk '{ print $1 }')
    if [[ $IPv6_test > 0 ]]; then
        echo "${bold}${yellow}Success!${normal}"
        exit 0
    else
        echo "${bold}${red}Failed${normal}"
        exit 1
    fi
}

function sysctl_enable_ipv6() {
    sysctl -w net.ipv6.conf.$interface.autoconf=0 > /dev/null
    sed -i '/^net.ipv6.conf.*/'d /etc/sysctl.conf
    echo "net.ipv6.conf.$interface.autoconf=0" >> /etc/sysctl.conf
}

function ask_reboot() {
    if [[ $reboot == no ]]; then
        echo -e "Press ${on_red}Ctrl+C${normal} ${bold}to exit${jiacu}, or press ${bailvse}ENTER${normal} ${bold}to reboot"
        read input
    fi
    echo -e "\n${bold}Rebooting ... ${bold}"
    reboot -f
    init 6
}

function info() {
    echo -e "
script_update=$script_update
script_version=$script_version

DISTRO=$DISTRO
CODENAME=$CODENAME
IPv4=$serveripv4
interface=$interface
mode=$mode   type=$type
reboot=$reboot

IPv6=$IPv6
DUID=$DUID
subnet=$subnet
"
    echo -e "\n${yellow}cat /etc/network/interfaces${normal}\n"
    cat /etc/network/interfaces     2>/dev/null
    echo -e "\n${yellow}cat /etc/netplan/01-netcfg.yaml${normal}\n"
    cat /etc/netplan/01-netcfg.yaml 2>/dev/null
    echo -e "
cd /log/script && ls
netplan apply
systemctl restart networking.service
ping6 -c 5 ipv6.google.com"
}

###########################################################################


case $mode in
    ik  ) ikoula_interfaces   ; ipv6_test  ;;
    ik2 ) ikoula_netplan      ; ipv6_test  ;;
    ol  ) online_interfaces   ; ipv6_test  ;; ask_reboot ;;
    ol2 ) online_netplan      ; ipv6_test  ;;
    ol3 ) online_dibbler      ; ask_reboot ;;
    t   ) info ; ipv6_test ;;
esac

