//
//  main.m
//  MkvParseObjectiveC
//
//  Created by Grigory Zubankov on 02.03.12.
//  Copyright (c) 2012 ss.greg@me.com. All rights reserved.
//

#include <iostream>
#include <vector>
#include "MatroskaFile.h"
#include "MatroskaParser.h"

// GCD
#include <dispatch/queue.h>

#import <Foundation/Foundation.h>
#import <Foundation/NSThread.h>

@interface MyThreadHolder : NSObject
{
  NSThread* Thread;
  NSLock *theLock;
}
//@property NSThread* Thread;
- (void)Run;
@end


@implementation MyThreadHolder
//@synthesize Thread;

- (void)Run
{
//  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(myFun) name:NSThreadWillExitNotification object:nil];
  
  theLock = [[NSLock alloc] init];
  Thread = [[NSThread alloc] initWithTarget:self selector:@selector(Routine) object:nil];

  [theLock lock];
  [Thread start];
  [theLock lock];
  [theLock unlock];
}


- (void)myFun
{
  StdIoStream* stream = new StdIoStream;
  MatroskaFile* mf = openMatroskaFile("/Volumes/Multimedia/Downloads/Grimm.S01E12.720p.rus.LostFilm.TV.mkv", stream);
  TrackInfo* trackInfo = mkv_GetTrackInfo(mf, 0);
  
  NSLog(@"Hello, World! %d", mkv_GetNumTracks(mf));
}

- (void)Routine
{
  @autoreleasepool
  {
//    [self performSelectorOnMainThread:@selector(myFun) withObject:nil waitUntilDone:YES];  
//    [self performSelector:@selector(myFun) onThread:Thread withObject:nil waitUntilDone:YES];
    [self myFun];
    [theLock unlock];
  }
}

@end



//
// TransitionManager
//

@interface TransitionDataManager : NSObject
{
  NSData* Data;
  NSConditionLock* LockedWithoutDataLock;
  NSConditionLock* LockedWithDataLock;
}
- (id) init;
- (void) SetTransitionData: (NSData*) data;
- (NSData*) GetTransitionData;
@end


//
// TransitionManager
//

#define T_NODATA 1
#define T_DATA 2

@implementation TransitionDataManager

- (id) init
{
  if (self = [super init])
  {
    // LockedWithoutDataLock lock by default
//    LockedWithoutDataLock = [[NSLock alloc] init];
    // LockedWithDataLock unlocked by default 
    LockedWithDataLock = [[NSConditionLock alloc] initWithCondition:T_NODATA];
  }
  return self;
}

- (void) SetTransitionData: (NSData*) data
{
  [LockedWithDataLock lockWhenCondition: T_NODATA];
  Data = data;
  [LockedWithDataLock unlockWithCondition: T_DATA];
}

- (NSData*) GetTransitionData
{
  [LockedWithDataLock lockWhenCondition: T_DATA];
  NSData* oldData = Data;
  Data = nil;
  [LockedWithDataLock unlockWithCondition: T_NODATA];
  return oldData;
}

@end


void Reader(TransitionDataManager* dataManager, NSString* sourceFile, unsigned int requestedTrack)
{  
  char* mystring = (char*)[[sourceFile dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] bytes];
  
  StdIoStream* stream = new StdIoStream;
  MatroskaFile* mf = openMatroskaFile(mystring, stream);
  TrackInfo* trackInfo = mkv_GetTrackInfo(mf, 0);
  
  NSLog(@"Hello, World! %d", mkv_GetNumTracks(mf));
  
  mkv_SetTrackMask(mf, ~(1 << requestedTrack));
  
  uint64_t StartTime = 0;
  uint64_t EndTime = 0;
  uint64_t FilePos = 0;
  
  uint32_t Track = 0;
  uint32_t FrameSize = 0;
  uint32_t FrameFlags = 0;
  
  
  for (; mkv_ReadFrame(mf, 0, &Track, &StartTime, &EndTime, &FilePos, &FrameSize, &FrameFlags) == 0; )
  {
    if (fseeko(stream->fp, FilePos, SEEK_SET))
    {
      return;				
    }

    void* buffer = malloc(FrameSize);
    size_t rd = fread(buffer, 1, FrameSize, stream->fp);
    [dataManager SetTransitionData: [NSData dataWithBytesNoCopy: buffer length: FrameSize]];
  }
  [dataManager SetTransitionData:nil];
  return;
}

void Writer(TransitionDataManager* dataManager, NSString* targetFile)
{
  [[NSFileManager defaultManager] createFileAtPath:targetFile contents:nil attributes:nil];
  NSFileHandle* trackFile = [NSFileHandle fileHandleForWritingAtPath:targetFile];
  
  [trackFile truncateFileAtOffset:0];
  
  for (NSData* data; data = [dataManager GetTransitionData], data;)
  {
    [trackFile writeData:data];
  } 
}



int main(int argc, const char * argv[])
{
  @autoreleasepool
  {
    NSString* sourceFile = @"/Volumes/Multimedia/Downloads/Grimm.S01E12.720p.rus.LostFilm.TV.mkv";
    NSString* targetFile = @"/Volumes/Multimedia/Downloads/Grimm.track.1";
    unsigned int requestedTrack = 1;

    TransitionDataManager* dataManager = [[TransitionDataManager alloc] init];

    dispatch_group_t myGroup = dispatch_group_create();
    dispatch_group_async(myGroup, dispatch_get_global_queue(0, 0), ^{ Reader(dataManager, sourceFile, requestedTrack); });
    dispatch_group_async(myGroup, dispatch_get_global_queue(0, 0), ^{ Writer(dataManager, targetFile); });
    
    
    dispatch_group_wait(myGroup, DISPATCH_TIME_FOREVER);
    dispatch_release(myGroup);
    
//    MyThreadHolder* threadHolder = [MyThreadHolder alloc];
//    [threadHolder Run];
  }
  return 0;
}

