//
//  FileQueue.h
//  FileQueue
//
//

/**
* Format:
* Header (16 bytes)
* Element Ring Buffer (File Length - 16 bytes)
*
* Header:
* File Length (4 bytes)
* Element Count (4 bytes)
* First Element Position (4 bytes, =0 if null)
* Last Element Position (4 bytes, =0 if null)
*
* Element:
* Length (4 bytes)
* Data (Length bytes)
*/

#import <Foundation/Foundation.h>

/** Initial file size in bytes. one file system block */
#define INITIAL_LENGTH 4096

/** Length of header in bytes. */
#define HEADER_LENGTH 16

/** Length of element header in bytes. */
#define ELEMENT_HEADER_LENGTH 4


typedef struct
{
    int position;
    
    int length;
    
}QueueElement;


@interface FileQueue : NSObject

@property(nonatomic, retain)NSFileHandle *fh;

@property(nonatomic, assign)int fileLength;

@property(nonatomic, assign)int elementCount;

/** Pointer to first (or eldest) element. */
@property(nonatomic, assign)QueueElement first;

/** Pointer to last (or newest) element. */
@property(nonatomic, assign)QueueElement last;

/** In-memory buffer. Big enough to hold the header. */
@property(nonatomic, retain)NSMutableData *headBuffer;

-(id)initWithFileName:(NSString *) fileName;

-(void)add:(NSData *)data;

-(BOOL)isEmpty;

-(NSData *)peek;

-(int)size;

-(void)remove;

-(void)clear;

-(void)close;

@end

