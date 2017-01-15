#!/bin/bash


#### Opening Questions ####
echo "###TFSD Firewall/Router deployment script by Killer Panda###"
echo "          #### Beta v0.1.5 ####"
echo "This setup requires 2 NIC's in order to function, please specify your WAN facing NIC below"
read nwan
echo "Please specify your LAN facing NIC below"
read nlan
echo "Do you need to forward any ports? y/n"
read portf

	if [ $portf = "y" ]
		then
			echo "IP or FQDN of server to forward packets to"
			read fwip
			echo "Wan port"
			read fwwp
			echo "Server port"
			read fwlp
			echo "Enter the web address eg: testdomain.com"
			read weba
			echo "Enter the protocaol"
			read pr

echo "iptables -t nat -A PREROUTING -p "$prt" -d "$weba" --dport "$fwwp" -j DNAT --to-destination "$fwip":"$fwlp" would your string is listed above, would you like to proceed (y/n)"
echo "Would you like commit this string? y/n"
read prtf

	if [ $prtf = "y" ]
	then
	iptables -t nat -A PREROUTING -p "$prt" -d "$weba" --dport "$fwwp" -j DNAT --to-destination "$fwip":"$fwlp"
	else
	fi

	


echo "We will now create a table to interogate packets, enter a name for this table EG: sniffer"
read icc
## chain creation ##
iptables -N "$icc"

### Flush command ###
iptables -t nat -F # Flush the nat table first
iptables -F # Flush the remaining tables
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P INPUT ACCEPT



## Enable forwarding on os level ##

sysctl -w net.ipv4.ip_forward=1

## Drop invalid packer on wan ##

iptables -A "$icc" -i "$nwan" -m state --state INVALID -j DROP


## Masquerade ##

iptables -t nat -A POSTROUTING -o "$nwan" -j MASQUERADE


## Forward policy ##

iptables -A FORWARD -i "$nlan" -o "$nwan" -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i "$nwan" -o "$nlan" -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT


## Link local ## 
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT


## Network time protocal ##
iptables -A "$icc" -i "$nwan" -p udp --dport 123 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT


## Ping requests ##
echo "Allow gateway to respond to ping requests? y n"
read preq
	if [ $preq = "y" ]
	then
		iptables -A INPUT -p icmp --icmp-type 8 -s 0/0 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
	else
	fi

## dns ##
iptables -A "$icc" -i "$nwan" -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT  ## DNS requests in on wan add ##


## Allowing web trafic and other trafic ##

iptabes -A "$icc" -i "$nwan" -m state --state RELATED,ESTABLISHED -j ACCEPT


## Allow everything out of lan ##

iptables -A INPUT -i "$nlan" -j ACCEPT
iptables -A OUTPUT -o "$nwan" -j ACCEPT
iptables -A OUTPUT -o "$nlan" -j ACCEPT


## Moving incoming packers to our interogation table ##

iptables -A INPUT -i "$nwan" -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -i "$nwan" -m state --state RELATED,NEW -j "$icc"


## Drop packet ##

iptables -A "$icc" -j DROP


## installing iptables-persistant ##

echo "Would you like to install iptables-persistant? This package will ensure that your iptables config will remain after reboot y/n?"
read pers

if [ $pers = "y" ]
	then
	apt-get update
	apt-get purge iptables-persistant
	apt-get install iptables-persistant

fi



## Install DNS server ##

echo "Would you like a combo DNS server and Add Blocker? y/n"
read dnsph
if [ $dnsph = "y" ]
then
curl -sSL https://install.pi-hole.net | bash
fi


iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

echo ## Twisted Fre Starter isnow enabled ##


done

