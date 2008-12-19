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

@synthesize extendedErr=err_, stmt=stmt_;

- (int)simpleErr {
	return err_ & 0xFF;
}

- (void)setResult:(int)err {
	err_ = err;
	msg_ = sqlite3_errmsg(database_);
	if ( ( err_ != SQLITE_OK ) && ( self.simpleErr < 100 ) )
		NSLog( @"SLStmt: (%d) %s", err_, msg_ );
}

+ (id)stmtWithDatabase:(SLDatabase*)database sql:(NSString*)sql {
    return [[[SLStmt alloc] initWithDatabase:database sql:sql] autorelease];
}

- (id)initWithDatabase:(SLDatabase*)database sql:(NSString*)sql {
	self = [super init];
	if (!self) return self;
	database_ = [database dtbs];
	[self prepare:sql];
	return self;
}

- (void)dealloc {
	if ( stmt_ )
		sqlite3_finalize( stmt_ );
	[super dealloc];
}

- (void)prepare:(NSString*)sql {
	if ( stmt_ ) {
		[self close];
		stmt_ = NULL;
	}
	[self setResult:sqlite3_prepare_v2(database_, [sql UTF8String], -1, &stmt_, 0)];
	bind_ = 0;
}

- (void)close {
	if ( stmt_ ) {
		sqlite3_finalize( stmt_ );
		stmt_ = NULL;
	}
}

- (sqlite3_stmt*)stmt {
	return stmt_;
}

- (BOOL)step {
	[self setResult:sqlite3_step( stmt_ )];
	column_ = 0;
	return ( [self simpleErr] == SQLITE_ROW ) ? YES : NO;
}

- (long long int)columnCount {
	return sqlite3_column_count( stmt_ );
}

- (NSString*)columnNameByIndex:(int)column {
	const char * text = sqlite3_column_name( stmt_, column );
	if ( text == NULL )
		return NULL;
	return [NSString stringWithUTF8String:text];
}

- (NSString*)thisColumnName {
	const char * text = sqlite3_column_name( stmt_, column_ );
	if ( text == NULL )
		return NULL;
	return [NSString stringWithUTF8String:text];
}

- (long long int)intColumnByIndex:(int)column {
	return sqlite3_column_int64( stmt_, column );
}

- (long long int)intColumn {
	return [self intColumnByIndex:column_++];
}

- (NSString*)stringColumnByIndex:(int)column {
	const char * text = (char*)sqlite3_column_text( stmt_, column);
	if ( text == NULL )
		return NULL;
	return [NSString stringWithUTF8String:text];
}

- (NSString*)stringColumn {
	const char * text = (char*)sqlite3_column_text( stmt_, column_++);
	if ( text == NULL )
		return NULL;
	return [NSString stringWithUTF8String:text];
}

- (int)columnTypeByIndex:(int)column {
	return sqlite3_column_type( stmt_, column );
}

- (int)columnType {
	return sqlite3_column_type( stmt_, column_ );
}

- (id)columnByIndex:(int)column {
	int type = sqlite3_column_type( stmt_, column );
	switch (type) {
		case SQLITE_INTEGER:
			return [NSNumber numberWithLongLong:sqlite3_column_int64( stmt_, column )];
		case SQLITE_FLOAT:
			return [NSNumber numberWithDouble:sqlite3_column_double( stmt_, column )];
		case SQLITE_BLOB: {
			const void * bytes = sqlite3_column_blob( stmt_, column );
			return [NSData dataWithBytes:bytes length:sqlite3_column_bytes( stmt_, column )];
		}
		case SQLITE_NULL:
			return NULL;
		case SQLITE_TEXT: {
			const unsigned char * text = sqlite3_column_text( stmt_, column );
			return [NSString stringWithUTF8String:(char*)text];
		}
		default:
			return NULL;
	}
}

- (id)column {
	return [self columnByIndex:column_++];
}

- (NSDictionary*)allColumns {
	NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
	int n = [self columnCount];
	for ( int i = 0; i < n; i++ ) {
		id value = [self columnByIndex:i];
		if (!value)
			continue;
		NSString * name = [self columnNameByIndex:i];
		[dict setObject:value forKey:name];
	}
	NSDictionary * dictr = [[NSDictionary alloc] initWithDictionary:dict];
	return dictr;
}

- (void)bindIntByIndex:(int)bind value:(long long int)value {
	[self setResult:sqlite3_bind_int64( stmt_, bind+1, value )];
}

- (void)bindInt:(long long int)value {
	[self bindIntByIndex:bind_++ value:value];
}

- (void)bindStringByIndex:(int)bind value:(NSString*)value {
	[self setResult:sqlite3_bind_text( stmt_, bind+1, [value UTF8String], -1, SQLITE_TRANSIENT )];
}

- (void)bindString:(NSString*)value {
	[self bindStringByIndex:bind_++ value:value];
}

@end
