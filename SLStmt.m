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
	_msg = sqlite3_errmsg([_database dtbs]);
	if ( ( _err != SQLITE_OK ) && ( self.simpleErr < 100 ) )
		NSLog( @"SLStmt: (%d) %s", _err, _msg );
}

+ (id)stmtWithDatabase:(SLDatabase*)database
			   withSql:(NSString*)sql {
    return [[[SLStmt alloc] initWithDatabase:database withSql:sql] autorelease];
}

- (id)initWithDatabase:(SLDatabase*)database
			   withSql:(NSString*)sql {
	self = [super init];
	if (!self) return self;
	_database = [database retain];
	[self prepare:sql];
	return self;
}

- (void)dealloc {
	if ( _stmt ) {
		int err = sqlite3_finalize( _stmt );
		if ( err != SQLITE_OK )
			NSLog( @"Error %d while finalizing query as part of dealloc.", err );
	}
	[_database release];
	[super dealloc];
}

- (void)prepare:(NSString*)sql {
	if ( _stmt ) {
		[self close];
		_stmt = NULL;
	}
	[self setResult:sqlite3_prepare_v2([_database dtbs], [sql UTF8String], -1, &_stmt, &_nextSql)];
	_bind = 0;
}

- (BOOL)prepareNext {
	if ( ( _nextSql == NULL ) || ( *_nextSql == 0 ) )
		return NO;
	[self setResult:sqlite3_prepare_v2([_database dtbs], _nextSql, -1, &_stmt, &_nextSql)];
	return YES;
}

- (void)reset {
	if ( _stmt ) {
		sqlite3_reset( _stmt );
	}
}


- (void)close {
	if ( _stmt ) {
		int err = sqlite3_finalize( _stmt );
		if ( err != SQLITE_OK )
			NSLog( @"Error %d while finalizing query as part of close.", err );
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

- (NSString*)columnName:(int)column {
	const char * text = sqlite3_column_name( _stmt, column );
	if ( text == NULL )
		return NULL;
	return [NSString stringWithUTF8String:text];
}

- (NSString*)columnName {
	const char * text = sqlite3_column_name( _stmt, _column );
	if ( text == NULL )
		return NULL;
	return [NSString stringWithUTF8String:text];
}

- (long long int)longLongIntColumn:(int)column {
	return sqlite3_column_int64( _stmt, column );
}

- (long long int)longLongIntColumn {
	return [self longLongIntColumn:_column++];
}

- (NSString*)stringColumn:(int)column {
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

- (int)columnType:(int)column {
	return sqlite3_column_type( _stmt, column );
}

- (int)columnType {
	return sqlite3_column_type( _stmt, _column );
}

- (id)column:(int)column {
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
			return nil;
		case SQLITE_TEXT: {
			const unsigned char * text = sqlite3_column_text( _stmt, column );
			return [NSString stringWithUTF8String:(char*)text];
		}
		default:
			return nil;
	}
}

- (id)column {
	return [self column:_column++];
}

- (NSDictionary*)allColumns {
	NSMutableDictionary * temp_values = [[NSMutableDictionary alloc] init];
	int n = [self columnCount];
	for ( int i = 0; i < n; i++ ) {
		id value = [self column:i];
		if (!value)
			continue;
		NSString * name = [self columnName:i];
		[temp_values setObject:value forKey:name];
	}
	NSDictionary * values = [[NSDictionary alloc] initWithDictionary:temp_values];
	[temp_values release];
	return [values autorelease];
}

- (void)bindLongLongInt:(long long int)value
			   forIndex:(int)index {
	[self setResult:sqlite3_bind_int64( _stmt, index+1, value )];
}

- (void)bindLongLongInt:(long long int)value {
	[self bindLongLongInt:value forIndex:_bind++];
}

- (void)bindString:(NSString*)value
		  forIndex:(int)index {
	[self setResult:sqlite3_bind_text( _stmt, index+1, [value UTF8String], -1, SQLITE_TRANSIENT )];
}

- (void)bindString:(NSString*)value {
	[self bindString:value forIndex:_bind++];
}

@end
