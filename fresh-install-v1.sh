#!/bin/bash

# Tool MOTD
display_motd() {
	cat << "EOF"
   ___ __    __  __ __   _ __  _   __ _____ __  _   _   ___ ___  
 / _//  \ /' _/|  V  | | |  \| |/' _/_   _/  \| | | | | __| _ \ 
| \_| /\ |`._`.| \_/ | | | | ' |`._`. | || /\ | |_| |_| _|| v / 
 \__/_||_||___/|_| |_| |_|_|\__||___/ |_||_||_|___|___|___|_|_\

 by Casm101

EOF
}

# Simple line-break
line_break() {
	echo ""
}

# Function to show spinner
show_spinner() {
  local pid=$!
  local delay=0.1
  local spinstr='-\|/'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

# Dependency installation
initialize_setup() {
  (
    clear
    display_motd
    echo "Updating macOS... (press 's' to skip)"
    softwareupdate -ia --verbose > /dev/null &
  
		show_spinner
  	echo " Done."
    line_break

    echo "Installing Xcode Command Line Tools... (press 's' to skip)"
    xcode-select --install > /dev/null &
  
		local SETUP_PID=$!
		show_spinner $SETUP_PID
		echo " Done."
    line_break

    if ! command -v brew &> /dev/null; then
      echo "Installing Homebrew... (press 's' to skip)"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" > /dev/null &
  
			local SETUP_PID=$!
			show_spinner $SETUP_PID
			echo " Done."
			line_break
    fi

    echo "Updating Homebrew... (press 's' to skip)"
    if ! brew update; then
      echo "Failed to update Homebrew. Attempting to fix..."
      git -C "$(brew --repo)" fetch
      git -C "$(brew --repo)" reset --hard FETCH_HEAD
      brew update &
  
			local SETUP_PID=$!
			show_spinner $SETUP_PID
			echo " Done."
			line_break
    fi
  ) &
  
  SETUP_PID=$!
  
  while kill -0 $SETUP_PID 2> /dev/null; do
    read -t 1 -n 1 input
    if [[ $input = "s" ]]; then
      kill -9 $SETUP_PID
      wait $SETUP_PID 2> /dev/null
      echo "Skipped setup."
      break
    fi
  done
}

# Process software installation
process_installation() {

	clear
	display_motd

	local name=$1
	local cask=$2

	if brew list --cask "$cask" &> /dev/null; then
		read -n 1 -p "$name is already installed. Do you want to (u)ninstall or (r)einstall? " opt
		if [[ "$opt" == "u" ]]; then
			brew uninstall --cask "$cask"
		elif [[ "$opt" == "r" ]]; then
			brew reinstall --cask "$cask"
		fi
	else
		echo "Installing $name..."
		if ! brew install --cask "$cask"; then
      echo "${name} cask installation failed. Attempting to install using brew..."
      brew install "${cask}"
    else
			echo "${name}" cask was installed!
		fi
	fi
}

# Main function to handle sub-menus
show_submenu() {
	local names=("${!1}")
	local casks=("${!2}")

	while true; do
		clear
		display_motd
		echo "Select software to install:"
		for i in "${!names[@]}"; do
			local installed=""
			if brew list --cask "${casks[$i]}" &> /dev/null; then
				installed="(installed - cask)"
			elif brew list "${casks[$i]}" &> /dev/null; then
				installed="(installed)"
			fi
			echo "$((i + 1))) ${names[$i]} $installed"
		done
		line_break
		echo "-------------------------"
		echo "a) Install All"
		echo "e) Exit to Main Menu"
		echo "r) Reload"

		line_break
		read -n 1 -p "Enter the number corresponding to your choice: " choice

		case $choice in
		[1-${#names[@]}])
			((choice--))
			process_installation "${names[$choice]}" "${casks[$choice]}"
			;;
		a)
			for i in "${!names[@]}"; do
				process_installation "${names[$i]}" "${casks[$i]}"
			done
			;;
		e)
			break
			;;
		r)
			clear
			echo "Reloading..."
			initialize_setup
			;;
		*)
			echo "Invalid choice, please try again."
			;;
		esac
	done
}


# Start the installer tool
tool_init() {
	clear
	display_motd
	echo "Would you like to install tool dependancies? (y)es / (n)o"
	echo "(System updates, Brew,  XCode CLI, etc)"
	line_break
	read -n 1 -p "Enter your selection: " choice

	case $choice in
	y)
		initialize_setup
		;;
	n)
		clear
		echo "Loading software list..."
		sleep 0.75
		;;
	esac
}

tool_init

# Software categories
browsers=("Brave Browser" "Google Chrome" "Edge Browser" "Firefox" "Opera")
browser_casks=("brave-browser" "google-chrome" "microsoft-edge" "firefox" "opera")

dev_tools=("VSCode" "Fig" "Filezilla" "Insomnia" "Postman" "TablePlus")
dev_casks=("visual-studio-code" "fig" "filezilla" "insomnia" "postman" "tableplus")

cli_tools=("npm" "nvm" "Python" "Git")
cli_casks=("npm" "nvm" "python" "git")

others=("Rectangle")
other_casks=("rectangle")

while true; do
	clear
	display_motd
	echo "Main Menu:"
	echo "1) Browsers"
	echo "2) Development tools"
	echo "3) CLI tools"
	echo "4) Other"
	line_break
	echo "-------------------------"
	echo "e) Exit"
	echo "r) Reload"
	line_break
	read -n 1 -p "Enter the number corresponding to your choice: " choice

	case $choice in
	1)
		show_submenu browsers[@] browser_casks[@]
		;;
	2)
		show_submenu dev_tools[@] dev_casks[@]
		;;
	3)
		show_submenu cli_tools[@] cli_casks[@]
		;;
	4)
		show_submenu others[@] other_casks[@]
		;;
	e)
		clear
		echo "Exiting..."
		sleep 1 
		reset
		exit 0
		;;
	r)
		clear
		echo "Reloading..."
		sleep 1 
		reset
		tool_init
		;;
	*)
		echo "Invalid choice, please try again."
		;;
	esac
done
