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

# Dependency installation
initialize_setup() {
  (
    clear
    display_motd
    echo "Updating macOS... (press 's' to skip)"
    softwareupdate -ia --verbose > /dev/null
    line_break

    echo "Installing Xcode Command Line Tools... (press 's' to skip)"
    xcode-select --install > /dev/null
    line_break

    if ! command -v brew &> /dev/null; then
      echo "Installing Homebrew... (press 's' to skip)"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" > /dev/null
      line_break
    fi

    echo "Updating Homebrew... (press 's' to skip)"
    if ! brew update; then
      echo "Failed to update Homebrew. Attempting to fix..."
      git -C "$(brew --repo)" fetch
      git -C "$(brew --repo)" reset --hard FETCH_HEAD
      brew update
      line_break
    fi

    echo "Installing Git... (press 's' to skip)"
    brew install git > /dev/null
    line_break
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


# Available software options
software_names=("VSCode" "Google Chrome" "Brave Browser" "Firefox" "Edge Browser")
software_casks=("visual-studio-code" "google-chrome" "brave-browser" "firefox" "microsoft-edge")

initialize_setup

while true; do
  clear
	display_motd
  echo "Select software to install:"
  for i in "${!software_names[@]}"; do
    installed=""
    if brew list --cask "${software_casks[$i]}" &> /dev/null; then
      installed="(installed)"
    fi
    echo "$((i + 1))) ${software_names[$i]} $installed"
  done
	line_break
  echo "-------------------------"
  echo "a) Install All"
  echo "e) Exit"
  echo "r) Reload"

	line_break
  read -p "Enter the number corresponding to your choice: " choice

  case $choice in
  [1-5])
    ((choice--))
    if brew list --cask "${software_casks[$choice]}" &> /dev/null; then
      read -p "${software_names[$choice]} is already installed. Do you want to (u)ninstall or (r)einstall? " opt
      if [[ "$opt" == "u" ]]; then
        brew uninstall --cask "${software_casks[$choice]}"
      elif [[ "$opt" == "r" ]]; then
        brew reinstall --cask "${software_casks[$choice]}"
      fi
    else
      echo "Installing ${software_names[$choice]}..."
      brew install --cask "${software_casks[$choice]}"
    fi
    ;;
  a)
    for i in "${!software_names[@]}"; do
      if ! brew list --cask "${software_casks[$i]}" &> /dev/null; then
        echo "Installing ${software_names[$i]}..."
        brew install --cask "${software_casks[$i]}"
      fi
    done
    ;;
  e)
		clear
    echo "Exiting..."
    exit 0
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
