//
//  main.m
//  FileQueue
//
//  Copyright © 2016年 xlcw. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "FileQueue.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
//        NSLog(@"Hello, World!");
//        
//        NSMutableData *mData = [[NSMutableData alloc]initWithLength:8];
//        
//        int intValue = 10000;
//        
//        [mData replaceBytesInRange:NSMakeRange(0, 4) withBytes:&intValue];
//        
//        
//        int intValue2 = 3;
//        
//        [mData replaceBytesInRange:NSMakeRange(4,4) withBytes:&intValue2];
//        
//        Byte *bytes = (Byte *)[mData bytes];
//        
//        for (int i= 0; i<[mData length]; i++) {
//            NSLog(@"%hhu", bytes[i]);
//        }
//        
//        NSFileManager *fm = [NSFileManager defaultManager];
//        [fm createFileAtPath:@"/Users/dino/Desktop/test.tmp" contents:mData attributes:nil];
//        
//        NSFileHandle *fh = [NSFileHandle fileHandleForUpdatingAtPath:@"/Users/dino/Desktop/test.tmp"];
//        
//        [fh seekToFileOffset:0];
//        
//        NSData *rData = [fh readDataOfLength:4];
//        
//        int rint1;
//        
//        [rData getBytes:&rint1 length:sizeof(rint1)];
//    
//        NSLog(@"%i", rint1);
//        
//        [fh seekToFileOffset:4];
//        
//        rData = [fh readDataOfLength:4];
//        
//        int rint2;
//        
//        [rData getBytes:&rint2 length:sizeof(rint2)];
//        
//        NSLog(@"%i", rint2);
        
        FileQueue *queue = [[FileQueue alloc]initWithFileName:@"/Users/dino/Desktop/test.tmp"];
        
        NSString *stringForAdd = @"hello world";
        
        NSData *dataToAdd = [stringForAdd dataUsingEncoding:NSUTF8StringEncoding];
        
//        for (int i=0; i<5000; i++)
//        {
//            [queue add:dataToAdd];
//        }
        
        
//        for (int i=0; i<5000; i++)
//        {
//            [queue remove];
//        }
        
//        [queue remove];
        
//        [queue clear];
        
        NSLog(@"file length %i", queue.fileLength);
        NSLog(@"element count %i", queue.elementCount);
        NSLog(@"first element pos %i", queue.first.position);
        NSLog(@"last element pos %i", queue.last.position);
        
        NSData *readData = [queue peek];
        NSString *readString = [[NSString alloc]initWithData:readData encoding:NSUTF8StringEncoding];
        
        NSLog(@"read string %@", readString);
        
        [queue close];
        
        
    }
    return 0;
}
