# xamarin-practicum
Simple automated deployment script of a PayPal REST API demo app on both CentOS 7 and Ubuntu 14.04.2 LTS.

This script assumes that the machine is running either:
 - CentOS 7
 - Ubuntu 14.04.2 LTS
and that only git is installed on top of the base system (though if the script isn't being deployed from git this is unnecessary). All other dependencies required for deployment will be installed. MySQL root password will be printed at the end of the install.

Simply run ./deploy.sh, and the script will detect the OS and set everything up.
