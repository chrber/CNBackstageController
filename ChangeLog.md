##ChangeLog

**v1.1.0** ||| *11-09-2012*
- **Added**: tags in Github repository to handle versioning
- **Added**: possibility for resizing the applicationView by dragging the coverage
- **Added**: notifications for each delegate, send on a delegate call automatically
- **Added**: new delegate methods and notifications related to the new resizing feature
- **Added**: property `BOOL useShadowsOnApplicationView` to control the drawing of shadows on applicationView
- **Added**: property `BOOL applicationViewResizeable` to control the resizing feature of applicationView
- **Added**: property `NSSize applicationViewMinSize` to define a minimum size of the applicationView related to the active `toggleEdge` property
- **Changed**: File splitting - `CNBackstageDelegate` and `CNBackstageShadowView` are no longer included in `CNBackstageController`. They are seperate files by now.
- **Changed**: the property `toggleSize` is no longer a `NSUInteger`!<br>It is a `CNToggleSize` struct which makes more sense regarding its name. Please take a look at the [documentation](http://cnbackstagecontroller.cocoanaut.com/documentation/Classes/CNBackstageController.html#//api/name/toggleSize) for more details.

-
**v1.0.0** ||| *11-01-2012*
- first initial version