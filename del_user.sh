#!/bin/bash
# save as /root/del_user.sh

USERNAME=$1
if [[ -z "$USERNAME" ]]; then
    echo "Please give me a username"
    exit 1
fi

echo "This script will"
echo "1. Stop & remove lxc container $USERNAME"
echo "2. userdel -f -r $USERNAME"
echo ""
read -p "Are you sure (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    lxc stop $USERNAME
    lxc rm $USERNAME
    rm /var/scripts/ports/$USERNAME
    userdel -f -r $USERNAME
    echo "Done!"
else
    echo "Canceled"
    exit 1
fi