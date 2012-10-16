#!/bin/bash

# Tell bash that we want the whole script to fail if any part fails.
set -e

# We require a parameter for where to put the results
destination="$1"

main() {
  check_destination

  xcode clean build TARGETED_DEVICE_FAMILY=1

  bin/choose_sim_device "iPhone (Retina 3.5-inch)"
  shoot en fr ja

  bin/choose_sim_device "iPhone (Retina 4-inch)"
  shoot en fr ja

  # We to build again with the iPad device family because otherwise Instruments
  # will build and run for iPhone even though the simulator says otherwise.
  xcode build TARGETED_DEVICE_FAMILY=2

  bin/choose_sim_device "iPad (Retina)"
  shoot en fr ja

  close_sim
}

# Global variables to keep track of where everything goes
dev_tools_dir=`xcode-select -print-path`
tmp_dir="/tmp"
build_dir="$tmp_dir/screen_shooter"
bundle_dir="$build_dir/app.app"
trace_results_dir="$build_dir/traces"

check_destination() {
  # Abort if the destination directory already exists. Better safe than sorry.

  if [ -z "$destination" ]; then
    echo "usage: run_screenshooter.sh destination_directory"
    exit 1
  elif [ -d "$destination" ]; then
    echo "Destination directory \"$destination\" already exists! Aborting."
    exit 1
  fi
}

shoot() {
  # Takes the sim device type and a language code, runs the screenshot script,
  # and then copies over the screenshots to the destination

  for language in $*; do
    clean_trace_results_dir
    choose_sim_language $language
    run_automation "take_screenshots.js"
    copy_screenshots
  done
}

xcode() {
  # A wrapper around `xcodebuild` that tells it to build the app in the temp
  # directory. If your app uses workspaces or special schemes, you'll need to
  # specify them here.
  #
  # Use `man xcodebuild` for more information on how to build your project.

  xcodebuild -sdk iphonesimulator \
    CONFIGURATION_BUILD_DIR=$build_dir \
    PRODUCT_NAME=app \
    $*
}

clean_trace_results_dir() {
  # Removes the trace results directory. We need to do this because Instruments
  # keeps appending new trace runs and it's simpler for us to always assume
  # there's just one run recorded where we look for screenshots.

  rm -rf "$trace_results_dir"
  mkdir -p "$trace_results_dir"
}

choose_sim_language() {
  # Alters the global preference file for every simulator type and moves the
  # chosen language identifier to the top.

  echo "Localizing for $1"

  pref_file=`ls ~/Library/Application\ Support/iPhone\ Simulator/6.0/Library/Preferences/.GlobalPreferences.plist`

  close_sim

  /usr/libexec/PlistBuddy "$pref_file" -c "Delete :AppleLanguages" \
    -c "Add :AppleLanguages array" \
    -c "Add :AppleLanguages:0 string '$1'"
}

close_sim() {
  # Closes the simulator. We need to do this after altering the languages and
  # when we want to clean up at the end.

  osascript -e 'tell application "iPhone Simulator" to quit'
}

run_automation() {
  # Runs the UI Automation JavaScript file that actually takes the screenshots.

  tracetemplate="$dev_tools_dir/../Applications/Instruments.app/Contents/PlugIns/AutomationInstrument.bundle/Contents/Resources/Automation.tracetemplate"

  # Check out the `unix_instruments` script to see why we need this wrapper.
  bin/unix_instruments \
    -D "$trace_results_dir/trace" \
    -t "$tracetemplate" \
    $bundle_dir \
    -e UIARESULTSPATH "$trace_results_dir" \
    -e UIASCRIPT "$1" \
    $*
}

copy_screenshots() {
  # Since we're always clearing out the trace results before every run, we can
  # assume that any screenshots were saved in the "Run 1" directory. Copy them
  # to the destination!

  mkdir -p "$destination"
  cp $trace_results_dir/Run\ 1/*.png $destination
}

main

