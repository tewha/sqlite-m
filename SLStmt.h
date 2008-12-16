//
//  SLStmt.h
//
//  Copyright 2008 Steven Fisher.
//
//  This file is covered by the MIT/X11 License.
//  See LICENSE.TXT for more information.
//

#import <CoreFoundation/CoreFoundation.h>
#import <sqlite3.h>

@class NSString;
@class SLDatabase;

/** @class SLStmt
	@brief Compiled SQLite statement.

	Objetive-C wrapper for sqlite3_stmt*. */
@interface SLStmt : NSObject {
	SLDatabase *database_;
	sqlite3_stmt *stmt_;
	int err_;
	const char * msg_;
}

/** Pointer to sqlite3_stmt. */
@property (readonly) sqlite3_stmt* stmt;

/** Return result of last command. */
@property (readonly) int err;

/** Create a new, auto-released statement. */
+ (id)stmtWithDatabase:(SLDatabase*)database sql:(NSString*)sql;

/** Create a statement. */
- (id)initWithDatabase:(SLDatabase*)database sql:(NSString*)sql;

- (void)dealloc;

- (void)close;

/** Step to next result row. */
- (BOOL)step;

/** Get result column as int64. */
- (long long int)columnCount;

/** Get column name. */
- (NSString*)columnName:(int)column;

/** Get result column as int64. */
- (long long int)int64Column:(int)column;

/** Get result column as NSString. */
- (NSString*)textColumn:(int)column;

/** Get result column as NSString, NSNumber or NSBlob. */
- (id)column:(int)column;

- (NSDictionary*)allColumns;

/** Get column type. */
- (int)columnType:(int)column;

/** Bind int64 to a compiled statement.
    @note index is 0-based */
- (void)bindInt64:(int)bind value:(long long int)value;

@end
