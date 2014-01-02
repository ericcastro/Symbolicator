//
//  Tweak.xm
//  Symbolicator
//
//  Created by Eric Castro on 13/02/13.
//
//

#import "Symbolicator.h"

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
        theSymbolicator = [[Symbolicator alloc] init];
    }
}