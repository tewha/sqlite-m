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

@class SLDatabase;

/** @class SLStmt
 @brief Compiled SQLite statement.
 
 Objetive-C wrapper for sqlite3_stmt*. */
@interface SLStmt : NSObject {
	sqlite3 *_database;
	sqlite3_stmt *_stmt;
	int _err;
	int _bind;
	int _column;
	const char *_msg;
}

/** Pointer to sqlite3_stmt. */
@property (readonly) sqlite3_stmt* stmt;

/** Return result of last command. */
@property (readonly) int simpleErr;

/** Return result of last command. */
@property (readonly) int extendedErr;

/** Create a new, auto-released statement. */
+ (id)stmtWithDatabase:(SLDatabase*)database
				   sql:(NSString*)sql;

/** Create a statement. */
- (id)initWithDatabase:(SLDatabase*)database
				   sql:(NSString*)sql;

- (void)dealloc;

/** Compile a SQL query into a prepared statement. Rewinds to first bind point. */
- (void)prepare:(NSString*)sql;

/** Finalizes a query, closing it in sqlite library. */
- (void)close;

/** Step to next result row. Rewinds to first column. */
- (BOOL)step;

/** Get the number of columns in the result set. */
- (long long int)columnCount;

/** Get a specifc column's name. */
- (NSString*)columnNameByIndex:(int)column;

/** Get column name of the current column. */
- (NSString*)thisColumnName;

/** Get a specific column's contents as int64. */
- (long long int)intColumnByIndex:(int)column;

/** Get current column's contents as int64 and advance to next column. */
- (long long int)intColumn;

/** Get a specific column's contents as NSString. */
- (NSString*)stringColumnByIndex:(int)column;

/** Get current column's contents as NSString and advance to next column. */
- (NSString*)stringColumn;

/** Get a specific column's contents as NSString, NSNumber or NSBlob. */
- (id)columnByIndex:(int)column;

/** Get current column's contents as NSString, NSNumber or NSBlob and advance to next column. */
- (id)column;

- (NSDictionary*)allColumns;

/** Get a specific column's type. */
- (int)columnTypeByIndex:(int)column;

/** Get current column's type. Does not advance to next column. */
- (int)columnType;

/** Bind int64 to a compiled statement.
 @note index is 0-based */
- (void)bindIntByIndex:(int)bind
				 value:(long long int)value;

/** Bind int64 to a compiled statement and advance to next bind point. */
- (void)bindInt:(long long int)value;

/** Bind string to a compiled statement.
 @note index is 0-based */
- (void)bindStringByIndex:(int)bind
					value:(NSString*)value;

/** Bind string to a compiled statement and advance to next bind point. */
- (void)bindString:(NSString*)value;

@end
