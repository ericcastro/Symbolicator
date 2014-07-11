//
//  Tweak.xm
//  Symbolicator
//
//  Created by Eric Castro on 13/02/13.
//
//

#import "Symbolicator.h"

static NSString *preferenceFilePath = @"/private/var/mobile/Library/Preferences/ro.cast.eric.Symbolicator.plist";
static Symbolicator *theSymbolicator = nil;

%hook NSThread

+ (NSArray *) callStackSymbols
{
    NSArray *addresses = [NSThread callStackReturnAddresses];

    NSDictionary *symbols = [theSymbolicator symbolicateAddresses:addresses]; // where the magic happens
    SCCallStackArray *callStackSymbols = [SCCallStackArray arrayWithCallStack:%orig];
    [callStackSymbols loadSymbols:symbols];

    return callStackSymbols;
}

%end

%hook NSException

- (NSArray *) callStackSymbols
{
    NSArray *addresses = [self callStackReturnAddresses];

    NSDictionary *symbols = [theSymbolicator symbolicateAddresses:addresses]; // where the magic happens
    SCCallStackArray *callStackSymbols = [SCCallStackArray arrayWithCallStack:%orig];
    [callStackSymbols loadSymbols:symbols];

    return callStackSymbols;
}

%end

%ctor
{
    @autoreleasepool
    {

        // Load preferences
        NSMutableDictionary *preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:preferenceFilePath];
        // Only inject into Apps the user has selected in the settings panel
        NSString *appId = [[NSBundle mainBundle] bundleIdentifier];
        id shouldHook = [preferences objectForKey:appId];
        [preferences release];

        if ((shouldHook == nil) || (![shouldHook boolValue]))
        {
            // Don't load Symbolicator
        }
        else
        {
            NSLog(@"Symbolicator loaded");
            theSymbolicator = [[Symbolicator alloc] init];
        }
    }
}
