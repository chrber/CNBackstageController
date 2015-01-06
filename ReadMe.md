[![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=phranck&url=https://github.com/phranck/CNBackstageController&title=CNBackstageController&tags=github&category=software)
![Travis Status](https://travis-ci.org/phranck/CNBackstageController.png?branch=master)



## Overview

**`CNBackstageController` was a proof of concept and never found a place in a real application. Therefore it's no longer supported and development will be discontinued!**

-
`CNBackstageController` is an derivative of `NSWindowController` and a special impelementation to show you the content you would like to see. The goal of `CNBackstageController` is to provide the developer a slightly different interface for presenting an application.

It mimics the behavior you’ve just seen in Notification Center of Mountain Lion. Instead of showing a normal window and menu bar an application build with `CNBackstageController` offer you a behind the Finder-like desktop and will be shown with smooth animations. The common use is an application nested as a statusbar item that is not visible in the Dock.

Here is a shot of the included example application:

![CNBackstageController Example Application](https://dl.dropbox.com/u/34133216/WebImages/Github/CNBackstageController.png)


This screenshot is the result of the **horizontal screen split** animation effect:

![CNBackstageController - Horizontal Screen Split](https://dl.dropbox.com/u/34133216/WebImages/Github/CNBackstageController-Splitview.png)


## Requirements
`CNBackstageController` was written using ARC and should run on 10.7 and above. Also you have to add the QuartzCore Framework to your project.


## Contribution

The code is provided as-is, and it is far off being complete or free of bugs. If you like this component feel free to support it. Make changes related to your needs, extend it or just use it in your own project. Pull-Requests and Feedbacks are very welcome. Just contact me at [phranck@cocoanaut.com](mailto:phranck@cocoanaut.com?Subject=[CNBackstageController] Your component on Github) or send me a ping on Twitter [@TheCocoaNaut](http://twitter.com/TheCocoaNaut). 


## Documentation
The complete documentation you will find on [CocoaDocs](http://cocoadocs.org/docsets/CNBackstageController/).


## License
This software is published under the [MIT License](http://cocoanaut.mit-license.org).