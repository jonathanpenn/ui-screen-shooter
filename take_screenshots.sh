#!/bin/bash

set -e

main() {
  xcode clean build TARGETED_DEVICE_FAMILY=1

  shoot "iPhone (Retina 3.5-inch)" "en"
  shoot "iPhone (Retina 3.5-inch)" "fr"
  shoot "iPhone (Retina 3.5-inch)" "ja"

  shoot "iPhone (Retina 4-inch)" "en"
  shoot "iPhone (Retina 4-inch)" "fr"
  shoot "iPhone (Retina 4-inch)" "ja"

  # We to build again with the iPad device family because otherwise Instruments
  # will build and run for iPhone even though the simulator says otherwise.
  xcode build TARGETED_DEVICE_FAMILY=2

  shoot "iPad (Retina)" "en"
  shoot "iPad (Retina)" "fr"
  shoot "iPad (Retina)" "ja"

  close_sim
}

# Global variables to keep track of where everything goes
dev_tools_dir=`xcode-select -print-path`
tmp_dir="/tmp"
build_dir="$tmp_dir/screen_shooter"
bundle_dir="$build_dir/app.app"
trace_results_dir="$build_dir/traces"
destination="$1"

shoot() {
  # Takes the sim device type and a language code, runs the screenshot script,
  # and then copies over the screenshots to the destination

  clean_trace_results_dir
  bin/choose_sim_device "$1"
  choose_sim_language "$2"
  take_screenshots
  copy_screenshots
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

  /usr/libexec/PlistBuddy "$pref_file" -c "Delete :AppleLanguages"
  /usr/libexec/PlistBuddy "$pref_file" -c "Add :AppleLanguages array"
  /usr/libexec/PlistBuddy "$pref_file" -c "Add :AppleLanguages:0 string '$1'"
}

close_sim() {
  # Closes the simulator. We need to do this after altering the languages and
  # when we want to clean up at the end.

  osascript -e 'tell application "iPhone Simulator" to quit'
}

take_screenshots() {
  # Runs the UI Automation JavaScript file that actually takes the screenshots.

  tracetemplate="$dev_tools_dir/../Applications/Instruments.app/Contents/PlugIns/AutomationInstrument.bundle/Contents/Resources/Automation.tracetemplate"

  # Check out the `unix_instruments` script to see why we need this wrapper.
  bin/unix_instruments \
    -D "$trace_results_dir/trace" \
    -t "$tracetemplate" \
    $bundle_dir \
    -e UIARESULTSPATH "$trace_results_dir" \
    -e UIASCRIPT screenshots.js \
    $*
}

copy_screenshots() {
  # Since we're always clearing out the trace results before every run, we can
  # assume that any screenshots were saved in the "Run 1" directory. Copy them
  # to the destination!

  mkdir -p $destination
  cp $trace_results_dir/Run\ 1/*.png $destination
}

main

