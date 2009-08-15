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

@synthesize extendedErr=_err, dtbs=_dtbs;

- (int)simpleErr
{
	return _err & 0xFF;
}

- (void)setResult: (int)err
{
	_err = err;
	_msg = sqlite3_errmsg(_dtbs);
	if ( ( _err != SQLITE_OK ) && ( self.simpleErr < 100 ) )
		NSLog( @"SLDatabase: (%d) %s", _err, _msg );
}

+ (id)databaseWithPath: (NSString *)inPath
{
    return [[[self alloc] initWithPath:inPath] autorelease];
}

- (id)initWithPath: (NSString *)inPath
{
	self = [super init];
	if (!self) return self;
	[self setResult:sqlite3_open([inPath UTF8String], &_dtbs)];
	sqlite3_extended_result_codes( _dtbs, TRUE );
	return self;
}

- (void)dealloc
{
	int err = sqlite3_close( _dtbs );
	if ( err != SQLITE_OK )
		NSLog( @"Error %d while closing database.", err );
	[super dealloc];
}

- (BOOL)exec: (NSString *)sql
{
	[self setResult:sqlite3_exec(_dtbs, [sql UTF8String], NULL, NULL, NULL)];
	return _err == SQLITE_OK;
}

- (long long)lastInserted
{
	return sqlite3_last_insert_rowid(_dtbs);
}


@end
