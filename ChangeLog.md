##ChangeLog

**v1.1.2** ||| *11-16-2012*
- **Fixed**: a bug that occurs if the example was (complied &) executed on OSX 10.7.x
- **Fixed**: a bug that occurs by sliding on the left side
- **Changed**: handling to control the drawing of shadows
- **Updated**: example application (shadow handling)
- **Added**: property 'useShadow' on CNBackstageShadowView

-
**v1.1.1** ||| *11-14-2012*
- **Changed**: API - some method names/signatures were changed:<br />
               - `changeViewStateToOpen` &rarr; `expand`<br />
               - `changeViewStateToClose` &rarr; `collapse`<br />
- **Changed**: some enum type names/member names were changed:<br />
			   - `CNToggleStateOpened` &rarr; `CNToggleStateExpanded`<br />
			   - `CNToggleStateClosed` &rarr; `CNToggleStateCollapsed`<br />
- **Changed**: some notification names were changed:<br />
			   - `CNBackstageControllerWillOpenScreenNotification` &rarr; `CNBackstageControllerWillExpandOnScreenNotification`<br />
			   - `CNBackstageControllerDidOpenScreenNotification` &rarr; `CNBackstageControllerDidExpandOnScreenNotification`<br />
			   - `CNBackstageControllerWillCloseScreenNotification` &rarr; `CNBackstageControllerWillCollapseOnScreenNotification`<br />
			   - `CNBackstageControllerDidCloseScreenNotification` &rarr; `CNBackstageControllerDidCollapseOnScreenNotification`<br />
- **Changed**: some delegate method names were changed:<br />
               - `backstageController:willOpenScreen:onToggleEdge:` &rarr; `backstageController:willExpandOnScreen:onToggleEdge:`<br />
               - `backstageController:didOpenScreen:onToggleEdge:` &rarr; `backstageController:didExpandOnScreen:onToggleEdge:`<br />
               - `backstageController:willCloseScreen:onToggleEdge:` &rarr; `backstageController:willCollapseOnScreen:onToggleEdge:`<br />
               - `backstageController:didCloseScreen:onToggleEdge:` &rarr; `backstageController:didCollapseOnScreen:onToggleEdge:`<br />

-
**v1.1.0** ||| *11-09-2012*
- **Changed**: File splitting - `CNBackstageDelegate` and `CNBackstageShadowView` are no longer included in `CNBackstageController`. They are seperate files by now.
- **Changed**: the property `toggleSize` is no longer a `NSUInteger`!<br>It's a `CNToggleSize` struct which makes more sense regarding its name. Please take a look at the [documentation](http://cnbackstagecontroller.cocoanaut.com/documentation/Classes/CNBackstageController.html#//api/name/toggleSize) for more details.
- **Added**: tags in Github repository to handle versioning
- **Added**: possibility for resizing the applicationView by dragging the coverage
- **Added**: notifications for each delegate, send on a delegate call automatically
- **Added**: new delegate methods and notifications related to the new resizing feature
- **Added**: property `BOOL useShadowsOnApplicationView` to control the drawing of shadows on applicationView
- **Added**: property `BOOL applicationViewResizeable` to control the resizing feature of applicationView
- **Added**: property `NSSize applicationViewMinSize` to define a minimum size of the applicationView related to the active `toggleEdge` property

-
**v1.0.0** ||| *11-01-2012*
- first initial version