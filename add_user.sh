#!/bin/bash

### add user
echo "=====Welcome!"


echo "we need to get sudo permission first. Enter the password for \`addu\` below."
sudo ls

echo "=====Let's setup a new account and create a container now."

read -p "Enter your username: " USERNAME

if [[ -z "$USERNAME" ]]; then
    echo "Please give me a username"
    exit 1
fi

# create user
echo "Creating user..."
sudo useradd -m -s /bin/bash -G lxd $USERNAME

printf "Allocating container for \e[96;1m$USERNAME\e[0m...\n"

# config the container
lxc init template ${USERNAME} -p default

# allocate ssh port
printf "Allocating ssh port... "
PORTFILE=/var/scripts/next-port
PORT=$(cat $PORTFILE)
echo $PORT | sudo tee /var/scripts/ports/$USERNAME
echo $(( $PORT+10 )) | sudo tee $PORTFILE
printf "\e[96;1m$PORT\e[0m\n"

lxc config device add ${USERNAME} sshproxy proxy listen=tcp:0.0.0.0:$PORT connect=tcp:127.0.0.1:22

# map uid
lxc config device add $USERNAME door disk source=/home/$USERNAME path=/root/door
printf "uid $(id $USERNAME -u) 0\ngid $(id $USERNAME -g) 0" | lxc config set $USERNAME raw.idmap -

# password
echo "set password for $USERNAME now (host only)."
sudo passwd $USERNAME

echo "Login this host via \`ssh <username>@<host-ip>\` to manage your container."

# bashrc
printf '\nif [[ $- =~ i ]]; then\n    source /var/scripts/login.sh\nfi\n' | sudo tee -a /home/$USERNAME/.bashrc

echo "Done!"

read -p "Press any key to continue..." -n 1 -r
