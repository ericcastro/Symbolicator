//
//  Symbolicator.m
//  Symbolicator
//
//  Created by Eric Castro on 13/02/13.
//
//

#import <AppSupport/AppSupport.h>

#include <mach/mach.h>
#include <objc/runtime.h>
#include <sys/time.h>

#import "Symbolicator.h"

#ifdef __arm64__
#define ADDRESS_FORMAT "0x%016llx"
#else
#define ADDRESS_FORMAT "0x%08llx"
#endif

MethodEntry *createMethodEntry(NSUInteger imp, const char *className,const char *methodName, BOOL isClassMethod)
{
    MethodEntry *entry = (MethodEntry *)malloc(sizeof(MethodEntry));
    entry->imp = imp;
    entry->name[0] = NO ? '+' : '-';
    entry->name[1] = '[';
    strcpy(entry->name+2,className);
    entry->name[strlen(className)+2] = ' ';
    strcpy(entry->name+strlen(className)+3,methodName);
    strcpy(entry->name+strlen(className)+strlen(methodName)+3,"]");
    
    return entry;
}

@implementation Symbolicator

- (id)init
{
    self = [super init];
    if (self) {
        
        _symbolicator = [[VMUSymbolicator symbolicatorForTask:mach_task_self()] retain];
        _processInfo = [[VMUProcessDescription alloc] initWithPid:0 orTask:mach_task_self()];
        _machContainer = [[VMUMachTaskContainer machTaskContainerWithTask:mach_task_self()] retain];
        
        //dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self load];
        //});
        
    }
    return self;
}

- (void) load
{
    NSLog(@"Symbolicator: Loading all methods addresses from objc runtime");
    
    unsigned int numClasses;
    unsigned int numInstanceMethods;
    unsigned int numClassMethods;
    Class * classes = NULL;
    Method * instanceMethods = NULL;
    Method * classMethods = NULL;
    
    classes = NULL;
    char className[128];
    numClasses = objc_getClassList(NULL, 0);
        
    NSUInteger imp;
    
    _maxAddress = 0;
    _minAddress = 2^32;
    
    timeval time1, time2;
    gettimeofday(&time1, NULL);
    long millis1 = (time1.tv_sec * 1000) + (time1.tv_usec / 1000);
    
    MethodEntry *entry;
    if (numClasses > 0)
    {
        classes = (Class *)malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        
        for (int i=0;i<numClasses;i++)
        {
            classMethods = class_copyMethodList(objc_getMetaClass(class_getName(classes[i])), &numClassMethods);
            instanceMethods = class_copyMethodList(classes[i], &numInstanceMethods);
            
            for (int j=0; j<numClassMethods; j++) {
                imp = (NSUInteger)method_getImplementation(classMethods[j]);
                entry = createMethodEntry(imp, class_getName(classes[i]), sel_getName(method_getName(classMethods[j])), YES);
                
                HASH_ADD_INT(_methodList, imp, entry);
                
                if (imp > _maxAddress) _maxAddress = imp;
                if (imp < _minAddress) _minAddress = imp;
            }
            
            for (int j=0; j<numInstanceMethods; j++) {
                imp = (NSUInteger)method_getImplementation(instanceMethods[j]);
                entry = createMethodEntry(imp, class_getName(classes[i]), sel_getName(method_getName(instanceMethods[j])), NO);
                
                HASH_ADD_INT(_methodList, imp, entry);
                
                if (imp > _maxAddress) _maxAddress = imp;
                if (imp < _minAddress) _minAddress = imp;
            }
            
            free(classMethods);
            free(instanceMethods);
        }
        
        free(classes);
    }
    
    gettimeofday(&time2, NULL);
    long millis2 = (time2.tv_sec * 1000) + (time2.tv_usec / 1000);
    
    NSLog(@"Symbolicator: All addresses loaded and sorted %ld milliseconds",millis2-millis1);

}

- (NSDictionary *)symbolicateAddresses:(NSArray *)addresses
{
    NSMutableDictionary *response = [NSMutableDictionary dictionaryWithCapacity:addresses.count];
    
    NSString *hexAddress;
    
    NSString *methodName;
    NSUInteger longLongAddress;
    
    // Try to get the symbols for all requested addresses
    for (NSNumber *address in addresses)
    {
        longLongAddress = [address unsignedIntegerValue];
        hexAddress = [NSString stringWithFormat:@""ADDRESS_FORMAT,longLongAddress];

        
        methodName = [self findMethod:address slide:[self slideForAddress:longLongAddress]];
        if (methodName)
        {
            response[hexAddress] = methodName;
            continue;
        }
        
        VMUSymbol *symbol = [_symbolicator symbolForAddress:longLongAddress];

        if ([symbol name])
            response[hexAddress] = [symbol name];
        
    }
    
    return response;
}

- (NSString *)findMethod:(NSNumber *)address slide:(NSUInteger)slide
{
    NSUInteger newAddress = [address unsignedIntegerValue];
    unsigned searchCount = 0;
    
    struct MethodEntry *entry;
    
    do {
        
        entry = NULL;
        HASH_FIND_INT( _methodList, &newAddress, entry );
        
        if (entry)
            return [NSString stringWithFormat:@"("ADDRESS_FORMAT"): %s", newAddress-slide-1, entry->name];
        
        searchCount++;
        

        if (searchCount > 8096)
             return [NSString stringWithFormat:@"("ADDRESS_FORMAT"): <not found>", [address unsignedIntegerValue]-slide-1];
        
        newAddress = newAddress-1;
        
    } while (newAddress!=_minAddress);
    
    return nil;
}

- (NSUInteger)slideForAddress:(NSUInteger)address
{
    VMUMemory_NonContiguousTask *memory;
    VMUMachOHeader *header;
    VMURange range;
    NSUInteger textStart;
    
    for (NSDictionary *image in _processInfo.binaryImages)
    {
        range.location = [image[@"StartAddress"] unsignedIntegerValue];
        range.length = [image[@"Size"] unsignedIntegerValue];
        
        if (address >= range.location &&
            address <= range.location+range.length)
        {
            memory = [VMUMemory_NonContiguousTask memoryWithMachTaskContainer:_machContainer addressRange:range architecture:[VMUArchitecture currentArchitecture]];
            header = [VMUMachOHeader headerWithMemory:memory address:range.location name:image[@"Identifier"] path:image[@"ExecutablePath"] timestamp:[NSDate date]];
            textStart = [[header segmentNamed:@"__TEXT"] vmaddr];
            
            return range.location-textStart;
        }
    }
    return 0;
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
        
        for (int i=0;i<[array count];i++) //fugly stuff - must eliminate first line (that's Symbolicator's call you don't need) and preserve the numbers with the correct spacing
        {
//            pos = [array[i] componentsSeparatedByString:@" "][0];
//            nextpos = [array[i+1] componentsSeparatedByString:@" "][0];
//            _descriptions[i] = [NSString stringWithFormat:@"%@ %@",pos,[array[i+1] substringFromIndex:[nextpos length]]];

            _descriptions[i] = array[i];
        }
    }
    
    return self;
}

- (NSUInteger)count
{
    return [_descriptions count];
}

- (id)objectAtIndex:(NSUInteger)index
{
    return _descriptions[index];
}

- (id)descriptionWithLocale:(id)locale indent:(NSUInteger)level
{
    NSString *indentation = [@"" stringByPaddingToLength:level withString:@" " startingAtIndex:0];
    
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
            _descriptions[i] = [[_descriptions[i] stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@",hexAddress] withString:[NSString stringWithFormat:@"%@ %@",hexAddress,symbols[hexAddress]]] stringByReplacingOccurrencesOfString:@"<redacted>" withString:@""];
}

- (void)dealloc
{
    [_descriptions release];
    [super dealloc];
}

@end