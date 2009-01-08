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

@synthesize extendedErr=_err, stmt=_stmt;

- (int)simpleErr {
	return _err & 0xFF;
}

- (void)setResult:(int)err {
	_err = err;
	_msg = sqlite3_errmsg(_database);
	if ( ( _err != SQLITE_OK ) && ( self.simpleErr < 100 ) )
		NSLog( @"SLStmt: (%d) %s", _err, _msg );
}

+ (id)stmtWithDatabase:(SLDatabase*)database
				   sql:(NSString*)sql {
    return [[[SLStmt alloc] initWithDatabase:database sql:sql] autorelease];
}

- (id)initWithDatabase:(SLDatabase*)database
				   sql:(NSString*)sql {
	self = [super init];
	if (!self) return self;
	_database = [database dtbs];
	[self prepare:sql];
	return self;
}

- (void)dealloc {
	if ( _stmt )
		sqlite3_finalize( _stmt );
	[super dealloc];
}

- (void)prepare:(NSString*)sql {
	if ( _stmt ) {
		[self close];
		_stmt = NULL;
	}
	[self setResult:sqlite3_prepare_v2(_database, [sql UTF8String], -1, &_stmt, 0)];
	_bind = 0;
}

- (void)close {
	if ( _stmt ) {
		sqlite3_finalize( _stmt );
		_stmt = NULL;
	}
}

- (sqlite3_stmt*)stmt {
	return _stmt;
}

- (BOOL)step {
	[self setResult:sqlite3_step( _stmt )];
	_column = 0;
	return ( [self simpleErr] == SQLITE_ROW ) ? YES : NO;
}

- (long long int)columnCount {
	return sqlite3_column_count( _stmt );
}

- (NSString*)columnNameByIndex:(int)column {
	const char * text = sqlite3_column_name( _stmt, column );
	if ( text == NULL )
		return NULL;
	return [NSString stringWithUTF8String:text];
}

- (NSString*)thisColumnName {
	const char * text = sqlite3_column_name( _stmt, _column );
	if ( text == NULL )
		return NULL;
	return [NSString stringWithUTF8String:text];
}

- (long long int)intColumnByIndex:(int)column {
	return sqlite3_column_int64( _stmt, column );
}

- (long long int)intColumn {
	return [self intColumnByIndex:_column++];
}

- (NSString*)stringColumnByIndex:(int)column {
	const char * text = (char*)sqlite3_column_text( _stmt, column);
	if ( text == NULL )
		return NULL;
	return [NSString stringWithUTF8String:text];
}

- (NSString*)stringColumn {
	const char * text = (char*)sqlite3_column_text( _stmt, _column++);
	if ( text == NULL )
		return NULL;
	return [NSString stringWithUTF8String:text];
}

- (int)columnTypeByIndex:(int)column {
	return sqlite3_column_type( _stmt, column );
}

- (int)columnType {
	return sqlite3_column_type( _stmt, _column );
}

- (id)columnByIndex:(int)column {
	int type = sqlite3_column_type( _stmt, column );
	switch (type) {
		case SQLITE_INTEGER:
			return [NSNumber numberWithLongLong:sqlite3_column_int64( _stmt, column )];
		case SQLITE_FLOAT:
			return [NSNumber numberWithDouble:sqlite3_column_double( _stmt, column )];
		case SQLITE_BLOB: {
			const void * bytes = sqlite3_column_blob( _stmt, column );
			return [NSData dataWithBytes:bytes length:sqlite3_column_bytes( _stmt, column )];
		}
		case SQLITE_NULL:
			return NULL;
		case SQLITE_TEXT: {
			const unsigned char * text = sqlite3_column_text( _stmt, column );
			return [NSString stringWithUTF8String:(char*)text];
		}
		default:
			return NULL;
	}
}

- (id)column {
	return [self columnByIndex:_column++];
}

- (NSDictionary*)allColumns {
	NSMutableDictionary * temp_values = [[NSMutableDictionary alloc] init];
	int n = [self columnCount];
	for ( int i = 0; i < n; i++ ) {
		id value = [self columnByIndex:i];
		if (!value)
			continue;
		NSString * name = [self columnNameByIndex:i];
		[temp_values setObject:value forKey:name];
	}
	NSDictionary * values = [[NSDictionary alloc] initWithDictionary:temp_values];
	[temp_values release];
	return [values autorelease];
}

- (void)bindIntByIndex:(int)bind
				 value:(long long int)value {
	[self setResult:sqlite3_bind_int64( _stmt, bind+1, value )];
}

- (void)bindInt:(long long int)value {
	[self bindIntByIndex:_bind++ value:value];
}

- (void)bindStringByIndex:(int)bind
					value:(NSString*)value {
	[self setResult:sqlite3_bind_text( _stmt, bind+1, [value UTF8String], -1, SQLITE_TRANSIENT )];
}

- (void)bindString:(NSString*)value {
	[self bindStringByIndex:_bind++ value:value];
}

@end
