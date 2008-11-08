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

@synthesize err=err_, stmt=stmt_;

+ (id)stmtWithDatabase:(SLDatabase*)database sql:(NSString*)sql
{
    return [[[SLStmt alloc] initWithDatabase:database sql:sql] autorelease];
}

- (id)initWithDatabase:(SLDatabase*)database sql:(NSString*)sql
{
	self = [super init];
	if (!self) return self;
	err_ = sqlite3_prepare_v2([database dtbs], [sql UTF8String], -1, &stmt_, 0);
	return self;
}

- (void)dealloc
{
	sqlite3_finalize( stmt_ );
	[super dealloc];
}

- (sqlite3_stmt*)stmt
{
	return stmt_;
}

- (int)err
{
	return err_;
}

- (BOOL)step
{
	err_ = sqlite3_step( stmt_ );
	return ( err_ == SQLITE_ROW ) ? YES : NO;
}

- (sqlite_int64)int64Column:(int)column
{
	return sqlite3_column_int64( stmt_, column );
}

- (NSString*)textColumn:(int)column
{
	const char * text = (char*)sqlite3_column_text( stmt_, column);
	if ( text == NULL )
		return NULL;
	return [[NSString alloc] initWithUTF8String:text];
}

- (void)bindInt64:(int)bind value:(sqlite_int64)value
{
	err_ = sqlite3_bind_int64( stmt_, bind+1, value );
}

@end
