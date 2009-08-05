//
//  SLExtensions.h
//
//  Copyright 2009 Steven Fisher.
//
//  This file is covered by the MIT/X11 License.
//  See LICENSE.TXT for more information.
//

#import <CoreFoundation/CoreFoundation.h>

@interface NSDateFormatter(sqlitem)
+ (NSString*)sqlStringFromDate: (NSDate*)date;
+ (NSDate*)sqlDateFromString: (NSString*)date;
@end
