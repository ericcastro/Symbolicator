Symbolicator
============

Symbolicator for iOS 6 - unhides "&lt;redacted>" addresses in calls made to +[NSThread callStackSymbols] or -[NSException callStackSymbols], by making use of Symbolicator.framework

Before:
============
![Before](http://i.minus.com/jfz6PHQIhjxVS.png)

After:
============
![After](http://i.minus.com/jrlBCbM6FM19C.png)

Note: it is not able to symbolicate all addresses, but most of them.
