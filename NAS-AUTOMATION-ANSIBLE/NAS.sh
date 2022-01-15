#!/bin/bash

clear
which figlet &>> /dev/null
if [ $? -eq 0 ]
then 
    figlet NAS Automation 
    echo -e "   By:\t\tShrit Shah\tHarshil Shah\tNisarg Khacharia"
else
    echo -e "\v\v \t\t\t\t NAS AUTOMATION \n"
fi


new_setup()

{
    client_ip=$(hostname -I | awk {'print $1}')
    echo -e "\vWhere do you want to setup your storage server? \n\n\t1) Another system on the same LAN. \n\t2) In a cloud virtual machine.\n\n\t Press ESC and enter to go back to main menu"
    read -p "--> " server_location

    #if [ $server_location -eq "1" ]    ERROR: If none selected than error of "unary operator expected" comes at line 20 and 175
    #then

    case $server_location in 

        1)
            

            ############################ Inastalling ansible and calling spin2 function #############################

            #echo -e "\nInstalling ansible for server side configuration"
            spin2 "Installing ansible-4.6.0  " &
            pid=$!
            ansible_install
            echo -e "\n"
            kill $pid 2>&1 >> /dev/null
            #echo -e "\n"
            tput cnorm
            echo ""

            ##########################################################################################################


            # reading Client Private IP-address from client machine and taking server private IP address from user

            #client_ip=$(hostname -I | awk {'print $1}')
            read -p "Enter private ip-address of the server system: " server_ip

            
            # IP validation - REGEX: ((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}


            ################ Running ping command to check connectivity between server and client ######################

            #echo -e "\nEstablishing connection to $server_ip "
            spin2 "Establishing Connection to $server_ip  "  &    #adding loading animation to above echo line
            pid=$!
            ping -c 5 $server_ip &>> /dev/null
            ping_process=$?   #Storing return code of above command in ping_process variable
            echo -e "\n"
            kill $pid 2>&1 >> /dev/null
            tput cnorm
            echo ""

            ############################################################################################################


            if [ $ping_process -eq 0 ]
            then 
                echo -e "Connection Successful\n"

                # Asking user for server's user name
                read -p "Enter Server username: " user_name   
                echo -e "\n\033[3mPassword you type will not be visible on screen but will be recorded\033[0m\n"
                # Asking user for server's password
                read  -s -p "Enter ${user_name}'s password: " user_pass
                #echo -e "\n"

                
                ########################## Configuration of ansible on client machine ###################################

                #echo -e "\nConfiguring ansible and setting up neccessary config files"
                echo -e "\nCollecting server --> ${user_name}'s HOME directory path!!!"
                #ssh-keygen -R ${server_ip}
                #cmd1=$(echo "echo $HOME > /tmp/temp.txt")
                #ssh ${user_name}@${server_ip} $cmd1
                read -p "Enter ${server_ip}'s Home location: " server_home_dir
                client_home_dir=$HOME

                #spin2 "Configuring ansible and setting up neccessary config files  "  &
                #pid=$!
                ansible_setup ${server_ip} ${user_name} ${user_pass}
                if [ $? -eq 3 ]
                then
                    echo -e "\n"
                    #kill $pid 2>&1 >> /dev/null
                    #tput cnorm
                    #echo ""
                elif [ $? -eq 1 ]
                then
                    #kill $pid 2>&1 >> /dev/null
                    exit
                fi

                #########################################################################################################



                #scp server.sh  ${usr_name}@${server_ip}:/tmp/ &>> /dev/null
                #echo -e "\n"
                read -p "Name the backup folder on the Server: " server_dir  # Asking user to type in server side backup folder's name

                ########################## Configuring NAS server in server machine by executing ansible playbook ##########################

                #echo -e "\nConfiguring NAS server. Running ansible playbook"
                echo -e "\nHome directory of ${server_ip} is '${server_home_dir}'"


                #echo -e "${server_home_dir}/Desktop/${server_dir} *(rw,no_root_squash)" > ${server_home_dir}/Desktop/.NAS/exports.j2
                spin2  "Configuring NAS server. Running ansible playbook  "  &
                pid=$!
                sudo ansible-playbook ./nas-playbook.yml --extra-vars "server_home_dir=${server_home_dir} server_dir=${server_dir}" >> /dev/null
                play_process=$?
                echo -e "\n"
                kill $pid &>> /dev/null
                tput cnorm
                echo ""

                #############################################################################################################################



                if [ $play_process -eq 0 ]
                then
                
                    echo -e "\n Server configuration successfull.\n \033[1m(${server_ip})\033[0m node is now configured as \033[4mNAS Backup Server\033[0m\n"
                    echo -e "Name and location of Backup folder on server with ip-->(${server_ip}) is '\033[1m${server_home_dir}/Desktop/${server_dir}/\033[0m'\n"
                    echo -e "Now for configuring client...\n\n"
                    
                    read -p "Name the backup folder here on the Client: " client_dir  # Asking user to type in client side backup folder's name that will be mounted on server
                    mkdir ${client_home_dir}/Desktop/${client_dir} &>> /dev/null
                    
                    df -h | grep ${client_home_dir}/Desktop/${client_dir}
                    if [ $? -eq 1 ]
                    then
                        spin2 "Mounting client folder onto server folder" &
                        pid=$!
                        echo -e "\n"
                        sudo mount  ${server_ip}:${server_home_dir}/Desktop/${server_dir}  /${client_home_dir}/Desktop/${client_dir} &>> /dev/null #Mounting directories
                        mount=$?
                        sleep 5
                        echo -e "\n"
                        kill $pid 2>&1 >> /dev/null
                        tput cnorm
                        echo ""
                        if [ $mount -eq 0 ]
                        then
                            #if [ -d ${HOME}/Desktop/${client_dir} -a $? -eq 0 ]
                            #then    
                            echo -e "Setup on both client and server \033[1mSUCCESSFULL\033[0m\n\n"
                            echo -e "Name and location of Backup folder on your client machine having ip-->(${client_ip}) and Username-->${user_name} is '\033[1m${HOME}/Desktop/${client_dir}\033[0m'\n" 
                        else 
                            echo "mount operation on client side FAILED"
                        fi
                        echo -e "\n Finalizing Setup...\t[This may take a minute]\n"
                        cp Thank_You.txt ${HOME}/Desktop/${client_dir}/
                        echo -e "\v\tSetup Successful\n"

                    else
                        echo -e "Setup on both client and server \033[1mSUCCESSFULL\033[0m\n\n"
                    fi
                else
                    echo -e "Server Configuration failed, playbook didn't executed\n"	
                
                fi
                
            else
                echo "Connection Failed"           
            fi
            
            ;;


#Remove after examining-----------------------------------------------------------------------------------------------------------------------------
#                if [ $? -eq 0 ]
#                then
#                    echo -e "\nSSH connection successful\n"
#                    
#                    read -p "Name of backup folder on the Server: " server_bak_dir
#                    cmd=$(echo sudo -S -p "Enter\ sudo\ password\ of\ server-side: " bash /tmp/server.sh ${usr_name} ${server_bak_dir} ${client_ip})
#                    echo "\nConfiguring NAS server on $server_ip ...\n"
#                    ssh ${usr_name}@${server_ip} $cmd
#                    if [ $? -eq 0 ]
#                    then   
#                        echo -e "\nServer configuration successful\n"
#                        read -p "Name of backup folder here on the Client: " client_dir
#                        mkdir ${HOME}/Desktop/${client_dir}
#                        
#                        if [ $? -eq 0 ]
#                        then    
#                            echo -e "\v\tSetup Successful"
#                            exit
#                        fi
#                    else
#                        echo "Server configuration failed"
#                    fi
#                else
#                    echo -e "SSH connection failed\nPlease run the below commands manually on the server system & run this script again."
#                    echo -e "\v\tsudo yum -y install openssh \n\tsudo systemctl enable --now sshd"
#                fi
#Remove after examining-----------------------------------------------------------------------------------------------------------------------------



        2)

            #client_ip=$(dig +short myip.opendns.com @resolver1.opendns.com) # Client Public IP-address
            read -p "Enter Public ip-address of the server system: " server_ip
            

            # IP validation - REGEX: ((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}

            ################ Running ping command to check connectivity between server and client ######################

            #echo -e "\nEstablishing connection to $server_ip "
            spin2 "Establishing Connection to $server_ip  "  &    #adding loading animation to above echo line
            pid=$!
            ping -c 5 $server_ip &>> /dev/null
            ping_process=$?   #Storing return code of above command in ping_process variable
            echo -e "\n"
            kill $pid 2>&1 >> /dev/null
            tput cnorm
            echo ""

            ############################################################################################################

            #ping -c 3 $server_ip &>> /dev/null
            if [ $ping_process -eq 0 ]
            then 
                echo -e "Connection Successful\n"

                #read -p "Enter Server username: " user_name
                user_name="ec2-user"
                read -p "Enter location of Cloud-VM's pem Key file: " key_file
                scp -i $key_file server.sh  ${user_name}@${server_ip}:/tmp/ &>> /dev/null
                if [ $? -eq 0 ]
                then
                    echo -e "\nSSH connection successful\n"
                
                    read -p "Name of backup folder on the Server: " server_bak_dir
                    cmd=$(echo sudo bash /tmp/server.sh ${user_name} ${server_bak_dir} ${client_ip})
                    echo -e "\n Configuring NAS server on $server_ip ...\n"
                    ssh -i $key_file ${user_name}@${server_ip} $cmd
                    if [ $? -eq 0 ]
                    then   
                        echo -e "\nServer configuration successful\n"
                        read -p "Name of backup folder here on the Client: " client_dir
                        mkdir ${HOME}/Desktop/${client_dir}

                        if [ $? -eq 0 ]
                        then
                            spin2 "Mounting client folder onto server folder" &
                            pid=$!
                            echo -e "\n"
                            sudo mount  ${server_ip}:/home/${user_name}/Desktop/${server_bak_dir}  ${HOME}/Desktop/${client_dir} #Mounting directories
                            mount=$?
                            sleep 5
                            echo -e "\n"
                            kill $pid 2>&1 >> /dev/null
                            tput cnorm
                            echo ""

                            if [ $mount -eq 0 ]
                            then
                                #if [ -d ${HOME}/Desktop/${client_dir} -a $? -eq 0 ]
                                #then    
                                echo -e "Setup on both client and server \033[1mSUCCESSFULL\033[0m\n\n"
                                echo -e "Name and location of Backup folder on your client machine having private ip-->(${client_ip}) and Username-->${user_name} is '\033[1m${HOME}/Desktop/${client_dir}\033[0m'\n" 
                            else 
                                echo "mount operation on client side FAILED"
                            fi
    
                            echo -e "\n Finalizing Setup...\t[This may take a minute]\n"
                            cp Thank_You.txt ${HOME}/Desktop/${client_dir}/
                            echo -e "\v\tSetup Successful\n"
                        else
                            echo -e "\n ${client_dir} --> folder creation failed!!!"
                        fi
                    else
                        echo "Server configuration failed"
                    fi
                else
                    echo -e "SSH connection failed\nPlease run the below commands manually on the server system & run this script again."
                    echo -e "\v\tsudo yum -y install openssh \n\tsudo systemctl enable --now sshd"
                fi
            else
                echo "Connection Failed"
            fi
            ;;

        
        $'\e')
            clear
            main
            ;;
        

        *)
            echo -e "\vSelect valid option from the menu"
            ;;

    esac
}




add_clients()
{

    echo -e "\t\033[1mNOTE:\033[0m clients are supposed to be on same LAN for this function to Work\n\n"
    read -p "Enter client node's  private IP address: " client_priv_ip

    ##################### Running ping command to check connectivity with client #############################

            #echo -e "\nEstablishing connection to $server_ip "
            spin2 "Establishing Connection to ${client_priv_ip}  "  &    #adding loading animation to above echo line
            pid=$!
            ping -c 5 $client_priv_ip &>> /dev/null
            ping_process=$?   #Storing return code of above command in ping_process variable
            echo -e "\n"
            kill $pid 2>&1 >> /dev/null
            tput cnorm
            echo ""

            if [ $ping_process -eq 0 ]
            then
                echo -e "\nConnection Successful\n"
                read -p "Name of backup folder to be created on $client_priv_ip: " client_dir
                mkdir ${HOME}/Desktop/${client_dir} &>> /dev/null
                echo -e "\vWhere is your server located? \n\n\t1) Another system on the same LAN. \n\t2) In a cloud virtual machine.\n\n\t Press ESC and enter to go back to main menu"
                read -p "--> " server_location

                case $server_location in

                    1)
                        read -p "Enter the NAS server's folder name that is already created: " server_bak_dir
                        read -p "Enter the NAS server's private ip address: " server_ip
                        ssh-keygen -R ${client_priv_ip}
                        ssh $client_priv_ip mkdir /root/Desktop/$client_dir
                        ssh $client_priv_ip sudo mount ${server_ip}:/root/Desktop/${server_bak_dir}  /root/Desktop/${client_dir} &>> /dev/null
                        if [ $? -eq 0 ]
                        then
                            #if [ -d ${HOME}/Desktop/${client_dir} -a $? -eq 0 ]
                            #then    
                            echo -e "Setup on both client \033[1mSUCCESSFULL\033[0m\n\n"
                            echo -e "Name and location of Backup folder on your client machine having ip-->(${client_priv_ip}) is '\033[1m/root/Desktop/${client_dir}\033[0m'\n" 
                        else 
                            echo "mount operation on client side FAILED"
                        fi
                        ;;

                    2)  
                        read -p "Enter the NAS server's folder name that is already created: " server_bak_dir
                        read -p "Enter the NAS server's public ip address: " server_ip
                        ssh-keygen -R ${client_priv_ip}
                        ssh $client_priv_ip mkdir /root/Desktop/$client_dir
                        ssh $client_priv_ip sudo mount ${server_ip}:/home/ec2-user/Desktop/${server_bak_dir}  /root/Desktop/${client_dir} &>> /dev/null
                        if [ $? -eq 0 ]
                        then
                            #if [ -d ${HOME}/Desktop/${client_dir} -a $? -eq 0 ]
                            #then    
                            echo -e "Setup on both client \033[1mSUCCESSFULL\033[0m\n\n"
                            echo -e "Name and location of Backup folder on your client machine having ip-->(${client_priv_ip}) is '\033[1m/root/Desktop/${client_dir}\033[0m'\n" 
                        else 
                            echo "mount operation on client side FAILED"
                        fi
                        ;;

                    $'\e')
                        clear
                        main
                        ;;

                    *)
                        echo -e "\vSelect valid option from the menu"
                        ;;
                esac
            else
                echo -e "\n Connection failed"
            fi

}



uninstall()
{
    echo "Coming Soon!!"
}




ansible_install()
{
    #installing ansible on client machine

    ansible_version="ansible 2.10.14"
    pip3 show ansible >> /dev/null

    if [ $? -eq 1 ]
    then
	    sudo pip3 install --no-cache-dir --disable-pip-version-check -q 'ansible==2.10.2'
	    pip3 show ansible >> /dev/null
	    if [ $? -eq 0 ]
	    then
		    echo -e "\n\n\033[1mSuccessefully installed ansible-2.10.2 ansible-base-2.10.14\033[0m"
        fi

    #elif [[ `ansible --version | sed -n 1p` =~ $ansible_version ]]
    #then
    else
        echo -e "\n\n\033[1mAnsible pre-installed ansible-2.10.2 ansible-base-2.10.14\033[0m"
    
    fi
}




ansible_setup()
{
    #configuring inventory file for ansible

    server_ip="$1"
    usr_name="$2"
    usr_pass="$3"
    home_dir="$HOME"
    connection_type="ssh"
    [ -f ${home_dir}/Desktop/.NAS/.ip.txt ]
    if [ $? -eq 1 ]
    then
	    mkdir ${home_dir}/Desktop/.NAS
	    #echo "[NASserver]" > /.NAS/.ip.txt
    fi
    echo "${server_ip} ansible_user=${usr_name} ansible_password=${usr_pass} ansible_connection=${connection_type}" > ${home_dir}/Desktop/.NAS/.ip.txt

    #configuring ansible.cfg file

    [ -d /etc/ansible/ ]
    if [ $? -eq 1 ]
    then
	    sudo mkdir /etc/ansible/
    fi
    echo -e "[defaults]\ninventory=${home_dir}/Desktop/.NAS/.ip.txt\nhost_key_checking=False\ndeprecation_warnings=False\ncommand_warnings=False" | sudo tee /etc/ansible/ansible.cfg &>> /dev/null

    sudo dnf list installed | grep epel-release &>> /dev/null
    if [ $? -eq 1 ]
    then
        sudo ping -c 1 8.8.8.8 &>> /dev/null
        if [ $? -eq 0 ]
        then 
            sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y &>> /dev/null
            sudo dnf upgrade &>> /dev/null
            
            sudo dnf list installed | grep sshpass
            if [ $? -eq 1 ]
            then
                sudo ping -c 1 8.8.8.8 &>> /dev/null    
                if [ $? -eq 0 ]
                then
                    sudo dnf install sshpass -y  &>> /dev/null
                    if [ $? -eq 0 ] 
                    then
                        sudo dnf clean dbcache &>> /dev/null
                        echo -e "\nSuccessfully installed sshpass.x86_64 package!!!"
                    else 
                        echo -e "\nUnable to install required packages!!!"
                        return 1
                    fi
                elif [ $? -eq 2 ]
                then   
                    echo -e "\nPlease check your internet connectivity!!! and re-run program."
                    return 1
                fi
            elif [ $? -eq 0 ]
            then    
                echo -e "\nsshpass.86_64 package is already installed!!!"
            fi
        elif [ $? -eq 2 ]
        then
            echo -e "\nPlease check your internet connectivity!!! and re-run program."
            return 1
        fi

    elif [ $? -eq 0 ]
    then
        sudo dnf upgrade &>> /dev/null
        sudo dnf list installed | grep sshpass
        if [ $? -eq 1 ]
        then
            sudo ping -c 1 8.8.8.8 &>> /dev/null
            if [ $? -eq 0 ]
            then
                sudo dnf install sshpass -y &>> /dev/null
                if [ $? -eq 0 ]
                then 
                    sudo dnf clean dbcache &>> /dev/null
                    echo -e "\nSuccessfully installed sshpass.x86_64 package"
                else
                    echo -e "\nUnable to install required packages"
                    return 1
                fi
            elif [ $? -eq 2 ] 
            then
                echo -e "\nPlease check your internet connectivity and re-run program."
                return 1
            fi
        elif [ $? -eq 0 ]
        then
            echo -e "\nsshpass.86_64 package is already installed!!!"
        fi

    fi

    sleep 5
    return 3
}



spin2() #spin function for rotating the array of \ | -- /
{
        spinner=( '|' '/' "--" '\' )
        var="$1"
        echo -e "\n"
        tput civis
        while [ 1 ]
        do
                for i in ${spinner[@]};
                do
                        echo -ne "\r$var $i ";
                        sleep 0.1;
                done
        done

}


<< load
load_animation()
{
    tput civis
    while [ 1 ]
        do
            echo -ne "."
            sleep 0.5
        done
    tput cnorm
}
load

Backup_func()
{
    read -p "Enter complete path of the folder you want to backup --> " filename
    read -p "Enter path of directory where you want backup to be created --> " backup_dir
    echo -e "\nBackup will be created as 'filename.tar' at '$backup_dir' location\n"
    spin2 "Creating a Compressed backup..." &
    pid=$!
    tar -cf $backup_dir/backup-$(date "+%d-%m-%Y_%H-%M-%S").tar  $filename &>> /dev/null
    success_command=$?
    sleep 5
    echo -e "\n"
    kill $pid 2>&1 >> /dev/null
    tput cnorm
    echo ""

    if [ $success_command -eq 0 ]
    then
        echo -e "\n Backup created!!!"
    else
        echo -e "\nUnable to create backup!!!"
    fi
}

main()
{

    while [ 0 ]
    do
        echo "-----------------------------------------------------------------------------"
        echo -e "\v\t\033[1m\033[4mMain menu\033[4m\033[0m\n\n\t1) Setup new storage \n\t2) Add more clients \n\t3) Create compressed archived Backup\n\n\t Press ESC and enter to exit" #Main Menu

        read  -p "--> " menu_opt

        case $menu_opt in 
            1) 
                clear
                new_setup
                ;;
            2) 
                clear
                add_clients
                ;;

            3)
                clear
                Backup_func
                ;;


            $'\e') 
                echo "Cleaning up and Exiting..."
                sleep 3
                clear
                exit 0 &>> /dev/null
                ;;
            *)
                echo "Select valid option from the menu"
                ;;
        esac
    done
}

main

#exit 0 &>> /dev/null