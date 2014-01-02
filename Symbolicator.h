//
//  Symbolicator.h
//  Symbolicator
//
//  Created by Eric Castro on 13/02/13.
//
//

#import <Foundation/Foundation.h>
#import <Symbolication/Symbolication.h>

#include "uthash.h"

struct MethodEntry {
    int imp;            /* we'll use this field as the key */
    char name[192];
    UT_hash_handle hh; /* makes this structure hashable */
};

@class CPDistributedMessagingCenter;

@interface Symbolicator : NSObject
{
    VMUSymbolicator *_symbolicator;
    VMUProcessDescription *_processInfo;
    VMUMachTaskContainer *_machContainer;
    
    struct MethodEntry *_methodList;
    
    unsigned int _maxAddress;
    unsigned int _minAddress;

}

- (NSDictionary *)symbolicateAddresses:(NSArray *)addresses;
- (NSString *)findMethod:(NSNumber *)address slide:(unsigned)slide;
- (unsigned)slideForAddress:(unsigned long long)address;

@end

@interface SCCallStackArray : NSArray
{
    NSMutableArray *_descriptions;
}

+ (id)arrayWithCallStack:(NSArray *)array;
- (id)initWithCallStack:(NSArray *)array;
- (void)loadSymbols:(NSDictionary *)symbols;

@end