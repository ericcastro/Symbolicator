Symbolicator
============

Now supports both ARM64 and ARM7!

Symbolicator for iOS 6 and iOS 7 - it's a Cydia Substrate library that reveals "&lt;redacted>" symbol names at runtime in calls made to +[NSThread callStackSymbols] or -[NSException callStackSymbols], by making use of Symbolicator.framework and the ObjC runtime

Useful when debugging without the need to crash the application, or when reverse engineering some application or framework. This was the usual in iOS 5 and older, but starting in iOS 6 all of their frameworks symbols are hidden (which you can later symbolicate in XCode with a CrashReport, but this is not possible to do at runtime), probably due to the different format found on dyld_shared_cache

### Installing ######

You require theos to compile the sources, or you can skip that step and just install a precompiled binary from this deb package:

http://eric.cast.ro/debs/ro.cast.eric.Symbolicator_0.0.1-1_iphoneos-arm.deb

The included filter plist hooks into SpringBoard only - you can manually modify it to suit your needs but... (read below)

### Important: ######
**Do NOT inject this library into all processes**. Choose the ones you will work with in your filter plist, because current version also uses the ObjC runtime to load all class and method names and while optimized, it is still very expensive. If you load it in every process, system will be likely to crash.

Before:
============
![Before](http://i.minus.com/jfz6PHQIhjxVS.png)

After:
============
![After](http://i.minus.com/jrlBCbM6FM19C.png)
