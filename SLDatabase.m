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

@synthesize err=err_, dtbs=dtbs_;

+ (id)databaseWithPath:(NSString*)inPath
{
    return [[[SLDatabase alloc] initWithPath:inPath] autorelease];
}

- (id)initWithPath:(NSString*)inPath
{
	self = [super init];
	if (!self) return self;
	err_ = sqlite3_open([inPath UTF8String], &dtbs_);
	return self;
}

- (void)dealloc
{
	sqlite3_close( dtbs_ );
	[super dealloc];
}

- (SLStmt*)prepare:(NSString*)sql
{
	SLStmt *stmt = [[SLStmt alloc] initWithDatabase:self sql:sql];
	err_ = stmt.err;
	return stmt;
}

@end
