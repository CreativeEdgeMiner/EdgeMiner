#!/bin/bash

# [[ -z "$SOFTWARE_RUNNING" ]] && SOFTWARE_RUNNING="ethdcrminer64"
# [[ -z "$RUNNING" ]] && RUNNING="eth"
# # [[ -z "$DUAL_RUNNING" ]] && DUAL_RUNNING=""
# # [[ -z "$DUAL_POOL" ]] && DUAL_POOL=""
# # [[ -z "$DUAL_ADDR" ]] && DUAL_ADDR=""
# [[ -z "$POOL" ]] && POOL="us2.ethermine.org"
# [[ -z "$PORT" ]] && PORT="4444"
# [[ -z "$ADDR" ]] && ADDR="34989a5480af30e3ddedb4926f18814dd0ddff96"
# [[ -z "$NAME" ]] && NAME="default"

# [[ -z "$CMD_FILE" ]] && CMD_FILE="./miners/run.sh"
[[ -e "$CMD_FILE" ]] && rm -r "$CMD_FILE"

software_config="./miners/software/$SOFTWARE_RUNNING/$SOFTWARE_RUNNING".conf
[[ ! -f "$software_config" ]] && exit 1


set_val()
{
	case "$1" in 
		'$name')
			echo -n "$NAME"
		;;
		'$software')
			echo -n "$SOFTWARE_RUNNING"
		;;
		'$running')
			echo -n "$RUNNING"
		;;
		'$pool')
			echo -n "$POOL"
		;;
		'$port')
			echo -n "$PORT"
		;;
		'$addr')
			echo -n "$ADDR"
		;;
		'$pass'|'$password')
			echo -n "$PASS"
		;;
		'$dual_running')
			echo -n "$DUAL_RUNNING"
		;;
		'$dual_pool')
			echo -n "$DUAL_POOL"
		;;
		'$dual_port')
			echo -n "$DUAL_PORT"
		;;
		'$dual_addr')
			echo -n "$DUAL_ADDR"
		;;
		'$dual_pass'|'$dual_password')
			echo -n "$DUAL_PASS"
		;;
		'$email')
			echo -n "$EMAIL"
		;;

		*)
			echo -n "$1"
		;;
	esac
}

check_match()
{
	[[ "$1" = "$RUNNING" ]] && return 0
	[[ "$1" = "$ADDR" ]] && return 0
	[[ "$1" = "$POOL" ]] && return 0
	[[ -n "$DUAL_RUNNING" && "$1" = "$DUAL_RUNNING" ]] && return 0
	[[ -n "$DUAL_ADDR" && "$1" = "$DUAL_ADDR" ]] && return 0
	[[ -n "$DUAL_POOL" && "$1" = "$DUAL_POOL" ]] && return 0
	return 1 # fail
}

configured=false
worker=false
separate_port=false # Must set Port Arg

# Needed args
arg_names=()
arg_flags=()
arg_values=()
other_args=()

# Two passes. First pass grabs arguments used and flags for the argument
#	Before the second pass, configure argument values in config/global_software
#	For second pass get values for arguements and flags used.  These will overwrite anything specified in config/global_software
while IFS='' read -r config_line_comments || [[ -n "$config_line_comments" ]]
do
	conf_line=${config_line_comments%%'#'*}
	if [[ -z "$conf_line" ]]
	then
		continue
	fi
	case "$conf_line" in
		*"_arg=")
			# Arg with no setting, ignore
			continue
		;;
		"export "*)
			key="${conf_line%%=*}"
			key="${key##export }"
			value="${conf_line##*=}"
			echo "export $key=$value" >> "$CMD_FILE"
		;;
		"configured_flag"*)
			configured="${conf_line##*_flag=}"
		;;
		"worker_flag"*)
			worker="${conf_line##*_flag=}"
		;;
		"separate_port_flag"*)
			separate_port="${conf_line##*_flag=}"
		;;
		"other_args="*)
			other_args+=(${conf_line##*_args=}) 
			# Note: no quotation marks so whitespace is removed
		;;
		*"_arg="*)
			if [[ -n "${conf_line##*_arg=}" ]]
			then
				arg_names+=("${conf_line%%_arg=*}")
				arg_flags+=("${conf_line##*_arg=}")
				arg_values+=("")
			fi
		;;
	esac
done <"$software_config"

# Second pass. Get default and specific values (Based on pools, coins or addresses) for each flag sent to miner
while IFS='' read -r config_line_comments || [[ -n "$config_line_comments" ]]
do
	conf_line=${config_line_comments%%'#'*}
	conf_line="$(echo "$conf_line" | tr [:upper:] [:lower:])" # Lower Case
	conf_line="$(echo "${conf_line//[[:blank:]]/}")"
	if [[ -z "$conf_line" || "$conf_line" = *"_arg"* || "$conf_line" = *"_flag"* ]]
	then
		continue
	fi
	for i in "${!arg_names[@]}"
	do
		if [[ "${conf_line%%=*}" = "${arg_names[$i]}" ]]
		then
			# Default value. Does not overwrite.
			if [[ -z "${arg_values[$i]}" ]]
			then
				arg_values[$i]="$(set_val "${conf_line##*=}")"
				if [[ "${arg_names[$i]}" = "addr" && "$worker" = "true" ]]
				then
					arg_values[$i]+=".$NAME"
				fi
				if [[ "${arg_names[$i]}" = "pool" && "$separate_port" = "false" ]]
				then
					arg_values[$i]+=":$PORT"
				fi
				if [[ "${arg_names[$i]}" = "dualpool" && "$separate_port" = "false" ]]
				then
					arg_values[$i]+=":$DUAL_PORT"
				fi
			fi
			# echo "Arg:  ${arg_names[$i]}"
			# declare -p conf_line
		elif [[ "${conf_line%%=*}" = *"_${arg_names[$i]}" ]]
		then
			keywords_all="${conf_line%%_${arg_names[$i]}*}"
			IFS=_ read -a keywords <<<"${keywords_all}"
			keywords_match=true
			for keyword in "${keywords[@]}"
			do
				if ! check_match "$keyword"
				then
					keywords_match=false
					break
				fi
			done
			# declare -p keywords
			# declare -p keywords_match
			if [[ "$keywords_match" = "true" ]]
			then
				# Override default
				arg_values[$i]="${conf_line##*=}"
				if [[ "${arg_names[$i]}" = "addr" && "$worker" = "true" ]]
				then
					arg_values[$i]+=".$NAME"
				fi
				if [[ "${arg_names[$i]}" = "pool" && "$separate_port" = "false" ]]
				then
					arg_values[$i]+=":$PORT"
				fi
				if [[ "${arg_names[$i]}" = "dualpool" && "$separate_port" = "false" ]]
				then
					arg_values[$i]+=":$DUAL_PORT"
				fi
			fi
		fi
	done
done <"$software_config"

# Combine args
miner_args=()
for i in "${!arg_names[@]}"
do
	if [[ -n "${arg_flags[$i]}" && -n "${arg_values[$i]}" ]]
	then
		miner_args+=("${arg_flags[$i]}")
		miner_args+=("${arg_values[$i]}")
	fi
done

# Get executable #
readarray -t start_file_arr < <(find ./ -type f -name "$SOFTWARE_RUNNING")
start_file="${start_file_arr[0]}"
chmod +x "$start_file"

# Write Script #
echo "cd ${start_file%'/'*}" >> "$CMD_FILE"
echo "./${start_file##*'/'} ${miner_args[@]} ${other_args[@]} & echo "'$!' >> "$CMD_FILE"
chmod +x "$CMD_FILE"