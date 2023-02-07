#!/bin/bash

#  spawn sudo apt install xtables-addons-common
sudo apt install xtables-addons-common -y


# start change port
echo "Port $1" >> /etc/ssh/sshd_config
sudo service sshd restart
# end
# start change port2
echo "Port $2" >> /etc/ssh/sshd_config
sudo service sshd restart
# end

# start ufw
if [ ! -z $3 ] || [ ! -z $4 ] || [ ! -z $5 ] || [ ! -z $6 ]
then
  sudo iptables -A OUTPUT -j ACCEPT
  IFS=';' read -ra ADDR <<< "$2"
    for tcp_port in "${ADDR[@]}"; do
      sudo iptables -A INPUT -p tcp --dport $tcp_port -j ACCEPT
    done
fi
# end

# дозволяємо ip
if [ ! -z $3 ]
then
    IFS=';' read -ra ADDR <<< "$3"
    for server_ip in "${ADDR[@]}"; do
      sudo iptables -A INPUT -p tcp -s $server_ip --dport $1 -j ACCEPT
    done
fi
# end
# забороняємо ip
if [ ! -z $4 ]
then
  IFS=';' read -ra ADDR <<< "$4"
    for server_ip in "${ADDR[@]}"; do
        sudo iptables -A INPUT -p tcp -s $server_ip --dport $1 -j DROP
    done
fi
# end


if [ ! -z $5 ] || [ ! -z $6 ]
then
  # start geolib
  mkdir /usr/share/xt_geoip
  sudo chmod +x /usr/lib/xtables-addons/xt_geoip_build
  sudo mkdir /usr/share/xt_geoip
  apt-get install libtext-csv-xs-perl unzip
  /usr/lib/xtables-addons/xt_geoip_dl
  /usr/lib/xtables-addons/xt_geoip_build -D /usr/share/xt_geoip *.csv
  # end
  # дозволяємо geo
  if [ ! -z $5 ]
  then
    iptables -I INPUT -p tcp --dport $1 -m geoip --src-cc $5 -j ACCEPT
#    iptables -I INPUT ! -i lo -p tcp --dport 22 -m geoip ! --src-cc UA,RU -j DROP
#    iptables -I INPUT -i lo -p tcp --dport $1 -m geoip --src-cc $4 -j ACCEPT
#      IFS=';' read -ra ADDR <<< "$4"
#      for country in "${ADDR[@]}"; do
#        iptables -I INPUT ! -i lo -p tcp --dport $1 -m geoip ! --src-cc $country -j DROP
#      done
  fi
  # забороняємо geo
  if [ ! -z $6 ]
  then
    iptables -I INPUT -p tcp --dport $1 -m geoip --src-cc $6 -j DROP
  fi
fi


if [ ! -z $4 ] || [ ! -z $6 ]
then
  sudo iptables -A INPUT -p tcp --dport $1 -j ACCEPT
fi

if [ ! -z $3 ] || [ ! -z $5 ]
then
  sudo iptables -A INPUT -p tcp --dport $1 -j DROP
fi

service netfilter-persistent restart
/sbin/iptables-save
iptables -S

exit 0
