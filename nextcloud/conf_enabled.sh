#!/bin/bash

# Ask user for path to configuration file
read -p "Enter the path to the configuration file (or press enter to use default /etc/php.ini): " config_file

# If no path is given, use default
if [[ -z "$config_file" ]]; then
  config_file="/etc/php.ini"
fi

# Output header and file name
echo -e "\nUsing configuration file: $config_file\n"

# Define variables to keep track of section and block titles
section_title=""
block_title=""
empty_blocks=""
empty_columns=""

# Loop through each line in the file
while read -r LINE; do

  # Check if the line is not a comment (i.e., does not start with ";")
  if [[ $LINE != \;* ]]; then

    # Check if the line contains a "[" character
    if [[ $LINE == *\[** ]]; then

      # Print a horizontal line to separate sections
      echo "--------------------------------------------------------------------------------"

      # Set the section title to the contents of the line (without the square brackets)
      section_title=$(echo "$LINE" | sed -e 's/\[\(.*\)\]/\1/')

      # Print the section title in bold
      echo -e "\033[1m$section_title\033[0m"

      # Reset the block title and empty blocks/columns
      block_title=""
      empty_blocks=""
      empty_columns=""

    # Check if the line contains an "=" character
    elif [[ $LINE == *"="* ]]; then

      # Extract the name and value from the line
      NAME=$(echo "$LINE" | cut -d "=" -f 1)
      VALUE=$(echo "$LINE" | cut -d "=" -f 2-)

      # Check if this is a new block
      if [[ $NAME != $block_title ]]; then

        # If there were any empty blocks in the previous section, print them now
        if [[ ! -z "$empty_blocks" ]]; then
          printf "%-50s%-20s\n" "$empty_blocks" "$empty_columns"
          empty_blocks=""
          empty_columns=""
        fi

        # Set the block title to the name of the block
        block_title=$NAME

      fi

      # If there is no value, add this block to the empty blocks list
      if [[ -z "$VALUE" ]]; then
        empty_blocks="$empty_blocks [$block_title] $NAME"
        empty_columns=""
      else
        # If there were any empty blocks in this section, print them now
        if [[ ! -z "$empty_blocks" ]]; then
          printf "%-50s%-20s\n" "$empty_blocks" "$empty_columns"
          empty_blocks=""
          empty_columns=""
        fi

        # Print the name and value of the configuration option
        printf "%-50s%-20s\n" "[$block_title] $NAME" "$VALUE"
      fi

    fi
  fi

  # If we've reached the end of the file, print any remaining empty blocks
  if [[ $? -eq 1 && ! -z "$empty_blocks" ]]; then
    printf "%-50s%-20s\n" "$empty_blocks" "$empty_columns"
    empty_blocks=""
    empty_columns=""
  fi

done < "$config_file"

# Print a horizontal line at the end of the output
echo "--------------------------------------------------------------------------------"

