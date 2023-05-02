#!/bin/bash

# Get CPU information
echo "CPU Information:"
echo "----------------"
cat /proc/cpuinfo | grep "model name" | uniq
echo "Number of CPU cores: $(nproc)"

# Get RAM information
echo
echo "RAM Information:"
echo "----------------"
RAM_INFO=$(dmidecode --type 17)
DDR_TYPE=$(echo "$RAM_INFO" | grep "Type:" | awk '{print $2}')
echo "DDR Type: $DDR_TYPE"
echo "$RAM_INFO" | grep "Speed:" | awk '{print "Speed: "$2" MHz"}'
echo "$RAM_INFO" | grep "Size:" | awk '{print $2, $3}' | paste -sd+ - | bc | awk '{print "Total RAM: "$1" GB"}'

# Calculate RAM performance
echo
echo "RAM Performance:"
echo "----------------"
RAM_SPEED=$(echo "$RAM_INFO" | grep "Speed:" | awk '{print $2}')
TOTAL_RAM=$(echo "$RAM_INFO" | grep "Size:" | awk '{print $2, $3}' | paste -sd+ - | bc)
RAM_BANDWIDTH=$(echo "$RAM_SPEED*2*8*$TOTAL_RAM/1000/1000/1000" | bc -l)
echo "RAM Bandwidth: $RAM_BANDWIDTH GB/s"

