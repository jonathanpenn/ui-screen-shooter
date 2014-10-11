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

# Global variables to keep track of where everything goes
tmp_dir="/tmp"
build_dir="$tmp_dir/screen_shooter"
bundle_dir="$build_dir/app.app"
trace_results_dir="$build_dir/traces"
tmp_ui_script="./.ui-screen-shooter-tmp.js"


export UISS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ "$DEBUG" ]; then
  echo "DEBUG: Using UISS_DIR=$UISS_DIR"
fi

#default options
config_file="./config-screenshots.sh"
destination="$HOME/Desktop/screenshots" 
ui_script="./config-automation.js"

function usage {
  echo 
  echo "Usage $0  [options]" 1>&2; 
  echo 
  echo "   Options:"
  echo "     -c, --config-file <config_file> # set config file. Default: $config_file"
  echo "     -o, --output-dir <path>         # set screenshots output directory. Default: $destination"
  echo "     -u, --ui-script <script_file>   # set ui-script. Default: $ui_script"
  echo "     -f, --force                     # force overwrite output directory if exists"
  echo "     -s, --skip-build                # skip building the project"
  echo "     -h, --help                      # display this help"
  exit 1;  
}

#get options
while :
do
  case "$1" in    #in alphabetical order
    -c | --config-file) 
      config_file="$2"
      shift 2
      ;;
    -f | --force)
	    force="force"   
      shift
	    ;;
    -h | --help)
	    usage  # Call your function
	    ;;
    -s | --skip-build)
      skip_build="skip-build"
      shift
      ;;
    -u | --ui-script)
	    ui_script="$2" # You may want to check validity of $2
	    shift 2
	    ;;
    -o | --output-dir)
      destination="$2"
      shift 2
      ;;
    -v | --verbose)
 	    verbose="verbose"
	    shift
	    ;;
    --) # End of all options
	     shift
	     break
       ;;
    -*)
	    echo "Error: Unknown option: $1" >&2
      usage
	    exit 1
	    ;;
    *) 
       # No more options
	    break
	    ;;
    esac
done


function main {
  
  # Load configuration
  # Not in a separate function because you can't export arrays
  # https://stackoverflow.com/questions/5564418/exporting-an-array-in-bash-script
  # Will export languages and simulators bash variables
  if [ -f "$config_file" ]; then
    source "$config_file"
  else
    echo "Config file \"$config_file\" not found. Aborting!"
    echo "Read README.md to know more about this file."
    exit 1
  fi
 
  _check_destination
  _check_ui_script
  # run xcode except if --skip-build option is set
  if [ ! -n "$skip_build" ]; then
    _xcode clean build
  fi
  
  _create_dyn_js_file
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


function _check_destination {
  # Abort if the destination directory already exists except if force option set.
  # Better safe than sorry.

  if [ -d "$destination" ]; then
    if [ ! -n "$force" ]; then
      echo "Output directory \"$destination\" already exists! Aborting."
      echo "You can use --force option to overwrite its contents."
      exit 1
    fi
  fi
}

function _check_ui_script {
  # Abort if the UI script does not exist.

  if [ ! -f "$ui_script" ]; then
      echo "UI Automation script file \"$ui_script\" does not exist! Aborting."
      echo "Read Readme.md to know more about this file"
      exit 1
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
      -workspace $base.xcworkspace -scheme $base -configuration AdHoc \
      DSTROOT=$build_dir \
      OBJROOT=$build_dir \
      SYMROOT=$build_dir \
      ONLY_ACTIVE_ARCH=NO \
    "$@"
    xcodebuild -sdk "iphonesimulator$ios_version" \
      CONFIGURATION_BUILD_DIR="$build_dir/build" \
      PRODUCT_NAME=app \
      -workspace $base.xcworkspace -scheme $base -configuration AdHoc \
      DSTROOT=$build_dir \
      OBJROOT=$build_dir \
      SYMROOT=$build_dir \
      ONLY_ACTIVE_ARCH=NO \
    "$@"
    cp -r "$build_dir/build/app.app" "$build_dir"
  else
    xcodebuild -sdk "iphonesimulator$ios_version" \
      CONFIGURATION_BUILD_DIR=$build_dir \
      PRODUCT_NAME=app \
    "$@"
  fi
}

function real_path() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

function _create_dyn_js_file {
  #Creates a UIAutomation js file that automatically imports all js files in UISS_DIR/../lib/
  #get the path to lib
  
  lib_js_files=`ls "$UISS_DIR"/../lib/*.js`
  if [ "$DEBUG" ]; then
    echo "DEBUG: ui-screen-shooter library_files: $lib_js_files"
  fi
  echo "//temporary file created by ui-screen-shooter." > $tmp_ui_script
  echo "//add it to your .gitignore" >> $tmp_ui_script
  for lib_js_file in $lib_js_files; do
    real_lib_js_file_path=$(real_path $lib_js_file)
    echo "Adding library file: $real_lib_js_file_path" 
    echo "#import \"$real_lib_js_file_path\"" >> $tmp_ui_script
  done
  real_ui_script_path=$(real_path "$ui_script")
  echo "#import \"$real_ui_script_path\"" >> $tmp_ui_script
  
  if [ "$DEBUG" ]; then
    echo "DEBUG: $tmp_ui_script contents:"
    cat $tmp_ui_script
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
  "$UISS_DIR"/unix_instruments.sh \
    -w "$simulator " \
    -D "$trace_results_dir/trace" \
    -t "$tracetemplate" \
    $bundle_dir \
    -e UIARESULTSPATH "$trace_results_dir" \
    -e UIASCRIPT "$tmp_ui_script" \
    -AppleLanguages "($language)" \
    -AppleLocale "$language" 
   
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

function _close_sim {
  # I know, I know. It says "iPhone Simulator". For some reason,
  # that's the only way Applescript can identify it.
  osascript -e "tell application \"iPhone Simulator\" to quit"
}

main

