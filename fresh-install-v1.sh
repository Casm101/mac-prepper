#!/bin/bash

# Declaration of global variables
isInstalledBrew=false
installed_casks=
installed_formulas=

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


# Retrieve installed software
initialize_installed_lists() {
	if [ "$isInstalledBrew" = true ]; then
		installed_casks=$(brew list --cask)
		installed_formulas=$(brew list)
	fi
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

		# Clear for installs
    clear
    display_motd

		# Install brew
		if ! command -v brew &> /dev/null; then
      echo "Installing Homebrew... (press 's' to skip)"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" > /dev/null &
  
			show_spinner
			isInstalledBrew=true
			echo " Done."
			line_break
    else
			echo "✅ Brew is already installed."
			isInstalledBrew=true
			line_break
			sleep .5
		fi

		# Install xcode-cli-tools
		if ! command -v xcode-select &> /dev/null; then
			echo "Installing Xcode Command Line Tools... (press 's' to skip)"
			xcode-select --install &
		
			show_spinner
			echo " Done."
			sleep 5
			line_break
		else
			echo "✅ XCode tools are already installed."
			sleep .5
		fi

  ) &
  
  SETUP_PID=$!
  
  while kill -0 $SETUP_PID 2> /dev/null; do
    read -t 1 -n 1 input
    if [[ $input = "s" ]]; then
      kill -9 $SETUP_PID
      wait $SETUP_PID 2> /dev/null
      echo "Skipped setup."
			sleep .5
      break
    fi
  done
}


# Process software installation
process_installation() {

	clear
	display_motd

	# Declare local software variables
	local name=$1
	local cask=$2
	local isCask=

	# Check if software is installed
	if [[ $installed_casks == *"${casks[$i]}"* || $installed_formulas == *"${casks[$i]}"* ]] &> /dev/null; then

		# Check software type
		if [[ $installed_casks == *"${casks[$i]}"* ]] &> /dev/null; then
			isCask=true
		elif [[ $installed_formulas == *"${casks[$i]}"* ]] &> /dev/null; then
			isCask=false
		fi

		# Display management menu
		echo "$name is already installed"
		line_break
		echo "Manage $name installation:"
		echo "u) Uninstall"
		echo "r) Reinstall"
		line_break
		echo "-------------------------"
		echo "c) Cancel operation"

		# Prompt user input
		read -n 1 -p "Select operation to process: " opt

		# Process unser selection
		if [[ "$opt" == "u" ]]; then

			# Handle uninstall
			line_break && line_break
			if [[ $isCask == true ]]; then
				brew uninstall --cask "$cask"
			else
				brew uninstall "$cask"
			fi

		elif [[ "$opt" == "r" ]]; then
			
			# Handle reinstall
			line_break && line_break
			if [[ $isCask == true ]]; then
				brew reinstall --cask "$cask"
			else
				brew reinstall "$cask"
			fi

		elif [[ $opt == "c" ]]; then
			break
		fi
	else
		echo "Installing $name..."
		if ! brew install --cask "$cask"; then
      echo "${name} cask installation failed. Attempting to install using brew..."
      brew install "${cask}"
			line_break
			echo "${name}" formula was installed!
    else
			echo "${name}" cask was installed!
		fi
	fi

	# Reload installed software
	initialize_installed_lists
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
			if [[ $installed_casks == *"${casks[$i]}"* ]] &> /dev/null; then
				installed="(installed - cask)"
			elif [[ $installed_formulas == *"${casks[$i]}"* ]] &> /dev/null; then
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
	echo "(Installs updates, Brew, xcode-cli-tools, etc)"
	line_break
	read -n 1 -p "Enter your selection: " choice

	case $choice in
	y)
		initialize_setup
		;;
	n)
		clear
		echo "Loading software list..."

		# Load installed software
		initialize_installed_lists
		show_spinner
		;;
	esac
}

tool_init

# Software categories
browsers=("Brave Browser" "Google Chrome" "Edge Browser" "Firefox" "Opera")
browser_casks=("brave-browser" "google-chrome" "microsoft-edge" "firefox" "opera")

dev_tools=("VSCode" "Fig" "Filezilla" "Insomnia" "Postman" "TablePlus" "Termius" "Cursor" "Docker")
dev_casks=("visual-studio-code" "fig" "filezilla" "insomnia" "postman" "tableplus" "termius" "cursor" "docker")

cli_tools=("npm" "nvm" "Python" "Git" "NeoFetch")
cli_casks=("npm" "nvm" "python" "git" "neofetch")

socials=("Beeper" "Whatsapp" "Discord")
socials_casks=("beeper" "whatsapp" "discord")

office_tools=("WPS Office Suite" "Obsidian")
office_casks=("wpsoffice" "obsidian")

others=("Rectangle" "VLC")
other_casks=("rectangle" "vlc")

while true; do
	clear
	display_motd

	if [ "$isInstalledBrew" = true ]; then
		echo "yes"
	else
		echo "no: $isInstalledBrew"
	fi
	line_break

	echo "Main Menu:"
	echo "1) Browsers"
	echo "2) Development tools"
	echo "3) CLI tools"
	echo "4) Communications / Social"
	echo "5) Office tools"
	echo "6) Other"
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
		show_submenu socials[@] socials_casks[@]
		;;
	5)
		show_submenu office_tools[@] office_casks[@]
		;;
	6)
		show_submenu others[@] other_casks[@]
		;;
	e)
		clear
		echo "Exiting..."
		sleep .75 
		reset
		exit 0
		;;
	r)
		clear
		echo "Reloading..."
		sleep .75 
		reset
		tool_init
		;;
	*)
		echo "Invalid choice, please try again."
		;;
	esac
done
