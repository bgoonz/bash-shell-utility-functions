#!/bin/sh
echo "show_hme, v1.5. Stacey Marshall, 16 April 1998"
# Display HME/network parameters.
# Based on get_hme_paramters, Version 2 by Mark F 26/2/97
#
#
#       ******************************************************
#       *                                                    *
#       *                    DISCLAIMER                      *
#       *                                                    *
#       ******************************************************
#
#
# The contents of this file  are intended to  be read as an example.
# This  is not  a  supported product of Sun Microsystems  and  no hotline
# calls  will  be accepted which directly relate to this information.
#
# NO LIABILITY WILL BE  ACCEPTED BY SUN MICROSYSTEMS FOR ANY LOSS (DIRECT
# OR CONSEQUENTIAL) INCURRED IN ANY WAY BY ANY PARTY THROUGH THE USE OF
# THIS INFORMATION.
#
# NO WARRANTY  OF  ANY SORT  IS IMPLIED OR GIVEN FOR ANY CODE DERIVED
# FROM THIS INFORMATION.
#

# Did ya know on Solaris 2.x you can get simular results with:
# ndd /dev/hme `ndd /dev/hme \? | awk '$1 !~ /\?/ {print $1 "\n" }' | \
#     tee /tmp/hme1` > /tmp/hme2;pr -F -m -t /tmp/hme1 /tmp/hme2
# Stacey, 24/3/97

# get_ndd_info(): $NDD is set before this routine is called.
# argument 1 is the variable name we are interested in, and
# although not seen here it is used within the $NDD variable.
get_ndd_info(){
	echo "$1|$2|$3|`$NDD`" | \
	awk -F\| \
	'BEGIN {tab="                                                  "} \
	{
	 if ( substr($4,length($4),1) == "0" ) { \
	   ans=$2 } \
	 else if ( substr($4,length($4),1) == "1" ) { ans=$3 } \
	  else { ans="("$1" = "$4")" } \
	printf("%s %s(%s = %s)\n",ans, \
	 substr(tab,length(ans),50),$1,$4)}'
}

# 16/Feb/98 : 1.5:  INSTANCES should be space seperated....
# 11/Feb/98 : 1.4:  Ultra platform reports onboard hme as 'network'!
# get_instances: find the instance numbers of hme cards installed.
get_instances(){
case $OS in
5.*)
	INSTANCES=`prtconf | nawk -F# '/network/ || /eri/ {printf("%d ",$2)}'`
## For Solaris testing with no eri...
#        INSTANCES=1
	;;
*)
	INSTANCES=`echo "hmeps/4X" | adb -k /vmunix /dev/mem |
		nawk 'BEGIN { FS = ":"; RS="" }
		{ print \$NF }' | 
		nawk '{for (i = 1; i <= NF; i++) {
		if ($i != 0)
		printf "%s ", $i
		}}'`
	;;
## For SunOS testing with no hme...
# *) INSTANCES=1
esac
}

set_instance(){
case $OS in
5.*)
## Comment out the following line if testing on Solaris without HME
 	/usr/sbin/ndd -set /dev/eri instance $1
	;;
*)
	get_eri_info $1
	;;
esac
}

get_eri_info() {
  parameters=`echo "$1+0x130/29D" | adb -k /vmunix /dev/mem | nawk '/physmem/ { next }
                               {print substr($0,index($0,":")+1,length($0))}'`
## For SunOS testing
# parameters='0 1 0 0 8 4 0 0 1 0 0 1 0 1 1 0 0 1 0 1 0 0 0 0 0 0 0 1 16'
 i=0
 for param in $parameters ; do
   i=`expr $i + 1`
   case $i in
     1)	HMEtransceiver_inuse=$param ;;
     2) HMElink_status=$param ;;
     3) HMElink_speed=$param ;;
     4) HMElink_mode=$param ;;
     5) HMEipg1=$param ;;
     6) HMEipg2=$param ;;
     7) HMEuse_int_xcvr=$param ;;
     8) HMEpace_size=$param ;;
     9) HMEadv_autoneg_cap=$param ;;
    10) HMEadv_100T4_cap=$param ;;
    11) HMEadv_100fdx_cap=$param ;;
    12) HMEadv_100hdx_cap=$param ;;
    13) HMEadv_10fdx_cap=$param ;;
    14) HMEadv_10hdx_cap=$param ;;
    15) HMEautoneg_cap=$param ;;
    16) HME100T4_cap=$param ;;
    17) HME100fdx_cap=$param ;;
    18) HME100hdx_cap=$param ;;
    19) HME10fdx_cap=$param ;;
    20) HME10hdx_cap=$param ;;
    21) HMElp_autoneg_cap=$param ;;
    22) HMElp_100T4_cap=$param ;;
    23) HMElp_100fdx_cap=$param ;;
    24) HMElp_100hdx_cap=$param ;;
    25) HMElp_10fdx_cap=$param ;;
    26) HMElp_10hdx_cap=$param ;;
    27) HMEinstance=$param ;;
    28) HMElance_mode=$param ;;
    29) HMEipg0=$param ;;
    *) ;;
   esac
 done
}

check_root_id()
{
# Check that the users id is root 
 
   id | grep root >/dev/null 
   if [ $? -ne 0 ]
        then 
        echo "Only the super-user can execute this script " 
        abort 
   fi 
} 
 
get_version() {

	VERSION=`strings /kernel/drv/eri |grep "FEPS Ethernet Driver"`

}

##
##  Start
##

check_root_id
get_version
OS=`uname -r`

case $OS in
  5.*)
	ECHO=/usr/bin/echo
 	NDD='eval /usr/sbin/ndd /dev/eri $1'
	## For Solaris testing with no HME
	# NDD='eval $PWD/ndd /dev/eri $1'
	;;
  *)
	ECHO=/usr/5bin/echo
	NDD='eval eval echo \$HME$1'
	;;
esac

$ECHO "\t\tConfigured Interfaces:\n"
ifconfig -a

$ECHO "\n\n\t\tHME $VERSION"
instance=${1}
get_instances

if [ "$INSTANCES" = "" ]
  then
    $ECHO "\nNo eri interfaces found on host `uname -n`\n"
    exit
fi
echo "Detailing Instances: \"${INSTANCES}\""
for instance in $INSTANCES
	do
	$ECHO "\n\nConfiguration of eri card # $instance.\n"
	$ECHO "NOTE Parameters MAY NOT be accurate if the card is not connected to a HUB/SWITCH"
	$ECHO "or if the interface is unused ( IE: Not plumbed in )."
	$ECHO "Try snooping the device to inititalise it."

	$ECHO "\nLink Paremeters.\n\n"
	set_instance $instance
	get_ndd_info link_status "The link is DOWN" "The link is UP"
	get_ndd_info link_speed "Speed = 10Mb/S" "Speed = 100Mb/S"
	get_ndd_info  link_mode "Mode = Half Duplex" "Mode = Full Duplex"
	get_ndd_info  transceiver_inuse "Using INTERNAL Transiever" "Using EXTERNAL Transiever"
	get_ndd_info  use_int_xcvr "Use External Tranciever if present" "Only use internal tranciever"
	get_ndd_info lance_mode "LANCE mode is DISABLED" "LANCE mode is ENABLED"
	get_ndd_info adv_autoneg_cap "Will NOT auto negotiate" "WILL auto negotiate"
	get_ndd_info lp_autoneg_cap "Link partner (switch) DOES NOT auto-negotiate" "Link partner (switch) HAS auto-negotiate ability"

	$ECHO "\nMisc parameters.\n\n"

	get_ndd_info pace_size "Number of back to back packets" "Number of back to back packets"
	get_ndd_info ipg0 "ipg0" "ipg0"
	get_ndd_info ipg1 "ipg1" "ipg1"
	get_ndd_info ipg2 "ipg2" "ipg2"
	
	$ECHO "\nCard is set to advertise the following:\n"

	get_ndd_info adv_100T4_cap "100T4 = NO" "100T4 = YES"
	get_ndd_info adv_100fdx_cap "100FDX = NO" "100FDX = YES"
	get_ndd_info adv_100hdx_cap "100HDX = NO" "100HDX = YES"
	get_ndd_info adv_10fdx_cap "10FDX = NO" "10FDX = YES"
	get_ndd_info adv_10hdx_cap "10HDX = NO" "10HDX = YES"

	$ECHO "\nThe card Supports the following:\n"

	get_ndd_info 100T4_cap "100T4 = NO" "100T4 = YES"
	get_ndd_info 100fdx_cap "100FDX = NO" "100FDX = YES"
	get_ndd_info 100hdx_cap  "100HDX = NO"  "100HDX = YES"
	get_ndd_info 10fdx_cap "10FDX = NO" "10FDX = YES"
	get_ndd_info 10hdx_cap "10HDX = NO" "10HDX = YES"
	get_ndd_info autoneg_cap "Auto Negotiation = NO" "Auto Negotiation = YES"

	$ECHO "\nThe HUB/SWITCH has advertised the following:\n"


	get_ndd_info lp_autoneg_cap "Link partner (switch) DOES NOT auto-negotiate"  "Link partner (switch) DOES HAVE auto-negotiate ability"
	$ECHO "\nThe following are ONLY valid if the Switch/HUB supports Auto Negotiation\n"

	get_ndd_info lp_100T4_cap "100T4 = NO" "100T4 = YES"
	get_ndd_info lp_100fdx_cap "100FDX = NO" "100FDX = YES"
	get_ndd_info lp_100hdx_cap "100HDX = NO" "100HDX = YES"
	get_ndd_info lp_10fdx_cap "10FDX = NO" "10FDX = YES"
	get_ndd_info lp_10hdx_cap "10HDX = NO" "10HDX = YES"

done
