Symbolicator
============

Symbolicator for iOS 6 - it's a mobile substrate lib that unhides "&lt;redacted>" addresses at runtima in calls made to +[NSThread callStackSymbols] or -[NSException callStackSymbols], by making use of Symbolicator.framework

Useful when debugging without the need to crash the application, or when reverse engineering some application or framework. This was the usual in iOS 5 and older, but in iOS 6 all of their frameworks symbols are be hidden (and later symbolicated in XCode with a CrashReport, but it is not possible to do so at runtime), probably due to the different format found on dyld_shared_cache

Before:
============
![Before](http://i.minus.com/jfz6PHQIhjxVS.png)

After:
============
![After](http://i.minus.com/jrlBCbM6FM19C.png)

Note: it is not able to symbolicate all addresses/frameworks, but most of them.
