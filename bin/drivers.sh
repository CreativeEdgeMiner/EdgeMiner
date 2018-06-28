#!/bin/bash

if [[ -z "$MINE_SCRIPT_DIR" || -z "$MINE_LOG" || -z  "$ERROR_LOG_FILE" ]]
then
	echo "Set exports"
	exit 1
fi

add_to_rc_local()
{
	line_num=1
	cmd="$(echo $@)"
	while IFS='' read -r rc_line || [[ -n "$rc_line" ]]
	do
		if [[ "$rc_line" = "$cmd" ]]
		then
			# already added
			return 0
		fi
		if [[ "$rc_line" = "exit 0" ]]
		then
			sudo sed -i "$line_num"'i'"$cmd" '/etc/rc.local'
			break
		fi
		((line_num++))
	done <'/etc/rc.local'
}

remove_from_rc_local()
{
	line_num=1
	cmd="$(echo $@)"
	while IFS='' read -r rc_line || [[ -n "$rc_line" ]]
	do
		if [[ "$rc_line" = *"$cmd"* ]]
		then
			sudo sed -i -e "$line_num"'d' '/etc/rc.local'
			return 0
		fi
		if [[ "$rc_line" = "exit 0" ]]
		then
			return 1
		fi
		((line_num++))
	done <'/etc/rc.local'
}

uninstall_drivers()
{
	[[ -e "/etc/modprobe.d/nvidia-graphics-drivers.conf" ]] && rm "/etc/modprobe.d/nvidia-graphics-drivers.conf"
	[[ -e "/etc/modprobe.d/blacklist-nouveau.conf" ]] && rm "/etc/modprobe.d/blacklist-nouveau.conf"
	[[ -e "/etc/profile.d/10-cuda.sh" ]] && rm "/etc/profile.d/10-cuda.sh"

	# Cuda devpacks
	[[ -e "/var/cuda-repo-"* ]] && rm -r "/var/cuda-repo-"*
	[[ -e "/usr/local/cuda"* ]] && rm -r "/usr/local/cuda"*	
	# Cuda runfile uninstall
	command -v /usr/local/cuda-*/bin/uninstall_cuda_*.pl && /usr/local/cuda-*/bin/uninstall_cuda_*.pl
	# cuda debfile uninstall
	dpkg -l cuda* &> /dev/null && apt-get --purge remove cuda*
	# Nvidia driver uninstall
	command -v /usr/bin/nvidia-uninstall && /usr/bin/nvidia-uninstall
	dpkg -l nvidia-* &> /dev/null && apt-get --purge remove nvidia-*

	# amd driver uninstall
	command -v amdgpu-pro-uninstall && amdgpu-pro-uninstall

	echo "Driver Uninstall Script finished.  Reboot to finish driver uninstall"
}

nvidia_get_file()
{
	install_file="${install_url##*/}"
	wget -O "$install_file" -c "${install_url%.*}" || { echo "Download Failed from $install_url" | tee -a "$ERROR_LOG_FILE" "$MINE_LOG" ; return 1 ; }

	echo "Check MDM5 of download:   TODO"

	declare -p version
	declare -p install_file
}

# Set install_file
# Set version
cuda_install()
{
	if ! dpkg -l gcc &> /dev/null
	then
		apt install -y gcc
	fi

	if ! dpkg -l linux-headers-$(uname -r) &> /dev/null
	then
		apt install -y linux-headers-$(uname -r)
	fi

	add-apt-repository ppa:graphics-drivers/ppa
	apt update

	case "$install_file" in 
		*.deb)
			if ! dpkg -i "$install_file" | tee -a "$MINE_LOG"
			then
				echo "Failed dpkg add. See $MINE_LOG" | tee -a "$MINE_LOG" "$ERROR_LOG_FILE"
				return 2
			fi
			readarray  -t keys < <(find /var/cuda-repo-$version* -name '*.pub')
			if ! apt-key add "${keys[0]}" | tee -a "$MINE_LOG"
			then
				echo "Failed apt-key add. See $MINE_LOG" | tee -a "$MINE_LOG" "$ERROR_LOG_FILE"
				return 2
			fi
			if ! apt update
			then
				echo "Failed cmd: 'apt update' during nvidia-cuda install" | tee -a "$MINE_LOG" "$ERROR_LOG_FILE"
				return 2
			fi
			if ! apt install "cuda" | tee -a "$MINE_LOG"
			then
				echo "Failed cmd: 'apt install cuda'. See $MINE_LOG" | tee -a "$MINE_LOG" "$ERROR_LOG_FILE"
				return 2
			fi
		;;
		cuda_*_linux-run)
			# Blacklist nouveau drivers
			#echo "blacklist nouveau" > "/etc/modprobe.d/blacklist-nouveau.conf"
			#echo "options nouveau modeset=0" >> "/etc/modprobe.d/blacklist-nouveau.conf"
			#update-initramfs -u
			echo "TODO:  Runfile Install"

			return 1
		;;
	esac

	add_to_rc_local "$MINE_SCRIPT_DIR"'edgeminer --post-cuda-auto-install >>'"$MINE_SCRIPT_DIR""$MINE_LOG"

	# echo "Post install actions and a reboot are required"
	# if prompt.sh 'Automatically restart and perform CUDA post insall actions?'
	# then
	# 	setup.sh --add_to_rc_local "$MINE_SCRIPT_DIR"'/mine setup --drivers --post-cuda-auto-install >>'"$MINE_SCRIPT_DIR"/"$MINE_LOG"
	# 	reboot
	# else
	# 	echo "Manually restart and then run post-install actions with ./mine setup --drivers --post-cuda-install"
	# fi
}

cuda_post_install()
{
	# Envrionment setup
	var=(/usr/local/cuda-*/bin)
	var2=(/usr/local/cuda-*/lib64)
	if [[ -d "${var[0]}" ]]
	then
		echo '#!/bin/sh' > /etc/profile.d/10-cuda.sh
		echo 'export PATH=$PATH:'"${var[0]}" >> /etc/profile.d/10-cuda.sh
		if [[ -d "${var2[0]}" ]]
		then
			echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:'"${var2[0]}" >> /etc/profile.d/10-cuda.sh
		fi
	fi

	# idk if this is needed for runfile only?
	#./mine setup --add_to_rc_local /usr/bin/nvidia-persistenced --verbose

	# Allow setting fan speed and overclocking.
	# Sometimes this breaks Ubuntu-desktop gui
	nvidia-xconfig -a --allow-empty-initial-configuration --cool-bits=28 --use-display-device=DFP-0 --connected-monitor=DFP-0
}

amd_get_file()
{
	#install_file="${install_url##*/}"
	#wget -q -O "$install_file" -c "$install_url" || { echo "Download Failed from $install_url" | tee -a "$ERROR_LOG_FILE" "$MINE_LOG" ; return 1 ; }
	tar -Jxvf "$install_file"
	install_folder="${install_file%%.tar*}"

	declare -p install_folder
}

# Set install_folder
amd_install()
{
	cd "$install_folder"
	if ./amdgpu-pro-install
	then
		cd "$MINE_SCRIPT_DIR"
		add_to_rc_local "$MINE_SCRIPT_DIR"'edgeminer --post-amd-auto-install >>'"$MINE_SCRIPT_DIR""$MINE_LOG"
		return 0
	else
		echo "AMD Driver install failed" | tee -a "$ERROR_LOG_FILE" "$MINE_LOG"
		return 1
	fi
}

amd_post_install()
{
	for username in /home/*
	do
		usermod -a -G video "$username"
	done
	sed -i '/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/c\GRUP_CMDLINE_LINUX_DEFAULT="quiet splash amdgpu.vm_fragment_size=10"' '/etc/default/grub'
	update-grub
	sleep 10
}

verify_drivers()
{
	dpkg -l cuda* &> /dev/null && cuda_driver=true
	command -v nvidia-smi &> /dev/null && nvidia_driver=true
	dpkg -l amdgpu-pro &> /dev/null && amd_driver=true
	exit_val=1
	[[ -n "$amd_driver" && "$amd_driver" = "true" ]] && { echo "AMD Driver found" | tee -a "$MINE_LOG" ; exit_val=0 ; }
	[[ -n "$nvidia_driver" && "$nvidia_driver" = "true" ]] && { echo "NVIDIA Driver found" | tee -a "$MINE_LOG" ; exit_val=0 ; }
	[[ -n "$cuda_driver" && "$cuda_driver" = "true" ]] && { echo "CUDA Driver found" | tee -a "$MINE_LOG" ; exit_val=0 ; }
	return "$exit_val"
}

key="$1"
case $key in
	--post-amd-auto-install)
		remove_from_rc_local "$MINE_SCRIPT_DIR"'edgeminer --post-amd-auto-install >>'"$MINE_SCRIPT_DIR""$MINE_LOG"
		amd_post_install
		sleep 10
		reboot
		exit 0
	;;

	--post-cuda-auto-install)
		remove_from_rc_local "$MINE_SCRIPT_DIR"'edgeminer --post-cuda-auto-install >>'"$MINE_SCRIPT_DIR""$MINE_LOG"
		cuda_post_install
		sleep 10
		reboot
		exit 0
	;;

	-v|--verify)
		verify_drivers
		exit $?
	;;

	--install)
		if verify_drivers
		then
			echo "Drivers Found.  Run uninstall first"
			exit 0
		fi

		is_nvidia="$2"
		version="$3"

		if [[ "$is_nvidia" -eq 0 ]]
		then
			install_url="$4"
			nvidia_get_file
			if cuda_install
			then
				echo "Rebooting"
				sleep 10
				reboot
			fi
			exit 1
		elif [[ "$is_nvidia" -eq 1 ]]
		then
			install_file="$4"
			amd_get_file
			# cd "$install_folder"
			# cd "$MINE_SCRIPT_DIR"
			# add_to_rc_local "$MINE_SCRIPT_DIR"'edgeminer --post-amd-auto-install >>'"$MINE_SCRIPT_DIR""$MINE_LOG"
			if amd_install
			then
				echo "Rebooting"
				sleep 10
				reboot
			fi
			exit 1
		fi
	;;

	--uninstall)
		if ! verify_drivers
		then
			echo "No drivers Found."
			exit 0
		fi
		uninstall_drivers
		exit 0
	;;
    *)    # first option is print promt, then responce options
   	echo "discarding option $1"
	shift # past argument
    ;;
esac

