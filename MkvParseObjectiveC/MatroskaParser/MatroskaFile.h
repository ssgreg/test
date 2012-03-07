/*
 *  MatroskaFile.h
 *  Subler
 *
 *  Created by Ryan Walklin on 23/09/09.
 *  Copyright 2009 Test Toast. All rights reserved.
 *
 */

#include "MatroskaParser.h"

#ifdef __cplusplus
extern "C" {
#endif

/* first we need to create an I/O object that the parser will use to read the 
 * source file 
 */ 
struct StdIoStream { 
	struct InputStream  base; 
	FILE                      *fp; 
	int                      error; 
}; 
typedef struct StdIoStream StdIoStream; 

MatroskaFile* openMatroskaFile(const char *filePath, StdIoStream *ioStream);

#ifdef __cplusplus
}
#endif