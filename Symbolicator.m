//
//  Symbolicator.m
//  Symbolicator
//
//  Created by Eric Castro on 13/02/13.
//
//

#import <Symbolication/Symbolication.h>

#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>
#include <mach/mach.h>

#import "Symbolicator.h"

#define kSCSymbolsRequest @"SCSymbolsRequest"
#define kSCMessagingCenterName @"ro.cast.eric.Symbolicator"

static VMUSymbolicator *_symbolicator = nil;

@implementation Symbolicator

+ (NSDictionary *)symbolicateAddresses:(NSArray *)addresses
{
    NSMutableDictionary *response = [NSMutableDictionary dictionaryWithCapacity:addresses.count];
    
    if (!_symbolicator)
        _symbolicator = [[VMUSymbolicator symbolicatorForTask:mach_task_self()] retain];
    
    NSString *hexAddress;
    unsigned long long longLongAddress;
    
    // Try to get the symbols for all requested addresses
    for (NSNumber *address in addresses)
    {
        longLongAddress = [address unsignedLongLongValue];
        
        // This will reveal the symbol needed for a specific address
        VMUSymbol *symbol = [_symbolicator symbolForAddress:longLongAddress];
        
        // Symbol name has the objc method format -[SomeClass someMethod]
        if ([symbol name])
        {
            hexAddress = [NSString stringWithFormat:@"0x%08llx",longLongAddress];
            response[hexAddress] = [symbol name];
        }
        
    }
    return response;
}

@end

// Replacement for _NSCallStackArray - imitates the exact same output when printed with NSLog

@implementation SCCallStackArray

+ (id)arrayWithCallStack:(NSArray *)array
{
    return [[[SCCallStackArray alloc] initWithCallStack:array] autorelease];
}

- (id)initWithCallStack:(NSArray *)array
{
    self = [super init];
    if (self) {
        _descriptions = [[NSMutableArray alloc] initWithCapacity:[array count]];
        
        NSString *pos, *nextpos;
        
        for (int i=0;i<[array count]-1;i++) //fugly stuff - must eliminate first line (that's Symbolicator's call you don't need) and preserve the numbers with the correct spacing
        {
            pos = [array[i] componentsSeparatedByString:@" "][0];
            nextpos = [array[i+1] componentsSeparatedByString:@" "][0];
            _descriptions[i] = [NSString stringWithFormat:@"%@ %@",pos,[array[i+1] substringFromIndex:[nextpos length]]];
        }
    }
    
    return self;
}

- (unsigned int)count
{
    return [_descriptions count];
}

- (id)objectAtIndex:(unsigned int)index
{
    return _descriptions[index];
}

- (id)descriptionWithLocale:(id)locale indent:(unsigned int)level
{
    NSString *indentation = [@"" stringByPaddingToLength:4*level withString:@" " startingAtIndex:0];
    
    NSMutableString *output = [NSMutableString stringWithCapacity:4096];
    [output appendString:indentation];
    [output appendString:@"(\n"];
    for (NSString *line in _descriptions)
        [output appendFormat:@"%@\t%@\n",indentation,line];
    [output appendString:indentation];
    [output appendString:@")"];
    return [NSString stringWithString:output];
}

- (void) loadSymbols:(NSDictionary *)symbols // Replace all <redacted> strings with actual symbol names
{
    for (int i=0;i<[_descriptions count];i++)
        for (NSString *hexAddress in [symbols allKeys])
            _descriptions[i] = [_descriptions[i] stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@ <redacted>",hexAddress] withString:[NSString stringWithFormat:@"%@ %@",hexAddress,symbols[hexAddress]]];
}

- (void)dealloc
{
    [_descriptions release];
    [super dealloc];
}

@end