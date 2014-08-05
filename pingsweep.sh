#!/bin/bash
#

#
#
#

# Color Variables
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldgreen=${txtbld}$(tput setaf 2) #  green
txtblu=$(tput setaf 4)
txtwhite=$(tput setaf 7)
txtyellow=$(tput setaf 3)
txtund=$(tput sgr 0 1)
txtrst=$(tput sgr0)   # reset
ROW=" "
TABLE="| Node_Name | Instance_Address | Nova_Status | Connectivity"
KILLSWITCH=/root/dontrunovswatch
EXPIRE=3600

log ()
{
    /usr/bin/logger -t ovswatch $@
    /bin/echo $@
}

node_instances_down ()
{
    log "NETWORK $NET_ID UNAVAILABLE on $SHORTNODE! Check or restart Open vSwitch and/or the Neutron plugin agent."
    /usr/bin/touch $KILLSWITCH
    exit 0
}

check_mode ()
{
    for NODE in $(nova-manage service list 2>/dev/null | awk '/nova-compute/ {print $2}')
    do
        num_instances=0
        fail=0
        SHORTNODE=$(echo $NODE | cut -d '.' -f1)
        echo -e "\r\nNode:" $NODE
        echo -e "Network ID:" $NET_ID
        for LINE in $(neutron port-list --network_id $NET_ID --binding:host_id $NODE --device_owner compute:nova | awk '/ip_address/ {print $2,$10}' | sed 's/ //')
        do
            ((num_instances++))
            INSTANCE_IP=$(echo $LINE | cut -d '"' -f2)
            PORT_ID=$(echo $LINE | cut -d '"' -f1)
            INSTANCES+=($INSTANCE_IP)
            #Attempt ICMP ping from DHCP namespace
            ip netns exec qdhcp-$NET_ID ping -i .25 -c 2 -W 2 $INSTANCE_IP >/dev/null && INSTANCE_STATE='ACTIVE' && INSTANCE_CONNECT=$bldgreen'ICMP'$txtrst && echo "$SHORTNODE instance $INSTANCE_IP $(tput setaf 2)OK$(tput sgr0)" || false
            if [ $? != 0 ]; then
                # If we're here it means ICMP failed. Could be dropped by secgroup or instance could be down.
                # Look for an ARP entry in the DHCP namespace
                NOARP=$(ip netns exec qdhcp-$NET_ID arp -an | grep $INSTANCE_IP | grep incomplete | wc -l)
                if [ $NOARP -eq "1" ]; then
                    # If we're here it means that ICMP and ARP failed. Check to see if the instance is ACTIVE
                    INSTANCE_STATE=$(nova list --all-tenants | grep $INSTANCE_IP | cut -d '|' -f4 | sed 's/ //g')
                    if [ $INSTANCE_STATE == 'ACTIVE' ]; then
                        INSTANCE_CONNECT=$bldred'FAIL'$txtrst
			echo "$SHORTNODE instance $INSTANCE_IP $(tput setaf 1)FAILED$(tput sgr0). Instance is in ACTIVE state and unresponsive."
                        ((++fail))
                    else
			INSTANCE_CONNECT='N/A'
                        echo "$SHORTNODE instance $INSTANCE_IP FAILED. Instance not in ACTIVE state. Disregard."
                        ((num_instances--))
                    fi
                else
		    INSTANCE_STATE='ACTIVE'
		    INSTANCE_CONNECT=$bldgreen'ARP'$txtrst
                    echo "$SHORTNODE instance $INSTANCE_IP $(tput setaf 2)OK$(tput sgr0) via ARP entry"
                fi
            fi
	    ROW="|"" "$SHORTNODE" ""|"" "$INSTANCE_IP" ""|"" "$INSTANCE_STATE" ""|"" "$INSTANCE_CONNECT
            TABLE="$TABLE\n$ROW"
	    unset INSTANCE_CONNECT
	    unset INSTANCE_IP
            unset PORT_ID
            unset INSTANCE_STATE
        done
        echo "Number of instances : $num_instances"
        echo "Number of unresponsive instances : $fail"
        if [ $num_instances -gt 0 ]; then
            if [ $fail -eq $num_instances ]; then
                for i in ${INSTANCES[*]}
                do
                    ip netns exec qdhcp-$NET_ID ping -i .25 -c 2 -W 2 $i > /dev/null
                    if [ $? == 0 ]; then
                        echo "$(tput setaf 1)NETWORK $NET_ID UNAVAILABLE on $SHORTNODE! Check or restart Open vSwitch and/or the Neutron plugin agent.$(tput sgr0)"
                    fi
                done
            fi
        fi
        unset num_instances
        unset fail
    done
    #echo -e " \r\n== Pretty table output =="
    echo -e $TABLE | column -t -x
    exit 0
}

unattended_mode ()
{
    for NODE in $(nova-manage service list 2>/dev/null | awk '/nova-compute/ {print $2}')
    do
        num_instances=0
        fail=0
        SHORTNODE=$(echo $NODE | cut -d '.' -f1)
        for LINE in $(neutron port-list --network_id $NET_ID --binding:host_id $NODE --device_owner compute:nova | awk '/ip_address/ {print $2,$10}' | sed 's/ //')
        do
            ((num_instances++))
            INSTANCE_IP=$(echo $LINE | cut -d '"' -f2)
            PORT_ID=$(echo $LINE | cut -d '"' -f1)
            INSTANCES+=($INSTANCE_IP)
            #Attempt ICMP ping from DHCP namespace
            ip netns exec qdhcp-$NET_ID ping -i .25 -c 2 -W 2 $INSTANCE_IP > /dev/null || false
            if [ $? != 0 ]; then
                # If we're here it means ICMP failed. Could be dropped by secgroup or instance could be down.
                # Look for an ARP entry in the DHCP namespace
                NOARP=$(ip netns exec qdhcp-$NET_ID arp -an | grep $INSTANCE_IP | grep incomplete | wc -l)
                if [ $NOARP -eq "1" ]; then
                    # If we're here it means that ICMP and ARP failed. Check to see if the instance is ACTIVE
                    INSTANCE_STATE=$(nova list --all-tenants | grep $INSTANCE_IP | cut -d '|' -f4 | sed 's/ //g')
                    if [ $INSTANCE_STATE == 'ACTIVE' ]; then
                        ((++fail))
                    else
                        ((num_instances--))
                    fi
                fi
            fi
            unset INSTANCE_IP
            unset PORT_ID
            unset INSTANCE_STATE
        done
        if [ $num_instances -gt 0 ]; then
            if [ $fail -eq $num_instances ]; then
                for i in ${INSTANCES[*]}
                do
                    ip netns exec qdhcp-$NET_ID ping -i .25 -c 2 -W 2 $i > /dev/null && node_instances_down
                done
                log "Possible network issue detected on $(hostname)! Check or restart Open vSwitch and/or the Neutron plugin agent."
            fi
        fi
        unset num_instances
        unset fail
    done
    exit 0
}

#
## Main
#

if [ "$#" -lt 2 ]; then
  echo "Usage examples: "
  echo "# ./ovs-watch.sh unattended INSIDE_NET (log and print major errors)"
  echo "# ./ovs-watch.sh check INSIDE_NET (print output for human consumption)"
  exit 1
fi

if [ -f $KILLSWITCH ]; then
  FILEDATE=`date -r $KILLSWITCH +%s`
  NOW=`date +%s`
  DELTA=$(( $NOW - $FILEDATE ))
  if [ $DELTA -gt $EXPIRE ]; then
    logger -t ovswatch "Removing expired kill switch ($KILLSWITCH) after $EXPIRE seconds"
    rm -f $KILLSWITCH
  else
    logger -t ovswatch "Kill switch $KILLSWITCH exists, exiting."
    exit 0
  fi
fi

source /root/openrc
NET_ID=$(neutron net-list | grep $2 | awk '{print $2}')
INSTANCES=()
[[ -z $NET_ID ]] && api_error

if [ $1 == 'check' ]; then
  check_mode
elif [ $1 == 'unattended' ]; then
  unattended_mode
fi
