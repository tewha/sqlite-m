//
//  SLStmt.m
//
//  Copyright 2008 Steven Fisher.
//
//  This file is covered by the MIT/X11 License.
//  See LICENSE.TXT for more information.
//

#import "SLStmt.h"
#import "SLDatabase.h"



@implementation SLStmt



@synthesize stmt, currentSQL;



- (BOOL)setResult: (int)err
			error: (NSError **)outError;
{
	errorCode = (err & 0xFF);
	NSError *theError = nil;
	if ( ( errorCode != SQLITE_OK ) && ( errorCode < 100 ) ) {
		const char *msg = sqlite3_errmsg([database dtbs]);
		theError = [NSError errorWithDomain: @"sqlite"
									   code: errorCode
								   userInfo: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithLongLong: err], @"Code",
											  [NSString stringWithUTF8String: msg], @"Message", nil]];
	}
	if (outError) {
		*outError = theError;
	}
	return (theError == nil);
}



+ (id)stmtWithDatabase: (SLDatabase *)inDatabase;
{
	return [[[self alloc] initWithDatabase: inDatabase] autorelease];
}



- (id)initWithDatabase: (SLDatabase *)inDatabase;
{
	self = [super init];
	if (!self) return self;
	database = [inDatabase retain];
	return self;
}



- (void)dealloc;
{
	if (stmt) {
		NSError *error;
		[self closeWithError: &error];
	}
	[fullSQL release];
	[currentSQL release];
	currentSQL = nil;
	[database release];
	[super dealloc];
}



- (void)updateCurrentSQL;
{
	intptr_t length = (intptr_t)nextSQL - (intptr_t)thisSQL;
	NSMutableData *data = [NSMutableData dataWithCapacity: length+1];
	[data appendBytes: thisSQL length: length];
	
	const int zero = 0;
	[data appendBytes: &zero length: sizeof(zero)];
	
	[currentSQL release];
	currentSQL = [[NSString stringWithUTF8String: [data bytes]] retain];
}



- (BOOL)prepareSQL: (NSString *)inSQL
			 error: (NSError **)outError;
{
	[inSQL retain];
	NSError *error;
	[self closeWithError: &error];
	[fullSQL release];
	fullSQL = inSQL;
	thisSQL = [fullSQL UTF8String];
	[self setResult: sqlite3_prepare_v2([database dtbs], thisSQL, -1, &stmt, &nextSQL)
			  error: outError];
	[self updateCurrentSQL];
	bind = 0;
	return (errorCode == SQLITE_OK) && (stmt != NULL);
}


- (BOOL)prepareNextWithError: (NSError **)outError;
{
	
	// finalize previous statement, if any
	if ( stmt ) {
		if ( ![self setResult: sqlite3_finalize( stmt )
						error: outError] ) {
			return FALSE;
		}
		stmt = NULL;
	}
	
	// return immediately if there's no more SQL to process
	if ( ( nextSQL == NULL ) || ( *nextSQL == 0 ) )
		return NO;
	
	// otherwise, prepare the next chunk of SQL and update the currentSQL property
	thisSQL = nextSQL;
	[self setResult: sqlite3_prepare_v2([database dtbs], nextSQL, -1, &stmt, &nextSQL)
			  error: outError];
	[self updateCurrentSQL];
	
	// success, if no error
	return (errorCode == SQLITE_OK) && (stmt != NULL);
}


- (BOOL)resetWithError: (NSError **)outError;
{
	if ( !stmt ) {
		return NO;
	}
	bind = 0;
	column = 0;
	[self setResult: sqlite3_reset( stmt )
			  error: outError];
	return (errorCode == SQLITE_OK);
}



- (BOOL)closeWithError: (NSError **)outError;
{
	BOOL ok = YES;
	if ( stmt ) {
		[self setResult: sqlite3_finalize( stmt )
				  error: outError];
		stmt = NULL;
		[currentSQL release];
		currentSQL = nil;
	}
	return ok;
}



- (sqlite3_stmt *)stmt;
{
	return stmt;
}



- (BOOL)stepWithError: (NSError **)outError;
{
	column = 0;
	[self setResult: sqlite3_step( stmt )
			  error: outError];
	return ( ( errorCode == SQLITE_ROW ) | (errorCode == SQLITE_DONE ) );
}



- (BOOL)stepHasRowWithError: (NSError **)outError;
{
	column = 0;
	[self setResult: sqlite3_step( stmt )
			  error: outError];
	return ( errorCode == SQLITE_ROW );
}



- (BOOL)stepOverRowsWithError: (NSError **)outError;
{
	column = 0;
	do {
		[self setResult: sqlite3_step( stmt )
				  error: outError];
	} while ( errorCode == SQLITE_ROW);
	return ( errorCode == SQLITE_DONE );
}



- (NSArray *)columnNames;
{
	int columnCount = sqlite3_column_count( stmt );
	id columns = [NSMutableArray arrayWithCapacity: columnCount];
	for (int i = 0; i < columnCount; i++ ) {
		const char *name = sqlite3_column_name( stmt, i);
		[columns addObject: [NSString stringWithUTF8String: name]];
	}
	return [NSArray arrayWithArray: columns];
}



- (int)columnCount;
{
	return sqlite3_column_count( stmt );
}



- (NSString *)columnName: (int)inColumn;
{
	const char *text = sqlite3_column_name( stmt, inColumn );
	if ( text == NULL )
		return nil;
	return [NSString stringWithUTF8String: text];
}



- (NSString *)columnName;
{
	const char *text = sqlite3_column_name( stmt, column );
	if ( text == NULL )
		return nil;
	return [NSString stringWithUTF8String: text];
}



- (int)intValue: (int)inColumn;
{
	return sqlite3_column_int( stmt, inColumn );
}



- (int)intValue;
{
	return [self intValue: column++];
}



- (long long)longLongValue: (int)inColumn;
{
	return sqlite3_column_int64( stmt, inColumn );
}



- (long long)longLongValue;
{
	return [self longLongValue: column++];
}



- (NSString *)stringValue: (int)inColumn;
{
	const char *text = (char *)sqlite3_column_text( stmt, inColumn);
	if ( text == NULL )
		return nil;
	return [NSString stringWithUTF8String: text];
}



- (NSString *)stringValue;
{
	const char *text = (char *)sqlite3_column_text( stmt, column++);
	if ( text == NULL )
		return nil;
	return [NSString stringWithUTF8String: text];
}



- (int)columnType: (int)inColumn;
{
	return sqlite3_column_type( stmt, inColumn );
}



- (int)columnType;
{
	return sqlite3_column_type( stmt, column );
}



- (id)value: (int)inColumn;
{
	int type = sqlite3_column_type( stmt, inColumn );
	switch (type) {
		case SQLITE_INTEGER:
			return [NSNumber numberWithLongLong: sqlite3_column_int64( stmt, inColumn )];
		case SQLITE_FLOAT:
			return [NSNumber numberWithDouble: sqlite3_column_double( stmt, inColumn )];
		case SQLITE_BLOB: {
			const void *bytes = sqlite3_column_blob( stmt, inColumn );
			return [NSData dataWithBytes: bytes
								  length: sqlite3_column_bytes( stmt, inColumn )];
		}
		case SQLITE_NULL:
			return nil;
		case SQLITE_TEXT:
			return [NSString stringWithUTF8String: (char *)sqlite3_column_text( stmt, inColumn ) ];
		default:
			return nil;
	}
}



- (id)value;
{
	return [self value: column++];
}



- (NSDictionary *)allValues;
{
	NSMutableDictionary *temp_values = [[NSMutableDictionary alloc] init];
	int n = [self columnCount];
	for ( int i = 0; i < n; i++ ) {
		id value = [self value: i];
		if (!value)
			continue;
		NSString *name = [self columnName: i];
		[temp_values setObject: value
						forKey: name];
	}
	NSDictionary *values = [NSDictionary dictionaryWithDictionary: temp_values];
	[temp_values release];
	return values;
}



- (NSArray *)bindNames;
{
	NSInteger theCount = sqlite3_bind_parameter_count( stmt );
	NSMutableArray *theBinds = [NSMutableArray arrayWithCapacity: theCount];
	for ( NSInteger i = 1; i<=theCount; i++ ) {
		[theBinds addObject: [NSString stringWithUTF8String: sqlite3_bind_parameter_name( stmt, i )]];
	}
	return [NSArray arrayWithArray: theBinds];
}



- (BOOL)bindLongLong: (long long)value
			forIndex: (int)inIndex
			   error: (NSError **)outError;
{
	[self setResult: sqlite3_bind_int64( stmt, inIndex+1, value )
			  error: outError];
	return ( errorCode == SQLITE_OK );
}



- (BOOL)bindLongLong: (long long)value
			   error: (NSError **)outError;
{
	return [self bindLongLong: value
					 forIndex: bind++
						error: outError];
}



- (BOOL)bindNullForIndex: (int)inIndex
				   error: (NSError **)outError;
{
	[self setResult: sqlite3_bind_null( stmt, inIndex+1 )
			  error: outError];
	return ( errorCode == SQLITE_OK );
}



- (BOOL)bindNullWithError: (NSError **)outError;
{
	return [self bindNullForIndex: bind++
							error: outError];
}



- (BOOL)bindData: (NSData *)value
		forIndex: (int)inIndex
		   error: (NSError **)outError;
{
	[self setResult: sqlite3_bind_blob( stmt, inIndex+1, [value bytes], [value length], SQLITE_TRANSIENT )
			  error: outError];
	return ( errorCode == SQLITE_OK );
	
}



- (BOOL)bindData: (NSData *)value
		   error: (NSError **)outError;
{
	return [self bindData: value
				 forIndex: bind++
					error: outError];
}



- (BOOL)bindValue: (id)value
		 forIndex: (int)inIndex
			error: (NSError **)outError;
{
	BOOL ok = NO;
	if ( [value isKindOfClass: [NSData class]] ) {
		ok = [self bindData: value
				   forIndex: inIndex
					  error: outError];
	} else if ( [value isKindOfClass: [NSNumber class]] ) {
		id str = [value description];
		[self setResult: sqlite3_bind_text( stmt, inIndex+1, [str UTF8String], -1, SQLITE_TRANSIENT )
				  error: outError];
		ok = ( errorCode == SQLITE_OK );
	} else if ( [value isKindOfClass: [NSString class]] ) {
		[self setResult: sqlite3_bind_text( stmt, inIndex+1, [value UTF8String], -1, SQLITE_TRANSIENT )
				  error: outError];
		ok = ( errorCode == SQLITE_OK );
	} else if ( value == [NSNull null] ) {
		ok = [self bindNullForIndex: inIndex
							  error: outError];
	} else {
		id theError = [NSError errorWithDomain: @"sqlite"
										  code: -1
									  userInfo: nil];
		if (outError) {
			*outError = theError;
		}
	}
	return ok;
}



- (BOOL)bindValue: (id)value
			error: (NSError **)outError;
{
	return [self bindValue: value
				  forIndex: bind++
					 error: outError];
}



- (NSSet *)bindDictionary: (NSDictionary *)bindings;
{
	if (bindings == nil)
		return nil;
	id accepted = [NSMutableSet setWithCapacity: bindings.count];
	NSArray *keys = [bindings allKeys];
	for (NSString *key in keys) {
		NSInteger bindIndex = [self findBinding: key];
		if ( bindIndex < 0 ) {
			continue;
		}
		id value = [bindings valueForKey: key];
		NSError *error = nil;
		[self bindValue: value
			   forIndex: bindIndex
				  error: &error];
		if (error == nil) {
			[accepted addObject: key];
		}
	}
	return [NSSet setWithSet: accepted];
}



- (int)findBinding: (NSString *)name;
{
	return sqlite3_bind_parameter_index( stmt, [name UTF8String]) - 1;
}



@end
