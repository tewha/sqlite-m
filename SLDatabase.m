//
//  SLDatabase.m
//
//  Copyright 2008 Steven Fisher.
//
//  This file is covered by the MIT/X11 License.
//  See LICENSE.TXT for more information.
//

#import "SLDatabase.h"
#import "SLStmt.h"

@implementation SLDatabase

@synthesize extendedErr=err_, dtbs=dtbs_;

- (int)simpleErr
{
	return err_ & 0xFF;
}

- (void)setResult:(int)err
{
	err_ = err;
	msg_ = sqlite3_errmsg(dtbs_);
	if ( ( err_ != SQLITE_OK ) && ( self.simpleErr < 100 ) )
		NSLog( @"SLDatabase: (%d) %s", err_, msg_ );
}

+ (id)databaseWithPath:(NSString*)inPath
{
    return [[[SLDatabase alloc] initWithPath:inPath] autorelease];
}

- (id)initWithPath:(NSString*)inPath
{
	self = [super init];
	if (!self) return self;
	[self setResult:sqlite3_open([inPath UTF8String], &dtbs_)];
	sqlite3_extended_result_codes( dtbs_, TRUE );
	return self;
}

- (void)dealloc
{
	sqlite3_close( dtbs_ );
	[super dealloc];
}

- (SLStmt*)prepare:(NSString*)sql
{
	SLStmt *stmt = [[[SLStmt alloc] initWithDatabase:self sql:sql] autorelease];
	[self setResult:stmt.extendedErr];
	return stmt;
}

- (BOOL)exec:(NSString*)sql
{
	[self setResult:sqlite3_exec(dtbs_, [sql UTF8String], NULL, NULL, NULL)];
	return err_ == SQLITE_OK;
}

@end
