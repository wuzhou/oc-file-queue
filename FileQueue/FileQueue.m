//
//  FileQueue.m
//  FileQueue
//
//

#import "FileQueue.h"

@implementation FileQueue

-(id)initWithFileName:(NSString *) fileName
{
    if(self = [super init])
    {
        NSFileManager *fm = [NSFileManager defaultManager];
        
        if(![fm fileExistsAtPath:fileName])
        {
            [self initializeQueueFile:fileName];
        }
        else
        {
            self.fh = [NSFileHandle fileHandleForUpdatingAtPath:fileName];
        }
        
        
        [self readFileHeader];
    }
    
    return self;
}

-(void)initializeQueueFile:(NSString *) fileName
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    [fm createFileAtPath:fileName contents:nil attributes:nil];
    
    self.fh = [NSFileHandle fileHandleForUpdatingAtPath:fileName];
    
    [self.fh truncateFileAtOffset:INITIAL_LENGTH];
    
    [self.fh seekToFileOffset:0];
    
    self.headBuffer = [NSMutableData dataWithLength:HEADER_LENGTH];

    NSNumber *length = [NSNumber numberWithInt:INITIAL_LENGTH];
    NSNumber *count     = [NSNumber numberWithInt:0];
    NSNumber *firstPos  = [NSNumber numberWithInt:0];
    NSNumber *lastPos   = [NSNumber numberWithInt:0];
    
    NSArray *initHeaderValues = [NSArray arrayWithObjects:length, count, firstPos, lastPos, nil];
    
    [self writeIntsToBuffer:self.headBuffer Ints:initHeaderValues];
    
    [self.fh seekToFileOffset:0];
    
    [self.fh writeData:self.headBuffer];
    
    [self.fh synchronizeFile];
}

-(void)readFileHeader
{
    [self.fh seekToFileOffset:0];
    
    NSData *data = [self.fh readDataOfLength:HEADER_LENGTH];
    
    self.headBuffer = [NSMutableData dataWithData:data];
    
    self.fileLength = [self readInt:self.headBuffer Offset:0];
    
    self.elementCount = [self readInt:self.headBuffer Offset:4];
    
    int firstPos = [self readInt:self.headBuffer Offset:8];
    self.first = [self readElement:firstPos];
    
    int lastPos  = [self readInt:self.headBuffer Offset:12];
    self.last = [self readElement:lastPos];
}

-(int)readInt:(NSData *) buffer Offset:(int) offset
{
    int result = 0;
    
    [buffer getBytes:&result range:NSMakeRange(offset, sizeof(result))];
    
    return result;
}

-(QueueElement)readElement:(int)pos
{
    QueueElement element;
    
    if(pos == 0)
    {
        element.position = 0;
        element.length = 0;
        
        return element;
    }
    
    element.position = pos;
    
    [self.fh seekToFileOffset:pos];
    
    NSData *data = [self.fh readDataOfLength:ELEMENT_HEADER_LENGTH];
    
    element.length =  [self readInt:data Offset:0];
    
    return element;
}

-(void)writeIntToBuffer:(NSMutableData *)buffer Offset:(int)offset Value:(int)intValue
{
    [buffer replaceBytesInRange:NSMakeRange(offset, sizeof(intValue)) withBytes:&intValue];
}

-(void)writeIntsToBuffer:(NSMutableData *)buffer Ints:(NSArray *) ints
{
    int offset = 0;
    for (int i = 0; i<[ints count]; i++)
    {
        [self writeIntToBuffer:self.headBuffer Offset:offset Value:(int)[ints[i] integerValue]];
        offset += 4;
    }
}

-(void)writeFileHeader:(int)fileLength ElementCount:(int)eCount FirstPos:(int)fPos LastPos:(int)lPos
{
    NSNumber *length    = [NSNumber numberWithInt:fileLength];
    NSNumber *count     = [NSNumber numberWithInt:eCount];
    NSNumber *firstPos  = [NSNumber numberWithInt:fPos];
    NSNumber *lastPos   = [NSNumber numberWithInt:lPos];
    
    NSArray *headerValues = [NSArray arrayWithObjects:length, count, firstPos, lastPos, nil];
    
    [self writeIntsToBuffer:self.headBuffer Ints:headerValues];
    
    [self.fh seekToFileOffset:0];
    
    [self.fh writeData:self.headBuffer];
    
    [self.fh synchronizeFile];
}

-(int)wrapPosition:(int)pos
{
    if (pos < self.fileLength)
    {
        return pos;
    }
    else
    {
        return HEADER_LENGTH + (pos - self.fileLength);
    }
}

-(void)ringWrite:(int)startPos DataToWrite:(NSData *)data
{
    startPos = [self wrapPosition:startPos];
    
    if (startPos + [data length] <= self.fileLength)
    {
        [self.fh seekToFileOffset:startPos];
        [self.fh writeData:data];
        [self.fh synchronizeFile];
    }
    else
    {
        int countBeforeEOF = self.fileLength - startPos;
        NSData *beforeDataToWrite
                = [data subdataWithRange:NSMakeRange(0, countBeforeEOF)];
        
        [self.fh seekToFileOffset:startPos];
        [self.fh writeData:beforeDataToWrite];
        
        int countAfterEOF   = (int)([data length] - countBeforeEOF);
        NSData *afterDataToWrite
                = [data subdataWithRange:NSMakeRange(countBeforeEOF, countAfterEOF)];
        
        [self.fh seekToFileOffset:HEADER_LENGTH];
        [self.fh writeData:afterDataToWrite];
        
        [self.fh synchronizeFile];
    }
}

-(NSData *)ringRead:(int)startPos DataLength:(int)dLength
{
    startPos = [self wrapPosition:startPos];
    
    if (startPos + dLength <= self.fileLength)
    {
        [self.fh seekToFileOffset:startPos];
        NSData *data = [self.fh readDataOfLength:dLength];
        
        return data;
    }
    else
    {
        int countBeforeEOF = self.fileLength - startPos;
        [self.fh seekToFileOffset:startPos];
        
        NSData *beforeDataRead = [self.fh readDataOfLength:countBeforeEOF];
        
        NSMutableData *readData = [NSMutableData dataWithData:beforeDataRead];
        
        int countAfterEOF = dLength - countBeforeEOF;
        [self.fh seekToFileOffset:HEADER_LENGTH];
        
        NSData *afterDataRead = [self.fh readDataOfLength:countAfterEOF];
        
        [readData appendData:afterDataRead];
        
        return readData;
    }
}

-(void)add:(NSData *)data
{
    if (data == nil)
    {
        NSLog(@"add data is nil !");
    }
    else
    {
        [self expandFileLengthIfNecessary:(int)[data length]];

        BOOL isEmpty = [self isEmpty];

        int pos = isEmpty ? HEADER_LENGTH :
                [self wrapPosition:(self.last.position + ELEMENT_HEADER_LENGTH + self.last.length)];

        QueueElement newLastElement;
        newLastElement.position = pos;
        newLastElement.length = (int)[data length];

        self.last = newLastElement;

        NSData *lData = [NSData dataWithBytes:&newLastElement.length length:sizeof(&newLastElement.length)];

        //write element header
        [self ringWrite:newLastElement.position DataToWrite:lData];

        //write data
        [self ringWrite:newLastElement.position + ELEMENT_HEADER_LENGTH DataToWrite:data];

        if(isEmpty)
        {
            self.first = newLastElement;
        }

        self.elementCount += 1;

        [self writeFileHeader:self.fileLength ElementCount:self.elementCount
                     FirstPos:self.first.position LastPos:self.last.position];

    }
}

-(void)expandFileLengthIfNecessary:(int)dataLength
{
    int lengthToWrite = ELEMENT_HEADER_LENGTH + dataLength;
    
    int remainLength = [self getRemainLengthInFile];
    
    if (remainLength >= lengthToWrite)
    {
        return;
    }
    else
    {
        NSLog(@"Expand!");
        int previousLength = self.fileLength;
        int newLength;
        do
        {
            remainLength += previousLength;
            newLength = previousLength << 1;
            previousLength = newLength;
        } while (remainLength < lengthToWrite);
        
        
        [self.fh truncateFileAtOffset:newLength];
        
        [self.fh seekToFileOffset:0];

        
        // If the buffer is split, we need to make it contiguous.
        if(self.last.position < self.first.position)
        {
            [self.fh seekToFileOffset:0];
            NSData *fileData = [self.fh readDataToEndOfFile];
            
            NSMutableData *newFileData = [NSMutableData dataWithData:fileData];
            
            int moveLength = (self.last.position + ELEMENT_HEADER_LENGTH + self.last.length) - HEADER_LENGTH;
            
            NSData *dataToMove = [newFileData subdataWithRange:NSMakeRange(HEADER_LENGTH, moveLength)];
            
            [newFileData replaceBytesInRange:NSMakeRange(self.fileLength, moveLength) withBytes:[dataToMove bytes]];
            
            [self.fh writeData:newFileData];
            
            int newLastElementPos = self.fileLength + self.last.position - HEADER_LENGTH;

            QueueElement newLastElement;
            newLastElement.position = newLastElementPos;
            newLastElement.length = self.last.length;

            self.last = newLastElement;
        }
        
        self.fileLength = newLength;
        
        [self writeFileHeader:self.fileLength ElementCount:self.elementCount
                     FirstPos:self.first.position LastPos:self.last.position];
    }
    
}

-(int)getRemainLengthInFile
{
    return self.fileLength - [self getUsedLengthInFile];
}

-(int)getUsedLengthInFile
{
    if (self.elementCount == 0)
    {
        return HEADER_LENGTH;
    }
    else if(self.first.position < self.last.position)
    {
        //contigous queue
        return (self.last.position - self.first.position)
               + (ELEMENT_HEADER_LENGTH + self.last.length)
               + HEADER_LENGTH;
    }
    else
    {
        //wraped queue
        return (self.last.position + ELEMENT_HEADER_LENGTH + self.last.length)
                + (self.fileLength - self.first.length);
    }
}

-(BOOL)isEmpty
{
    return self.elementCount == 0;
}

-(NSData *)peek
{
    if([self isEmpty])
    {
        return nil;
    }
    else
    {
        return [self ringRead:self.first.position + ELEMENT_HEADER_LENGTH
                   DataLength:self.first.length];
    }
}

-(int)size
{
    return  self.elementCount;
}

-(void)remove
{
    if([self isEmpty])
    {
        NSLog(@"queue is empty!");
        return;
    }
    else if(self.elementCount == 1)
    {
        [self clear];
    }
    else
    {
        QueueElement newFirstElement;
        
        newFirstElement.position
        = [self wrapPosition:self.first.position + ELEMENT_HEADER_LENGTH + self.first.length];
        
        [self.fh seekToFileOffset:newFirstElement.position];
        NSData *nextElementLengthData = [self.fh readDataOfLength:ELEMENT_HEADER_LENGTH];
        
        int nextElementLength = [self readInt:nextElementLengthData Offset:0];
        
        newFirstElement.length = nextElementLength;
        
        self.first = newFirstElement;
        
        self.elementCount -= 1;
        
        [self writeFileHeader:self.fileLength ElementCount:self.elementCount FirstPos:self.first.position LastPos:self.last.position];
    }
}

-(void)clear
{
    if(self.fileLength > INITIAL_LENGTH)
    {
        [self.fh truncateFileAtOffset:INITIAL_LENGTH];
    }
    
    [self writeFileHeader:INITIAL_LENGTH ElementCount:0 FirstPos:0 LastPos:0];
    
    [self.fh synchronizeFile];

    [self readFileHeader];
}

-(void)close
{
    [self.fh closeFile];
}

@end
