//
//  Symbolicator.h
//  Symbolicator
//
//  Created by Eric Castro on 13/02/13.
//
//

#import <Foundation/Foundation.h>

@class CPDistributedMessagingCenter;

@interface Symbolicator : NSObject
{
    CPDistributedMessagingCenter *_center;
}

+ (NSDictionary *)symbolicateAddresses:(NSArray *)addresses;

@end

@interface SCCallStackArray : NSArray
{
    NSMutableArray *_descriptions;
}

+ (id)arrayWithCallStack:(NSArray *)array;
- (id)initWithCallStack:(NSArray *)array;
- (void)loadSymbols:(NSDictionary *)symbols;

@end