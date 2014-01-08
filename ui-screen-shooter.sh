#!/bin/bash
# Copyright (c) 2012 Jonathan Penn (http://cocoamanifest.net/)

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


# Tell bash that we want the whole script to fail if any part fails.
set -e

# We require a parameter for where to put the results
destination="$1"

# The locale identifiers for the languages you want to shoot
# Use the format like en-US cmn-Hans for filenames compatible with iTunes
# connect upload tool
languages="en-US cmn-Hans"

# The iOS version we want to run the script against
ios_version="7.0"

# The iOS devices we want to run, can include: iphone4 iphone5 ipad
ios_devices="iphone4 iphone5 ipad"

function main {
  _check_destination

  # Attempt to save and restore the language the simulator SDKs were in before
  # running this. If you want to explicitly set the language, use the
  # `bin/choose_sim_language [lang]` after you run this script.
  original_language=$(bin/choose_sim_language)
  echo "Saving original language $original_language..."

  # We have to build and explicitly set the device family because otherwise 
  # Instruments will always launch a universal app on the iPad simulator.

  if [[ "$ios_devices" == *iphone* ]]
  then
    _xcode clean build TARGETED_DEVICE_FAMILY=1
    if [[ "$ios_devices" == *iphone4* ]]
    then
      bin/choose_sim_device "iPhone Retina (3.5-inch)" $ios_version
      _shoot_screens_for_all_languages
    fi
    if [[ "$ios_devices" == *iphone5* ]]
    then
      bin/choose_sim_device "iPhone Retina (4-inch)" $ios_version
      _shoot_screens_for_all_languages
    fi
  fi
  if [[ "$ios_devices" == *ipad* ]]
  then
    _xcode build TARGETED_DEVICE_FAMILY=2
    bin/choose_sim_device "iPad Retina" $ios_version
    _shoot_screens_for_all_languages
  fi

  bin/close_sim

  echo "Restoring original language $original_language..."
  bin/choose_sim_language $original_language

  echo
  echo "Screenshots complete!"
}

# Global variables to keep track of where everything goes
tmp_dir="/tmp"
build_dir="$tmp_dir/screen_shooter"
bundle_dir="$build_dir/app.app"
trace_results_dir="$build_dir/traces"

function _check_destination {
  # Abort if the destination directory already exists. Better safe than sorry.

  if [ -z "$destination" ]; then
    destination="$HOME/Desktop/screenshots"
  fi
  if [ -d "$destination" ]; then
    echo "Destination directory \"$destination\" already exists! Aborting."
    exit 1
  fi
}

function _shoot_screens_for_all_languages {
  # Loop over all the $languages (set at the top of the script) and execute the
  # automation screen for each one, copying the screenshots to the destination
  # each time

  for language in $languages; do
    _clean_trace_results_dir
    bin/choose_sim_language $language
    _run_automation "automation/shoot_the_screens.js"
    _copy_screenshots
  done
}

function _xcode {
  # A wrapper around `xcodebuild` that tells it to build the app in the temp
  # directory. If your app uses workspaces or special schemes, you'll need to
  # specify them here.
  #
  # Use `man xcodebuild` for more information on how to build your project.

  xcodebuild -sdk "iphonesimulator$ios_version" \
    CONFIGURATION_BUILD_DIR=$build_dir \
    PRODUCT_NAME=app \
    $*
}

function _clean_trace_results_dir {
  # Removes the trace results directory. We need to do this because Instruments
  # keeps appending new trace runs and it's simpler for us to always assume
  # there's just one run recorded where we look for screenshots.

  rm -rf "$trace_results_dir"
  mkdir -p "$trace_results_dir"
}

function _run_automation {
  # Runs the UI Automation JavaScript file that actually takes the screenshots.

  dev_tools_dir=`xcode-select -print-path`
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

function _copy_screenshots {
  # Since we're always clearing out the trace results before every run, we can
  # assume that any screenshots were saved in the "Run 1" directory. Copy them
  # to the destination!

  mkdir -p "$destination"
  cp $trace_results_dir/Run\ 1/*.png $destination
}

main
