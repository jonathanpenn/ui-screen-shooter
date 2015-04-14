#!/bin/bash
# This is an example configuration file to be used with ui-screen-shooter
# It is designed to work with the Hello World International application
# Please copy to config-screenshots.sh and edit for your needs


# LOCALE
# ======
# Set the locales here in which your screenshots should be made.
# Use format like en-US zh-Hans for filenames compatible with iTMSTransporter
# Note: to get the locale names for your existing app:
#  - Download .itmsp file with iTMSTransporter
#  - Run `grep locale ~/Desktop/*.itmsp/metadata.xml  | grep name | sort -u`

export languages="en-US fr ja"


# SIMULATORS
# ==========
# The simulators we want to run the script against, declared as a Bash array.
# Run `instruments -s devices` to get a list of all the possible string values.

declare -xa simulators=(
"iPhone 6 (8.3 Simulator)",
"iPhone 6 Plus (8.3 Simulator)",
"iPhone 5 (8.3 Simulator)",
"iPhone 4s (8.3 Simulator)"
)
