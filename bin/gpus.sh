#!/bin/bash
if ! dpkg -l clinfo &> /dev/null
then
	apt install -y clinfo
fi

# Environment variables should already be set but just in case #
[[ -z "$GPU_TYPE_FILE" ]] && GPU_TYPE_FILE=".local/gpu_type"
[[ -z "$GPU_OPENCL_REORDER" ]] && GPU_OPENCL_REORDER=".local/cl_reorder"
[[ -z "$NUM_GPUS" ]] && NUM_GPUS=".local/num_gpus"
[[ -z "$GPU_FILE" ]] && GPU_FILE=".local/is_nvidia"
[[ -z "$AMD_REORDER" ]] && AMD_REORDER=".local/amd_reorder"

is_nvidia=() # Set 0 for nvidia, 1 for amd, 2 for unkown.
gpu_names=()
cl_reorder=() # Re-order opencl since it is different
amd_reorder=() # Sometimes cpu has entry in /sys/class/drm folder
num_gpus=0

open_cl_output="$(clinfo 2>/dev/null)"

readarray -t open_cl_nvidia_gpu_name < <(echo "$open_cl_output" | grep "Device Name")
readarray -t open_cl_amd_gpu_name < <(echo "$open_cl_output" | grep "Board Name")
# Hack to remove multiple begining whitespace (So space in gpu name is maintained)
open_cl_nvidia_gpu_name=("${open_cl_nvidia_gpu_name[@]##*[[:blank:]][[:blank:]]}")
open_cl_amd_gpu_name=("${open_cl_amd_gpu_name[@]##*[[:blank:]][[:blank:]]}")

# Get PCIE Order for cards
readarray -t open_cl_order < <(echo "$open_cl_output" | grep -i "Device Topology")
open_cl_order=("${open_cl_order[@]##*PCI-E, }")

vendor_files=(/sys/class/drm/card*/device/vendor)
card_idx=("${vendor_files[@]##*card}")
card_idx=("${card_idx[@]%%'/device/vendor'*}")

pcie_order_file=()

for file_idx in "${!vendor_files[@]}"
do
	pcie_order_file="/sys/kernel/debug/dri/${card_idx[$file_idx]}/name"
	# Check Files Exist
	[[ ! -f "${vendor_files[$file_idx]}" || ! -f "$pcie_order_file" ]] && continue

	vendor="$(cat "${vendor_files[$file_idx]}")"
	if [[ "$vendor" == "0x10de" ]]
	then
		is_nvidia+=(0)
	elif [[ "$vendor" == "0x1002" ]]
	then
		is_nvidia+=(1)
	else
		continue
	fi

	amd_reorder+=("${card_idx[$file_idx]}")
	# Reorder from opencl to pcie slot #
	pcie="$(cat "$pcie_order_file")"
	pcie="${pcie##*unique=0000:}"
	# Loop through device topology to find matching pcie slot entry #
	found_match=false
	for cl_order_idx in "${!open_cl_order[@]}"
	do
		if [[ "$pcie" == "${open_cl_order[$cl_order_idx]}" ]]
		then
			found_match=true
			cl_reorder["$cl_order_idx"]="$num_gpus"
			if [[ "$vendor" == "0x10de" ]]
			then
				gpu_names+=("${open_cl_nvidia_gpu_name[$cl_order_idx]}")
			else
				gpu_names+=("${open_cl_amd_gpu_name[$cl_order_idx]}")
			fi
		fi
	done
	if [[ "$found_match" == "true" ]]
	then
		((num_gpus++))
	else
		is_nvidia["$num_gpus"]="2"
	fi
done

# declare -p gpu_names
# declare -p is_nvidia
# declare -p cl_reorder
# declare -p amd_reorder
# declare -p num_gpus

printf '%s\n' "${gpu_names[@]}" > "$GPU_TYPE_FILE"
printf '%s\n' "${is_nvidia[@]}" > "$GPU_FILE"
printf '%s\n' "${cl_reorder[@]}" > "$GPU_OPENCL_REORDER"
printf '%s\n' "${amd_reorder[@]}" > "$AMD_REORDER"
# printf '%s\n' "${num_gpus[@]}" > "$NUM_GPUS"
echo -n "$num_gpus" > "$NUM_GPUS"

exit 0
