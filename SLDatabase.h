//
//  SLDatabase.h
//
//  Copyright 2008 Steven Fisher.
//
//  This file is covered by the MIT/X11 License.
//  See LICENSE.TXT for more information.
//

#import <CoreFoundation/CoreFoundation.h>
#import <sqlite3.h>

@class SLStmt;

/** @class SLDatabase
 @brief SQLite database.
 
 Objetive-C wrapper for sqlite3*. */
@interface SLDatabase : NSObject {
	sqlite3 *_dtbs;
	int _err;
	const char *_msg;
}
/** Pointer to sqlite3 database. */
@property (readonly) sqlite3 *dtbs;

/** Result of last command. */
@property (readonly) int extendedErr;

/** Result of last command. */
@property (readonly) int simpleErr;

/** Allocate a new, autoreleased SLDatabase. */
+ (id)databaseWithPath:(NSString*)inPath;

/** Initialize a new SLDatabase. */
- (id)initWithPath:(NSString*)inPath;

- (BOOL)exec:(NSString*)sql;

- (long long)lastInserted;

@end
