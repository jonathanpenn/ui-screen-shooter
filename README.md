UI Screen Shots
===============

This is a set of scripts to demonstrate how to take screen shots for your iOS app for the App Store automatically using UI Automation. It shows how to take screen shots, extract them from the automation results and change the language in the simulator. This saves quite a bit of time since we need to generate screens for the 3.5" display, the 4" display, and both iPhone and iPad if your app is universal--not to mention that you'd have to do this for *every* localization you support in the store.

You can see the script run against one of my apps in [this video][readmorevid].

  [readmorevid]: http://nl1551.s3.amazonaws.com/cocoamanifest.net/2012/readmore-screenshots.mov

## Installation

First, you need to get Xcode from the App Store. It's free and comes with (almost) everything you need. Once you have Xcode installed, you need to install the command line tools. Choose "Preferences" from the "Xcode" menu. Choose the "Downloads" and choose the "Components" sub tab. You'll see "Command Line Tools" in the list. Click the install button next to it and wait until it finishes setting up.

Pull down the repository and change to the directory in the terminal.

## Usage

To run the demonstration, type `./run_screenshooter.sh ~/Desktop/screenshots` to dump the final screenshots to a directory on your Desktop. After a few minutes, you can open the destination directory and see all the languages, devices types and screen sizes as PNGs.

By default each screenshot is named like so:

    en-iphone5-portrait-screen1.png

The first part is the locale identifier, the second is the device (iphone, iphone5, ipad), the third is the device orientation, and the fourth is an identifier that you pick when you call the screenshot function.

All of the UI Automation scripts are in the `automation` directory for your perusal.

To see how to change the simulator language and how to extract the screenshots out of the automation trace results, see `run_screenshooter.sh`. I've put comments everywhere to try to explain it.

## How It Works

`run_screenshooter.sh` triggers a build of the application for the iOS simulator and puts the resulting bundle in `/tmp` with a custom name so it can find it. Then, the `instruments` command line tool is invoked which installs the app bundle and then executes `automation/run.js` which drives the simulator. In `run.js`, the app is manipulated to get each screen ready and then calls `captureLocalizedScreenshot()` to take each shot.

When the automation script ends, `run_screenshooter.sh` copies all the screenshots taken for that Instruments trace run and copies them to the destination directory. Then it continues on to execute the same automation script again with a new language or an a new device type. Check out the `main` function in `run_screenshooter.sh` for how this is all set up.

## For More Info

To learn more about UI Automation, check out my [collection of resources][automation] on [cocoamanifest.net](http://cocoamanifest.net).

  [automation]: http://cocoamanifest.net/features/#ui_automation

## Contributing

Feel free to fork the project and submit a pull request. If you have any good ideas to make this easier to set up for new users, that would be great!

## Contact

Questions? Ask!

Jonathan Penn

- http://cocoamanifest.net
- http://github.com/jonathanpenn
- http://twitter.com/jonathanpenn
- http://alpha.app.net/jonathanpenn
- jonathan@cocoamanifest.net

## License

UI Screen Shots is available under the MIT license. See the LICENSE file for more info.
