# xamarin-practicum
Simple automated deployment script of a PayPal REST API demo app on both CentOS 7 and Ubuntu 14.04.2 LTS.

This script assumes the following environment under CentOS 7:
 - Clean, minimal install (image used in testing was CentOS-7-x86_64-DVD-1503-01.iso)
 - Only package assumed to be install on top of the base system is git (to download this in the first place)
 - User is local, or on one of the trusted subnets (10.0.0.0/8, 172.0.0.0/8, 192.168.0.0/16)

This script will be updated for Ubuntu 14.04.2 LTS shortly.
