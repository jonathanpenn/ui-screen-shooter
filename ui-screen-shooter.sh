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

# We require a parameter for where to put the results and the test script
destination="$1"
ui_script="$2"

# The locale identifiers for the languages you want to shoot
# Use the format like en-US cmn-Hans for filenames compatible with iTunes
# connect upload tool
languages="en-US fr jp"

# The simulators we want to run the script against, declared as a Bash array.
# Run `instruments -w help` to get a list of all the possible string values.
declare -a simulators=(
"iPhone Retina (3.5-inch) - Simulator - iOS 7.1"
"iPhone Retina (4-inch) - Simulator - iOS 7.1"
"iPad Retina - Simulator - iOS 7.1"
)

function main {
  _check_destination
  _check_ui_script
  _xcode clean build

  for simulator in "${simulators[@]}"; do
    for language in $languages; do
      _clean_trace_results_dir
      _run_automation "$ui_script" "$language" "$simulator"
      _copy_screenshots "$language"
    done
  done

  _close_sim

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

function _check_ui_script {
  # Abort if the destination directory already exists. Better safe than sorry.

  if [ -z "$ui_script" ]; then
    ui_script="./shoot_the_screens.js"
  fi
  if [ ! -f "$ui_script" ]; then
    echo "UI script \"$ui_script\" does not exist! Aborting."
    exit 1
  fi
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

  automation_script="$1"
  language="$2"
  simulator="$3"

  echo "Running automation script \"$automation_script\"
          for \"$simulator\"
          in language \"${language}\"..."

  dev_tools_dir=`xcode-select -print-path`
  tracetemplate="$dev_tools_dir/../Applications/Instruments.app/Contents/PlugIns/AutomationInstrument.bundle/Contents/Resources/Automation.tracetemplate"

  # Check out the `unix_instruments.sh` script to see why we need this wrapper.
  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  "$DIR"/unix_instruments.sh \
    -w "$simulator" \
    -D "$trace_results_dir/trace" \
    -t "$tracetemplate" \
    $bundle_dir \
    -e UIARESULTSPATH "$trace_results_dir" \
    -e UIASCRIPT "$automation_script" \
    -AppleLanguages "($language)" \
    -AppleLocale "$language" \
    $*
}

function _copy_screenshots {
  # Since we're always clearing out the trace results before every run, we can
  # assume that any screenshots were saved in the "Run 1" directory. Copy them
  # to the destination's language folder!

  language="$1"

  mkdir -p "$destination/$language"
  cp $trace_results_dir/Run\ 1/*.png "$destination/$language"
}

function _close_sim {
  # I know, I know. It says "iPhone Simulator". For some reason,
  # that's the only way Applescript can identify it.
  osascript -e "tell application \"iPhone Simulator\" to quit"
}

main

