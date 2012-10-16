#!/bin/bash

set -e

dev_tools_dir=`xcode-select -print-path`
tmp_dir="/tmp"
build_dir="$tmp_dir/screen_shooter"
bundle_dir="$build_dir/app.app"
trace_results_dir="$build_dir/traces"
destination="$1"

main() {
  xcodebuild_command clean build TARGETED_DEVICE_FAMILY=1

  shoot "iPhone (Retina 3.5-inch)" "en"
  shoot "iPhone (Retina 3.5-inch)" "fr"
  shoot "iPhone (Retina 3.5-inch)" "ja"
  shoot "iPhone (Retina 4-inch)" "en"
  shoot "iPhone (Retina 4-inch)" "fr"
  shoot "iPhone (Retina 4-inch)" "ja"

  xcodebuild_command build TARGETED_DEVICE_FAMILY=2

  shoot "iPad (Retina)" "en"
  shoot "iPad (Retina)" "fr"
  shoot "iPad (Retina)" "ja"

  close_sim
}

shoot() {
  clean_trace_results_dir
  choose_sim_device "$1"
  choose_sim_language "$2"
  take_screenshots
  copy_screenshots
}

# TODO: provide instructions on modifying this for specific projects
xcodebuild_command() {
  xcrun xcodebuild -sdk iphonesimulator \
    CONFIGURATION_BUILD_DIR=$build_dir \
    PRODUCT_NAME=app \
    $*
}

clean_trace_results_dir() {
  rm -rf "$trace_results_dir"
  mkdir -p "$trace_results_dir"
}

choose_sim_language() {
  echo "Localizing for $1"

  pref_file=`ls ~/Library/Application\ Support/iPhone\ Simulator/6.0/Library/Preferences/.GlobalPreferences.plist`
  close_sim
  /usr/libexec/PlistBuddy "$pref_file" -c "Delete :AppleLanguages"
  /usr/libexec/PlistBuddy "$pref_file" -c "Add :AppleLanguages array"
  /usr/libexec/PlistBuddy "$pref_file" -c "Add :AppleLanguages:0 string '$1'"
}

choose_sim_device() {
  # This is just a prettier function name around the Applescript
  bin/choose_sim_device "$*"
}

close_sim() {
  osascript -e 'tell application "iPhone Simulator" to quit'
}

take_screenshots() {
  tracetemplate="$dev_tools_dir/../Applications/Instruments.app/Contents/PlugIns/AutomationInstrument.bundle/Contents/Resources/Automation.tracetemplate"

  # Check out the `unix_instruments` script to see why we need it
  ./bin/unix_instruments \
    -D "$trace_results_dir/trace" \
    -t "$tracetemplate" \
    $bundle_dir \
    -e UIARESULTSPATH "$trace_results_dir" \
    -e UIASCRIPT screenshots.js \
    $*
}

copy_screenshots() {
  mkdir -p $destination
  cp $trace_results_dir/Run\ 1/*.png $destination
}

main

