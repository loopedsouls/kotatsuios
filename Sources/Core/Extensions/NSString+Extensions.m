#import "NSString+Extensions.h"

@implementation NSString (Extensions)

- (NSString *)trimmedString {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)stringByRemovingHTMLTags {
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"<[^>]*>"
                                                          options:0
                                                            error:nil];
    });
    NSString *result = [regex stringByReplacingMatchesInString:self
                                                       options:0
                                                         range:NSMakeRange(0, self.length)
                                                  withTemplate:@" "];
    return [result stringByCollapsingWhitespace];
}

- (NSString *)stringByCollapsingWhitespace {
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+"
                                                          options:0
                                                            error:nil];
    });
    NSString *result = [regex stringByReplacingMatchesInString:self
                                                       options:0
                                                         range:NSMakeRange(0, self.length)
                                                  withTemplate:@" "];
    return [result trimmedString];
}

- (BOOL)containsStringCaseInsensitive:(NSString *)substring {
    if (!substring || substring.length == 0) return NO;
    return [self rangeOfString:substring
                       options:NSCaseInsensitiveSearch].location != NSNotFound;
}

- (NSString *)urlEncodedString {
    NSCharacterSet *allowed = [NSCharacterSet URLQueryAllowedCharacterSet];
    return [self stringByAddingPercentEncodingWithAllowedCharacters:allowed];
}

- (nullable NSURL *)toURL {
    if (self.length == 0) return nil;
    return [NSURL URLWithString:self];
}

- (NSString *)firstNonEmptyLine {
    NSArray<NSString *> *lines = [self componentsSeparatedByCharactersInSet:
                                  [NSCharacterSet newlineCharacterSet]];
    for (NSString *line in lines) {
        NSString *trimmed = [line trimmedString];
        if (trimmed.length > 0) return trimmed;
    }
    return @"";
}

- (NSString *)truncatedToLength:(NSUInteger)length {
    if (self.length <= length) return self;
    if (length <= 3) return [self substringToIndex:length];
    return [[self substringToIndex:length - 3] stringByAppendingString:@"..."];
}

- (NSString *)localized {
    return NSLocalizedString(self, nil);
}

@end
