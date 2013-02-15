//
//  Tweak.xm
//  Symbolicator
//
//  Created by Eric Castro on 13/02/13.
//
//

#import "Symbolicator.h"

%hook NSThread

+ (NSArray *) callStackSymbols
{
    NSArray *addresses = [NSThread callStackReturnAddresses];
    
    NSDictionary *symbols = [Symbolicator symbolicateAddresses:addresses]; // where the magic happens
    SCCallStackArray *callStackSymbols = [SCCallStackArray arrayWithCallStack:%orig];
    [callStackSymbols loadSymbols:symbols];
    
    return callStackSymbols;
}

%end

%hook NSException

- (NSArray *) callStackSymbols
{
    NSArray *addresses = [self callStackReturnAddresses];
    
    NSDictionary *symbols = [Symbolicator symbolicateAddresses:addresses]; // where the magic happens
    SCCallStackArray *callStackSymbols = [SCCallStackArray arrayWithCallStack:%orig];
    [callStackSymbols loadSymbols:symbols];
    
    return callStackSymbols;
}

%end