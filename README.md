Musait-Yerde
============

An iOS 8 Today Extension proof-of-concept for onebusaway

I want to start by apologizing.
What I am apologizing for:
* No documentation
* Terrible hardcoded UI entirely handled by autoconstraint
* Disgusting Code
* Hardcoded Favorite Stop
* Unpublishable (Apple requires a functional Host App)

Everything about this project is embarrassing and the hope of placing it in public view is to force myself to improve it.

The extension is currently only semi-useful. At best.
##Favorite Stop (half-baked)
This section displays the next bus arriving at a user-specified stop. The user will be able to specify their favorite stop through a map interface in the main app. It is currently hardcoded for the stop I wanted to use this extension for. (Which pretty much gives away a large part of my identity right here) 
##Nearby Buses
This section will tell you the next bus for the nearest two stops. If it can't find two stops (a scenario I handle, despite there being no evidence of such a situation occuring) it will display the next two buses. It seems the onebusaway api can return buses that have already arrived (their estimatedArrivalTime is earlier than the current Time). I have done some inexplicably unforgivable things to skip over those buses. Instead of sorting or removing the offending elements I rip out the bus I have already displayed. This is disgusting. ~God~ Woz forgive me.

#The Plan

I have a plan. Its not ordered:

* Turn the UI to be UITableView-based, making it easy to add and drop incoming Buses.
* Remove the bulk of hte logic from the locationManager callback. Place the logic within the Table objects themselves. Or something?
* Build the Host App interface to at least provide a way to pick Stops.
* Experiment with more useful UI. Maybe a map? maybe more information about the stop and the bus. Is it possible to embed a map? that would be nice

 
