#!/usr/bin/env bash
#
# Copyright (c) 2013 Jonathan Penn (http://cocoamanifest.net)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#


# unix_instruments
#
# A wrapper around `instruments` that returns a proper unix status code
# depending on whether the run failed or not. Alas, Apple's instruments tool
# doesn't care about unix status codes, so I must grep for the "Fail:" string
# and figure it out myself. As long as the command doesn't output that string
# anywhere else inside it, then it should work.
#
# I use a tee pipe to capture the output and deliver it to stdout
#
# Author: Jonathan Penn (jonathan@cocoamanifest.net)
#

set -e  # Bomb on any script errors

run_instruments() {
  # Pipe to `tee` using a temporary file so everything is sent to standard out
  # and we have the output to check for errors.
  output=$(mktemp -t unix-instruments)
  instruments "$@" 2>&1 | tee $output

  # Process the instruments output looking for anything that resembles a fail
  # message
  cat $output | get_error_status
}

get_error_status() {
  # Catch "Instruments Trace Error"
  # Catch "Instruments Usage Error"
  # Catch "00-00-00 00:00:00 +000 Fail:"
  # Catch "00-00-00 00:00:00 +000 Error:"
  # Catch "00-00-00 00:00:00 +000 None: Script threw an uncaught JavaScript error"
  ruby -e 'exit 1 if STDIN.read =~ /Instruments Usage Error|Instruments Trace Error|^\d+-\d+-\d+ \d+:\d+:\d+ [-+]\d+ (Fail:|Error:|None: Script threw an uncaught JavaScript error)/'
}

# Running this file with "----test" will try to parse an error out of whatever
# is handed in to it from stdin. Use this method to double check your work if
# you need a custom "get_error_status" function above.
if [[ $1 == "----test" ]]; then
  get_error_status
else
  run_instruments "$@"
fi
