//
//  SLExtensions.m
//
//  Copyright 2009 Steven Fisher.
//
//  This file is covered by the MIT/X11 License.
//  See LICENSE.TXT for more information.
//

#import "SLExtensions.h"

@implementation NSDateFormatter(sqlitem)

+ (NSString*)sqlStringFromDate: (NSDate*)inDate {
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat: @"yyyy-MM-dd'T'HH:mm:ss ZZZZ"];
	NSString *dateString = [dateFormat stringFromDate: inDate]; 
	[dateFormat release];
	return dateString;
}

+ (NSDate*)sqlDateFromString: (NSString*)inDate {
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat: @"yyyy-MM-dd'T'HH:mm:ss ZZZZ"];
	NSDate *date = [dateFormat dateFromString: inDate];  
	[dateFormat release];
	return date;
}

@end
