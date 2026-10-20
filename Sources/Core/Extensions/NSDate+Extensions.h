#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (Extensions)

+ (nullable instancetype)dateFromISO8601String:(NSString *)string;
- (NSString *)iso8601String;
- (NSString *)relativeTimeString;
- (NSString *)formattedStringWithStyle:(NSDateFormatterStyle)style;
- (BOOL)isToday;
- (BOOL)isYesterday;
- (NSInteger)daysSinceDate:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END