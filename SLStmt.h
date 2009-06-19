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
	SLDatabase *_database;
	sqlite3_stmt *_stmt;
	int _err;
	int _bind;
	int _column;
	NSString *_sql;
	const char *_msg;
	const char *_nextSql;
}

/** Pointer to sqlite3_stmt. */
@property (readonly) sqlite3_stmt *stmt;

/** Return result of last command. */
@property (readonly) int simpleErr;

/** Return result of last command. */
@property (readonly) int extendedErr;

/** Create a new, auto-released statement. */
+ (id)stmtWithDatabase:(SLDatabase*)database
			   withSql:(NSString*)sql;

/** Create a statement. */
- (id)initWithDatabase:(SLDatabase*)database
			   withSql:(NSString*)sql;

- (void)dealloc;

/** Compile a SQL query into a prepared statement. Rewinds to first bind point. */
- (SLStmt*)prepare:(NSString*)sql;

/** Compile next SQL query. Rewinds to first bind point. */
- (SLStmt*)prepareNext;

/** Reset current statement.
 sa sqlite3_reset */
- (SLStmt*)reset;

/** Finalizes a query, closing it in sqlite library. */
- (SLStmt*)close;

/** Step to next result row. Rewinds to first column. */
- (SLStmt*)step;

/** Get the number of columns in the result set. */
- (long long)columnCount;

/** Get a specifc column's name. */
- (NSString*)columnName:(int)column;

/** Get column name of the current column. */
- (NSString*)columnName;

/** Get a specific column's contents as int64. */
- (long long)longLongValue:(int)column;

/** Get current column's contents as int64 and advance to next column. */
- (long long)longLongValue;

/** Get a specific column's contents as NSString. */
- (NSString*)stringValue:(int)column;

/** Get current column's contents as NSString and advance to next column. */
- (NSString*)stringValue;

/** Get a specific column's contents as NSString, NSNumber or NSBlob. */
- (id)value:(int)column;

/** Get current column's contents as NSString, NSNumber or NSBlob and advance to next column. */
- (id)value;

/** Get all column contents, returning name-value pairing. */
- (NSDictionary*)allValues;

/** Get a specific column's type. */
- (int)columnType:(int)column;

/** Get current column's type. Does not advance to next column. */
- (int)columnType;

/** Bind int64 to a compiled statement.
 @note index is 0-based */
- (SLStmt*)bindLongLong:(long long)value
			   forIndex:(int)index;

/** Bind int64 to a compiled statement and advance to next bind point. */
- (SLStmt*)bindLongLong:(long long)value;

/** Bind string to a compiled statement.
 @note index is 0-based */
- (SLStmt*)bindString:(NSString*)value
			 forIndex:(int)index;

/** Bind string to a compiled statement and advance to next bind point. */
- (SLStmt*)bindString:(NSString*)value;

@end
