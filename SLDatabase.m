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

@synthesize extendedErr, dtbs;
@dynamic simpleErr;



- (int)simpleErr;
{
	return extendedErr & 0xFF;
}



- (void)setResult: (int)inErr;
{
	extendedErr = inErr;
	msg = sqlite3_errmsg(dtbs);
	if ( ( extendedErr != SQLITE_OK ) && ( self.simpleErr < 100 ) )
		NSLog( @"SLDatabase: (%d) %s", extendedErr, msg );
}



+ (id)databaseWithPath: (NSString *)inPath;
{
    return [[[self alloc] initWithPath:inPath] autorelease];
}



- (id)initWithPath: (NSString *)inPath;
{
	self = [super init];
	if (!self) return self;
	[self setResult: sqlite3_open([inPath UTF8String], &dtbs)];
	sqlite3_extended_result_codes( dtbs, TRUE );
	return self;
}



- (void)dealloc;
{
	int theErr = sqlite3_close( dtbs );
	if ( theErr != SQLITE_OK )
		NSLog( @"Error %d while closing database.", theErr );
	[super dealloc];
}



- (BOOL)execSQL: (NSString *)inSQL;
{
	[self setResult: sqlite3_exec(dtbs, [inSQL UTF8String], NULL, NULL, NULL)];
	return (extendedErr == SQLITE_OK);
}



- (long long)lastInserted;
{
	return sqlite3_last_insert_rowid(dtbs);
}



@end
