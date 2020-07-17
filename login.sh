#!/bin/bash
function print_help {
    echo 
    echo "==========About your container:"

    INFO=$(lxc info $USER)
    echo "$INFO" | grep Running > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        printf "\e[96;1mYour container is not running.\e[0m\n"
    else
        printf "\e[96;1mYour container is running.\e[0m\n"
    fi
    printf "Transfer data to your container using scp or sftp;\n"
    printf "File sharing is encouraged, access datasets at \e[96;1mshared/datasets\e[0m, access download files at \e[96;1mshared/downloads\e[0m, etc\n"
    printf "\nSee GPU load: \e[96;1mnvidia-smi.\e[0m\n    memory usage: free -h.\n    disk usage: df -h.\n "
    echo " "
}

function do_stop {
    echo "========== Stopping your container..."
    lxc stop $USER
}

function do_passwd {
    echo "========== Changing your password (host only)..."
    passwd $USER
}

function allocate_port {
    echo "========== Preserve a port for your application, e.g. tensorboard, jupyter ..."
    PORT=$(cat /var/scripts/ports/$USER)
    read -p "Enter a port id (you can use 9 port denoted as 1-9): " input_id
    if [[ $input_id > 9 ]]; then
        echo "Wrong id."
        allocate_port
    fi
    read -p "Enter port of your application (e.g. default port of tensorboard is 6006): " input_port
    lxc config device add $USER proxy$input_id proxy listen=tcp:0.0.0.0:$(( $PORT+$input_id )) connect=tcp:127.0.0.1:$input_port
    echo "Done. You can access your application via port $(( $PORT+$input_id )) now."
}

function release_port {
    echo "========== Release a port."
    PORT=$(cat /var/scripts/ports/$USER)
    read -p "Enter the port id you want to release (1-9): " input_id
    if [[ $input_id > 9 ]]; then
        echo "Wrong id."
        release_port
    fi
    lxc config device remove $USER proxy$input_id
    echo "Done."
}

function do_start {
    PORT=$(cat /var/scripts/ports/$USER)
    INFO=$(lxc info $USER)
    echo "$INFO" | grep Running > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "========== Starting your container..."
        lxc start $USER

        sleep 3
        echo ""
    else
        echo "It seems that your container is running."
    fi
    #echo "username: root"
    #echo "password: 1 as default, change your password when you login"
    #echo "ssh port: $PORT"
    echo 
    #echo "Connect your container directly via \`ssh root@<host-ip> -p $PORT\`, default password is 1."
    #echo "Transfer data to the container directly using sftp with info above."
}

function do_run {
    ln -s /var/lib/lxd/storage-pools/default/containers/$USER/rootfs/root $HOME/root-in-container
    lxc exec $USER bash
}

function do_run_tunnel {
    ln -s /var/lib/lxd/storage-pools/default/containers/$USER/rootfs/root $HOME/root-in-container
    read -p "Enter the port: " RPORT
    ssh -R $RPORT:localhost:$RPORT root@$(lxc list | grep $USER | cut -f4 -d \| | cut -f 1 -d \( | tr -d '[:space:]')
}

function menu {
    echo ""
    echo "===== main menu  ====="
    echo "[1] start your container"
    echo "[2] enter your container"
    echo "[20] enter your container with tunnel"
    echo "[3] stop your container"
    echo "[4] change your password"
    echo "[5] allocate ports"
    echo "[6] release ports"
    echo "[0] show info"
    echo "[x] exit"
    read -p "Enter your choice: " op
    if   [ "$op" == "1" ];
        then do_start
        read -p "Press any key to continue..." -n 1 -r
        menu
    elif   [ "$op" == "2" ];
       then do_run
       menu
    elif   [ "$op" == "20" ];
       then do_run_tunnel
       menu
    elif   [ "$op" == "3" ];
       then do_stop
       read -p "Press any key to continue..." -n 1 -r
       menu
    elif [ "$op" == "4" ];
        then do_passwd
        read -p "Press any key to continue..." -n 1 -r
        menu
    elif [ "$op" == "5" ];
        then allocate_port
        read -p "Press any key to continue..." -n 1 -r
        menu
    elif [ "$op" == "6" ];
        then release_port
        read -p "Press any key to continue..." -n 1 -r
        menu
    elif [ "$op" == "0" ];
        then
        lxc info $USER
        read -p "Press any key to continue..." -n 1 -r
        menu
    elif [ "$op" == "x" ];
    then
        exit 1
    elif [[ -z "$op" ]];
        then do_start
    else
        echo "========== Unknown command"
        read -p "Press any key to continue..." -n 1 -r
        print_help
        menu
    fi
}

printf "\n\n Hi, \e[96;1m$USER\e[0m\n"
echo " You're using the GPU Server in Vision Group."
print_help
menu

echo "========== Have a nice day :-)"
