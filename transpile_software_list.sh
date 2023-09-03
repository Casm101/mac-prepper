#!/bin/bash

# Kill all subprocesses if premature exit
trap "kill 0" EXIT

# Function to fetch brew information
fetch_info() {
  local software=$1
  local safe_name=$(echo "$software" | sed 's/[^a-zA-Z0-9]/_/g')
  local json_info=$(brew info --json=v2 "$software" 2>/dev/null)

  if [[ -z "$json_info" ]]; then
    # Try getting cask info if brew info failed
    json_info=$(brew info --cask --json=v2 "$software" 2>/dev/null)
  fi

  if [[ -z "$json_info" ]]; then
    echo "Failed to fetch info for $software. ❌"
    return
  fi

  # Lock the file and append this JSON to software_list.json
  (
    flock -x -w 10 200 || exit 1
    echo "\"$safe_name\": $json_info," >> software_list.json
  ) 200>>software_list.json.lock

  echo "Completed info for $software. ✅"
}

# Initialize the JSON file
echo "{" > software_list.json

# Read the software list file
while IFS= read -r line; do
  # Run background task
  fetch_info "$line" &
  
  # If there are 50 background tasks, wait for all to complete before continuing
  if [[ $(jobs -r -p | wc -l | awk '{print $1}') -ge 50 ]]; then
    wait  # Wait for all jobs to terminate
  fi

done < software.txt

# Wait for all background tasks to complete
wait

# Close the JSON bracket and remove trailing comma
sed -i '' -e '$ s/,$//' software_list.json
echo "}" >> software_list.json

# Remove lock file
rm -f software_list.json.lock

# Display completion message
echo "Transpile has finished"
