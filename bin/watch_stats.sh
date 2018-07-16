#!/bin/bash

# Stat arrays
temps=()
watts_max=()
#watts_avg=()
watts=()
mclks=()
sclks=()
fan_perc=()

if command -v nvidia-smi &> /dev/null
then
# nvidia-smi --help-query-gpu
# nvidia-smi --query-gpu=temperature.gpu,clocks.mem,clocks.sm,power.draw,fan.speed --format=csv | tail -n +2
# IFS=$'\n' fan_perc=($(nvidia-smi --query-gpu=fan.speed --format=csv | tail -n +2))
# fan_perc=(${fan_perc[@]%% '%'*})

# IFS=$'\n' temps=($(nvidia-smi --query-gpu=temperature.gpu --format=csv | tail -n +2))

# IFS=$'\n' mclks=($(nvidia-smi --query-gpu=clocks.mem --format=csv | tail -n +2))
# mclks=(${mclks[@]%% MHz*})

# IFS=$'\n' sclks=($(nvidia-smi --query-gpu=clocks.sm --format=csv | tail -n +2))
# sclks=(${sclks[@]%% MHz*})

# IFS=$'\n' watts=($(nvidia-smi --query-gpu=power.draw --format=csv | tail -n +2))
# watts=(${watts[@]%% W*})

# Fastest way, one query
	IFS=$'\n' stats=($(nvidia-smi --query-gpu=temperature.gpu,clocks.mem,clocks.sm,power.draw,fan.speed --format=csv | tail -n +2))
	for stat in "${stats[@]}"
	do
		IFS=, read -a stat_arr <<< "${stat//[[:blank:]]/}"
		temps+=(${stat_arr[0]})
		mclks+=(${stat_arr[1]%%MHz*})
		sclks+=(${stat_arr[2]%%MHz*})
		watts+=(${stat_arr[3]%W*})
		fan_perc+=(${stat_arr[4]%%'%'*})
	done
fi

if dpkg -l amdgpu-pro &> /dev/null
then
	# Get gpu info from /sys/kernel/debug/dri/
	gpu_files=(/sys/kernel/debug/dri/*/amdgpu_pm_info)
	for i in "${!gpu_files[@]}"
	do
		if [[ ! -f "${gpu_files[$i]}" ]]
		then
			continue
		fi

		while read -r line_space
		do
			line="${line_space//[[:blank:]]/}"
			case $line in
				*Temperature*)
					temp=${line##*ture:}
					temp=${temp%%C*}
					temps[$i]=$temp
				;;
				*max*)
					watt_max=${line%%W*}
					watts_max[$i]=$watt_max
					watts[$i]=$watt_max
				;;
				*average*)
					watt_avg=${line%%W*}
					watts_avg[$i]=$watt_avg
				;;
				*'(MCLK)'*)
					mclk=${line%%MHz*}
					mclks[$i]=$mclk
				;;
				*'(SCLK)'*)
					sclk=${line%%MHz*}
					sclks[$i]=$sclk
				;;

				*)
					# Discard
				;;
			esac
		done < <(cat "${gpu_files[$i]}") # 200 miliseconds
		#done <"${gpu_files[$i]}" # 7788 miliseconds ?? mabey not regular file? 
	done

	# Get fan percentage
	fan_files=(/sys/class/drm/card*/device/hwmon/hwmon*/pwm1)
	for i in "${!fan_files[@]}"
	do
		if [[ ! -f "${fan_files[$i]}" ]]
		then
			continue
		fi
		fan_pwm=$(cat ${fan_files[$i]})
		fan_per=$(( fan_pwm*100/255 ))
		fan_perc[$i]=$fan_per
	done
fi # amd

echo "${temps[@]}" > "$TEMP_FILE" || exit 2
echo "${watts[@]}" > "$WATTS_FILE" || exit 2
echo "${mclks[@]}" > "$MCLKS_FILE" || exit 2
echo "${sclks[@]}" > "$SCLKS_FILE" || exit 2
echo "${fan_perc[@]}" > "$FAN_PER_FILE" || exit 2


exit 0
