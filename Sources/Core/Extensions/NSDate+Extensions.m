#import "NSDate+Extensions.h"

static NSDateFormatter *isoFormatter = nil;
static NSDateFormatter *relativeFormatter = nil;
static NSCalendar *sharedCalendar = nil;
static dispatch_once_t onceToken;

@implementation NSDate (Extensions)

+ (void)initialize {
    if (self == [NSDate class]) {
        dispatch_once(&onceToken, ^{
            isoFormatter = [[NSDateFormatter alloc] init];
            isoFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
            isoFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
            isoFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];

            relativeFormatter = [[NSDateFormatter alloc] init];
            relativeFormatter.doesRelativeDateFormatting = YES;
            relativeFormatter.dateStyle = NSDateFormatterMediumStyle;
            relativeFormatter.timeStyle = NSDateFormatterShortStyle;

            sharedCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        });
    }
}

+ (nullable instancetype)dateFromISO8601String:(NSString *)string {
    if (string.length == 0) return nil;
    return [isoFormatter dateFromString:string];
}

- (NSString *)iso8601String {
    return [isoFormatter stringFromDate:self];
}

- (NSString *)relativeTimeString {
    NSTimeInterval interval = [self timeIntervalSinceNow] * -1.0;
    if (interval < 60.0) {
        return NSLocalizedString(@"Just now", nil);
    } else if (interval < 3600.0) {
        NSInteger minutes = (NSInteger)(interval / 60.0);
        return [NSString stringWithFormat:@"%ldm ago", (long)minutes];
    } else if (interval < 86400.0) {
        NSInteger hours = (NSInteger)(interval / 3600.0);
        return [NSString stringWithFormat:@"%ldh ago", (long)hours];
    } else if (interval < 604800.0) {
        NSInteger days = (NSInteger)(interval / 86400.0);
        return [NSString stringWithFormat:@"%ldd ago", (long)days];
    } else if (interval < 2592000.0) {
        NSInteger weeks = (NSInteger)(interval / 604800.0);
        return [NSString stringWithFormat:@"%ldw ago", (long)weeks];
    } else if (interval < 31536000.0) {
        NSInteger months = (NSInteger)(interval / 2592000.0);
        return [NSString stringWithFormat:@"%ldmo ago", (long)months];
    } else {
        NSInteger years = (NSInteger)(interval / 31536000.0);
        return [NSString stringWithFormat:@"%ldy ago", (long)years];
    }
}

- (NSString *)formattedStringWithStyle:(NSDateFormatterStyle)style {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = style;
    formatter.timeStyle = NSDateFormatterNoStyle;
    return [formatter stringFromDate:self];
}

- (BOOL)isToday {
    return [sharedCalendar isDateInToday:self];
}

- (BOOL)isYesterday {
    return [sharedCalendar isDateInYesterday:self];
}

- (NSInteger)daysSinceDate:(NSDate *)date {
    NSDateComponents *components = [sharedCalendar components:NSCalendarUnitDay
                                                     fromDate:date
                                                       toDate:self
                                                      options:0];
    return components.day;
}

@end
