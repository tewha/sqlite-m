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
	SLDatabase *database;
	sqlite3_stmt *stmt;
	int bind, column, errorCode;
	NSString *fullSQL, *currentSQL;
	const char *thisSQL, *nextSQL;
}

/** Pointer to sqlite3_stmt. */
@property (readonly) sqlite3_stmt *stmt;

/** Currently executing SQL. */
@property (readonly) NSString *currentSQL;

/** Create a new, auto-released statement. */
+ (id)stmtWithDatabase: (SLDatabase *)inDatabase;

/** Create a statement. */
- (id)initWithDatabase: (SLDatabase *)inDatabase;

- (void)dealloc;

/** Compile a SQL query into a prepared statement. Rewinds to first bind point. */
- (BOOL)prepareSQL: (NSString *)inSQL
			 error: (NSError **)outError;

/** Compile next SQL query. Rewinds to first bind point. */
- (BOOL)prepareNextWithError: (NSError **)outError;

/** Reset current statement. */
- (BOOL)resetWithError: (NSError **)outError;

/** Finalizes a query, closing it in sqlite library. */
- (BOOL)closeWithError: (NSError **)outError;

/** Step to next result row. Rewinds to first column. */
- (BOOL)stepWithError: (NSError **)outError;

/** Step, return YES if a row was found.
 
 @seealso stepOverRows */
- (BOOL)stepHasRowWithError: (NSError **)outError;

/** Step over all rows.
 Returns YES if done (regardless of whether a row was actually found), NO if an error occurs.
 
 @seealso stepHasRow */
- (BOOL)stepOverRowsWithError: (NSError **)outError;

/** Get a all column names. */
- (NSArray *)columnNames;

/** Get the number of columns in the result set. */
- (long long)columnCount;

/** Get a specifc column's name. */
- (NSString *)columnName: (int)inColumn;

/** Get column name of the current column. */
- (NSString *)columnName;

/** Get a specific column's contents as int64. */
- (long long)longLongValue: (int)inColumn;

/** Get current column's contents as int64 and advance to next column. */
- (long long)longLongValue;

/** Get a specific column's contents as NSString. */
- (NSString *)stringValue: (int)inColumn;

/** Get current column's contents as NSString and advance to next column. */
- (NSString *)stringValue;

/** Get a specific column's contents as NSString, NSNumber or NSBlob. */
- (id)value: (int)inColumn;

/** Get current column's contents as NSString, NSNumber or NSBlob and advance to next column. */
- (id)value;

/** Get all column contents, returning name-value pairing. */
- (NSDictionary *)allValues;

/** Get a specific column's type. */
- (int)columnType: (int)inColumn;

/** Get current column's type. Does not advance to next column. */
- (int)columnType;

/** Bind int64 to a compiled statement.
 @note index is 0-based */
- (BOOL)bindLongLong: (long long)value
			forIndex: (int)index
			   error: (NSError **)outError;

/** Bind int64 to a compiled statement and advance to next bind point. */
- (BOOL)bindLongLong: (long long)value
			   error: (NSError **)outError;

/** Bind string to a compiled statement.
 @note index is 0-based */
- (BOOL)bindString: (NSString *)value
		  forIndex: (int)index
			 error: (NSError **)outError;

/** Bind string to a compiled statement and advance to next bind point. */
- (BOOL)bindString: (NSString *)value
			 error: (NSError **)outError;

/** Bind blob to a compiled statement.
 @note index is 0-based */
- (BOOL)bindData: (NSData *)value
		forIndex: (int)index
		   error: (NSError **)outError;

/** Bind blob to a compiled statement and advance to next bind point. */
- (BOOL)bindData: (NSData *)value
		   error: (NSError **)outError;

/** Bind all key-values in a dictionary that match bind points.
 Returns keys of matched bound points. */
- (NSArray *)bindDictionary: (NSDictionary *)bindings;

/** Find bind point with name. */
- (int)findBinding: (NSString *)name;

@end
