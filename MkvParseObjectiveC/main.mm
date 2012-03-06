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

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[])
{
  @autoreleasepool {
    StdIoStream* stream = new StdIoStream;
    MatroskaFile* mf = openMatroskaFile("/Volumes/Multimedia/Downloads/Grimm.S01E12.720p.rus.LostFilm.TV.mkv", stream);
    TrackInfo* trackInfo = mkv_GetTrackInfo(mf, 0);
     
    std::vector<int> d;
      // insert code here...
      NSLog(@"Hello, World! %d", mkv_GetNumTracks(mf));
      
  }
    return 0;
}

