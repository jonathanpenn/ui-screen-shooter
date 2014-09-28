// This is an example configuration file to be used with ui-screen-shooter
// It is designed to work with the Hello World International application
// Please copy to config-automation.js and edit for your needs
// See also http://cocoamanifest.net/features/#ui_automation for automation help


// Pull in the special function, captureLocalizedScreenshot(), that names files
// according to device, language, and orientation
#import "capture.js"

// Now, we simply drive the application! For more information, check out my
// resources on UI Automation at http://cocoamanifest.net/features
var target = UIATarget.localTarget();
var window = target.frontMostApp().mainWindow();

captureLocalizedScreenshot("screen1");

window.buttons()[0].tap();
target.delay(0.5);

captureLocalizedScreenshot("screen2");
