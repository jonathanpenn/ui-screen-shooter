UI Screen Shooter
=================

**DEPRECATED**

I'm no longer able to maintain the development of this project, but fear not! [Felix Krause][k] has done a fantastic job integrating iOS screenshot capability in his all-encompasing [fastlane][f] project. I would recommend looking into his [screenshot][s] project for your needs.

  [k]: https://github.com/KrauseFx
  [f]: https://fastlane.tools
  [s]: https://github.com/fastlane/snapshot


----

UI Screen Shooter will take screen shots for your iOS app for the App Store automatically using UI Automation. This will produce the images needed in each localization, for each device, and in each screen of the app you need. This saves quite a bit of time since we need to generate screens for the 3.5", 4", 4.5", and 5.5" displays, and both iPhone and iPad if your app is universal--not to mention that you have to do this for *every* localization you support in the store.

## Prerequisites

You will need <a href="https://developer.apple.com/xcode/">Apple's Xcode</a> and its included instruments. Additionally, install command line tools using Xcode 5 or later by running `xcode-select --install` in your Terminal.<br>
**Optional**: ImageMagick, to remove alpha channel (which iTunes Connect requires). Script will run regardless of whether its installed or not.

## Demonstration

To run the demonstration, copy the two example config files and rename them without "example", then run `./ui-screen-shooter.sh` from inside the project directory. After a few minutes, you can open the destination directory and see all the languages, devices types and screen sizes as PNGs. By default each screenshot is saved to `~/Desktop/screenshots/` named like so:

    en_US/iphone5-portrait-screen1.png
    ...

You can see the script run against one of [my apps](http://readmoreapp.com) in [this video][readmorevid].

  [readmorevid]: http://nl1551.s3.amazonaws.com/cocoamanifest.net/2012/readmore-screenshots.mov

## Usage

To use UI Screen Shooter, clone or download inside your project's folder. Then copy the example config files and rename without "example". You may need to change the "Release" build configuration to add i386 to the `VALID_ARCHITECTURES` for this to work. Then play with the script `automation/config-automation.js` to simulate the user interaction you want. After your screen shots are saved, see https://github.com/rhaining/itc-localized-screenshot-uploader about uploading them in batch to iTunes connect.

## How It Works

`ui-screen-shooter.sh` triggers a build of the application for the iOS simulator and puts the resulting bundle in `/tmp` with a custom name so it can find it.  Then, the `instruments` command line tool is invoked which installs the app bundle and then executes `automation/shoot_the_screens.js` which drives the simulator. `config-automation.js` drives the app and calls `captureLocalizedScreenshot()` to shoot each image after navigating to the right screen.

`captureLocalizedScreenshot()` is a custom method that checks for the device and whether it's a 4" display or not, deduces the orientation, and generates the screenshot file name along with the user supplied identifier. Once the name is calculated, it calls `captureScreenWithName()` on the `UIATarget` which saves the image along with the Instruments trace results in `/tmp`.

After each time the automation script ends, `ui-screen-shooter.sh` copies all the screenshots taken for that Instruments trace run and copies them to locale subdirectories in the destination directory. Then it continues on to execute the same automation script again with a new language or an a new device type. Check out the `main` function in `ui-screen-shooter.sh` for how this is all set up.

The app build process may be the most difficult part for you if you're trying to integrate this with your project. `xcodebuild` needs extra details if you're using an explicit workspace or using a beta version of the dev tools. If the app isn't building, see if you can try to get `xcodebuild` to work yourself and then alter the `xcode` function in `ui-screen-shooter.sh` to match your setup.

## For More Info

To learn more about UI Automation, check out my [collection of resources][automation] on [cocoamanifest.net](http://cocoamanifest.net).

  [automation]: http://cocoamanifest.net/features/#ui_automation

## Contributing

Feel free to fork the project and submit a pull request. If you have any good ideas to make this easier to set up for new users, that would be great!

## Thanks

Thanks to all who have submitted pull requests and offered improvements. Special thanks to Ole Begemann for [his marvelous post on NSUserDefaults][n] that inspired me to pass the locale information in on the command line rather than what I was doing before by manipulating the simulate preference plist files.

  [n]: http://oleb.net/blog/2014/02/nsuserdefaults-handling-default-values/

## Contact

Questions? Ask!

Jonathan Penn

- http://cocoamanifest.net
- http://rubbercitywizards.com
- http://github.com/jonathanpenn
- http://twitter.com/jonathanpenn
- http://alpha.app.net/jonathanpenn
- jonathan@cocoamanifest.net

## License

UI Screen Shooter is available under the MIT license. See the LICENSE file for more info.

