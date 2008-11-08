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
	sqlite3 *dtbs_;
	int err_;
}
/** Pointer to sqlite3 database. */
@property (readonly) sqlite3* dtbs;

/** Result of last command. */
@property (readonly) int err;

/** Allocate a new, autoreleased SLDatabase. */
+ (id)databaseWithPath:(NSString*)inPath;

/** Initialize a new SLDatabase. */
- (id)initWithPath:(NSString*)inPath;

/** Prepare a SQL statement. */
- (SLStmt*)prepare:(NSString*)sql;

@end
