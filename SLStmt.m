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

@synthesize stmt=_stmt, currentSql=_currentSql;

- (NSError*)errorWithCode: (NSInteger)errorCode {
	int simpleError = errorCode & 0xFF;
	if ( ( simpleError != SQLITE_OK ) && ( simpleError < 100 ) ) {
		const char *msg = sqlite3_errmsg([_database dtbs]);
		return [NSError errorWithDomain: @"sqlite"
								   code: simpleError
							   userInfo: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithLongLong: errorCode], @"Code",
										  [NSString stringWithUTF8String: msg], @"Message", nil]];
	} else {
		return nil;
	}
}


- (void)setResult: (int)err
			error: (NSError**)outError {
	_errorCode = (err & 0xFF);
	NSError *theError = [self errorWithCode: err];
	if (outError) {
		*outError = theError;
	}
}


+ (id)stmtWithDatabase: (SLDatabase*)database {
	return [[[self alloc] initWithDatabase: database] autorelease];
}


- (id)initWithDatabase: (SLDatabase*)database {
	self = [super init];
	if (!self) return self;
	_database = [database retain];
	return self;
}

- (void)dealloc {
	NSError *error;
	[self closeWithError: &error];
	[_sql release];
	[_currentSql release];
	_currentSql = nil;
	[_database release];
	[super dealloc];
}


- (void)updateCurrentSql {
	intptr_t length = (intptr_t)_nextSql - (intptr_t)_thisSql;
	NSMutableData *data = [NSMutableData dataWithCapacity: length+1];
	[data appendBytes: _thisSql length: length];
	
	const int zero = 0;
	[data appendBytes: &zero length: sizeof(zero)];
	
	[_currentSql release];
	_currentSql = [[NSString stringWithUTF8String: [data bytes]] retain];
}


- (BOOL)prepareSql: (NSString*)sql
			 error: (NSError**)outError {
	[sql retain];
	NSError *error;
	[self closeWithError: &error];
	[_sql release];
	_sql = sql;
	_thisSql = [_sql UTF8String];
	[self setResult: sqlite3_prepare_v2([_database dtbs], _thisSql, -1, &_stmt, &_nextSql)
			  error: outError];
	[self updateCurrentSql];
	_bind = 0;
	return (_errorCode == SQLITE_OK);
}

- (BOOL)prepareNextWithError: (NSError**)outError {
	if ( ( _nextSql == NULL ) || ( *_nextSql == 0 ) )
		return NO;
	_thisSql = _nextSql;
	[self setResult: sqlite3_prepare_v2([_database dtbs], _nextSql, -1, &_stmt, &_nextSql)
			  error: outError];
	[self updateCurrentSql];
	return (_errorCode == SQLITE_OK);
}

- (BOOL)resetWithError: (NSError**)outError {
	if ( !_stmt ) {
		return NO;
	}
	_bind = 0;
	_column = 0;
	[self setResult: sqlite3_reset( _stmt )
			  error: outError];
	return (_errorCode == SQLITE_OK);
}


- (BOOL)closeWithError: (NSError**)outError {
	BOOL ok = YES;
	if ( _stmt ) {
		[self setResult: sqlite3_finalize( _stmt )
				  error: outError];
		_stmt = NULL;
		[_currentSql release];
		_currentSql = nil;
	}
	return ok;
}

- (sqlite3_stmt*)stmt {
	return _stmt;
}

- (BOOL)stepWithError: (NSError**)outError {
	_column = 0;
	[self setResult: sqlite3_step( _stmt )
			  error: outError];
	return ( ( _errorCode == SQLITE_ROW ) | (_errorCode == SQLITE_DONE ) );
}

- (BOOL)stepHasRowWithError: (NSError**)outError {
	_column = 0;
	[self setResult: sqlite3_step( _stmt )
			  error: outError];
	return ( _errorCode == SQLITE_ROW );
}

- (BOOL)stepOverRowsWithError: (NSError**)outError {
	_column = 0;
	do {
		[self setResult: sqlite3_step( _stmt )
				  error: outError];
	} while ( _errorCode == SQLITE_ROW);
	return ( _errorCode == SQLITE_DONE );
}

- (NSArray*)columnNames {
	int columnCount = sqlite3_column_count( _stmt );
	id columns = [NSMutableArray arrayWithCapacity: columnCount];
	for (int i = 0; i < columnCount; i++ ) {
		const char *name = sqlite3_column_name( _stmt, i);
		[columns addObject: [NSString stringWithUTF8String: name]];
	}
	return [NSArray arrayWithArray: columns];
}

- (long long)columnCount {
	return sqlite3_column_count( _stmt );
}

- (NSString*)columnName: (int)column {
	const char *text = sqlite3_column_name( _stmt, column );
	if ( text == NULL )
		return nil;
	return [NSString stringWithUTF8String: text];
}

- (NSString*)columnName {
	const char *text = sqlite3_column_name( _stmt, _column );
	if ( text == NULL )
		return nil;
	return [NSString stringWithUTF8String: text];
}

- (long long)longLongValue: (int)column {
	return sqlite3_column_int64( _stmt, column );
}

- (long long)longLongValue {
	return [self longLongValue: _column++];
}

- (NSString*)stringValue: (int)column {
	const char *text = (char*)sqlite3_column_text( _stmt, column);
	if ( text == NULL )
		return nil;
	return [NSString stringWithUTF8String: text];
}

- (NSString*)stringValue {
	const char *text = (char*)sqlite3_column_text( _stmt, _column++);
	if ( text == NULL )
		return nil;
	return [NSString stringWithUTF8String: text];
}

- (int)columnType: (int)column {
	return sqlite3_column_type( _stmt, column );
}

- (int)columnType {
	return sqlite3_column_type( _stmt, _column );
}

- (id)value: (int)column {
	int type = sqlite3_column_type( _stmt, column );
	switch (type) {
		case SQLITE_INTEGER:
			return [NSNumber numberWithLongLong: sqlite3_column_int64( _stmt, column )];
		case SQLITE_FLOAT:
			return [NSNumber numberWithDouble: sqlite3_column_double( _stmt, column )];
		case SQLITE_BLOB: {
			const void *bytes = sqlite3_column_blob( _stmt, column );
			return [NSData dataWithBytes: bytes
								  length: sqlite3_column_bytes( _stmt, column )];
		}
		case SQLITE_NULL:
			return nil;
		case SQLITE_TEXT:
			return [NSString stringWithUTF8String: (char*)sqlite3_column_text( _stmt, column ) ];
		default:
			return nil;
	}
}

- (id)value {
	return [self value: _column++];
}

- (NSDictionary*)allValues {
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

- (BOOL)bindLongLong: (long long)value
			forIndex: (int)index
			   error: (NSError**)outError {
	[self setResult: sqlite3_bind_int64( _stmt, index+1, value )
			  error: outError];
	return ( _errorCode = SQLITE_OK );
}

- (BOOL)bindLongLong: (long long)value
			   error: (NSError**)outError {
	return [self bindLongLong: value
					 forIndex: _bind++
						error: outError];
}

- (BOOL)bindString: (NSString*)value
		  forIndex: (int)index
			 error: (NSError**)outError {
	[self setResult: sqlite3_bind_text( _stmt, index+1, [value UTF8String], -1, SQLITE_TRANSIENT )
			  error: outError];
	return ( _errorCode = SQLITE_OK );
	
}

- (BOOL)bindString: (NSString*)value
			 error: (NSError**)outError {
	return [self bindString: value
				   forIndex: _bind++
					  error: outError];
}

- (BOOL)bindData: (NSData*)value
		forIndex: (int)index
		   error: (NSError**)outError {
	[self setResult: sqlite3_bind_blob( _stmt, index+1, [value bytes], [value length], SQLITE_TRANSIENT )
			  error: outError];
	return ( _errorCode = SQLITE_OK );
	
}

- (BOOL)bindData: (NSData*)value
		   error: (NSError**)outError {
	return [self bindData: value
				 forIndex: _bind++
					error: outError];
}


- (NSArray*)bindDictionary:(NSDictionary*)bindings {
	if (bindings == nil)
		return nil;
	id accepted = [NSMutableArray arrayWithCapacity: bindings.count];
	NSArray *keys = [bindings allKeys];
	for (NSString *key in keys) {
		NSInteger bindIndex = [self findBinding: key];
		if ( bindIndex < 0 ) {
			continue;
		}
		id value = [bindings valueForKey: key];
		[accepted addObject: key];
		[self bindString: value
				forIndex: bindIndex
				   error: nil];
	}
	return [NSArray arrayWithArray: accepted];
}


- (int)findBinding: (NSString*)name {
	return sqlite3_bind_parameter_index( _stmt, [name UTF8String]) - 1;
}

@end
