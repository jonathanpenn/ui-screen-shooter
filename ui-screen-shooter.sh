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

function main {
  # Load configuration
  # Not in a separate function because you can't exort arrays
  # https://stackoverflow.com/questions/5564418/exporting-an-array-in-bash-script
  # Will export languages and simulators bash variables
  export UISS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  if [ -f "$UISS_DIR"/config-screenshots.sh ]; then
    source "$UISS_DIR"/config-screenshots.sh
  else
    if [ -f "$UISS_DIR"/config-screenshots.example.sh ]; then
      source "$UISS_DIR"/config-screenshots.example.sh
      echo "WARNING: Using example config-screenshots file, you should create your own"
    else
      echo "Configuration \"config-screenshots.sh\" does not exist! Aborting."
      exit 1
    fi
  fi

  _check_destination
  _check_ui_script
  _close_sim
  _reset_all_sim
  _xcode clean build

  for simulator in "${simulators[@]}"; do
    for language in $languages; do
      _clean_trace_results_dir
      _run_automation "$ui_script" "$language" "$simulator"
      _copy_screenshots "$language"
    done
  done

  _close_sim

  _remove_alpha_from_screenshots

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
  # Abort if the UI script does not exist.

  if [ -z "$ui_script" ]; then
    ui_script="./config-automation.js"
  fi
  if [ ! -f "$ui_script" ]; then
    if [ -f "./config-automation.example.js" ]; then
      ui_script="./config-automation.js"
      echo "WARNING: Using example config-automation, please create your own"
    else
      echo "Config-automation does not exist! Aborting."
      exit 1
    fi
  fi
}

function _xcode {
  # A wrapper around `xcodebuild` that tells it to build the app in the temp
  # directory. If your app uses workspaces or special schemes, you'll need to
  # specify them here.
  #
  # Use `man xcodebuild` for more information on how to build your project.
  if test -n "$(find . -maxdepth 1 -name '*.xcworkspace' -print -quit)"
  then
    base=$(basename *.xcworkspace .xcworkspace)
    # First build omits PRODUCT_NAME
    # Do NOT ask me why you need to build this twice for it to work
    # or how I became to know this fact
    xcodebuild -sdk "iphonesimulator$ios_version" \
      CONFIGURATION_BUILD_DIR="$build_dir/build" \
      -workspace "$base.xcworkspace" -scheme "$base" -configuration Debug \
      DSTROOT=$build_dir \
      OBJROOT=$build_dir \
      SYMROOT=$build_dir \
      GCC_PREPROCESSOR_DEFINITIONS='$GCC_PREPROCESSOR_DEFINITIONS SCREENSHOTS=1' \
      ONLY_ACTIVE_ARCH=NO \
    "$@"
    xcodebuild -sdk "iphonesimulator$ios_version" \
      CONFIGURATION_BUILD_DIR="$build_dir/build" \
      -workspace "$base.xcworkspace" -scheme "$base" -configuration Debug \
      DSTROOT=$build_dir \
      OBJROOT=$build_dir \
      SYMROOT=$build_dir \
      GCC_PREPROCESSOR_DEFINITIONS='$GCC_PREPROCESSOR_DEFINITIONS SCREENSHOTS=1' \
      ONLY_ACTIVE_ARCH=NO \
    "$@"
    cp -r "$build_dir/build/$base.app" "$build_dir"
    bundle_dir="$build_dir/$base.app"
  else
    xcodebuild -sdk "iphonesimulator$ios_version" \
      CONFIGURATION_BUILD_DIR=$build_dir \
      PRODUCT_NAME=app \
    "$@"
  fi
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
  tracetemplate="Automation"

  # Check out the `unix_instruments.sh` script to see why we need this wrapper.
  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  until "$DIR"/unix_instruments.sh \
    -w "$simulator" \
    -D "$trace_results_dir/trace" \
    -t "$tracetemplate" \
    "$bundle_dir" \
    -e UIARESULTSPATH "$trace_results_dir" \
    -e UIASCRIPT "$automation_script" \
    -AppleLanguages "($language)" \
    -AppleLocale "$language"
   do
    echo Instruments failed to start up... retrying in 2 seconds
    sleep 2
  done

  find $trace_results_dir/Run\ 1/ -name *landscape*png -type f -exec sips -r -90 \{\} \;
}

function _copy_screenshots {
  # Since we're always clearing out the trace results before every run, we can
  # assume that any screenshots were saved in the "Run 1" directory. Copy them
  # to the destination's language folder!

  language="$1"

  mkdir -p "$destination/$language"
  cp $trace_results_dir/Run\ 1/*.png "$destination/$language"
}

function _reset_all_sim {
  # Reset all apps and data on from all iOS Simulators
  # Attention: Simulator can only be reset if it is not opend
  instruments -s devices \
   | grep Simulator \
   | grep -o "[0-9A-F]\{8\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{12\}" \
   | while read -r line ; do
      echo "Reseting Simulator with UDID: $line"
      xcrun simctl erase $line
  done
}

function _close_sim {
  # I know, I know. It says "iOS Simulator". For some reason,
  # that's the only way Applescript can identify it.
  osascript -e "tell application \"iOS Simulator\" to quit"
}

function _remove_alpha_from_screenshots {
  if ! type "convert" &> /dev/null; then
    echo -e "\nCannot remove alpha channel because ImageMagick is not installed. You need to remove alpha before you can upload to iTunes Connect."
  else
    language="$1"
    for entry in $(ls $destination/*/iOS*.png); do
    convert "$entry" -background white -alpha off "$entry"
    done
    echo -e "\nScreenshots' alpha channel removed."
  fi
}

main

