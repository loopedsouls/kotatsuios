#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Extensions)

- (NSString *)trimmedString;
- (NSString *)stringByRemovingHTMLTags;
- (NSString *)stringByCollapsingWhitespace;
- (BOOL)containsStringCaseInsensitive:(NSString *)substring;
- (NSString *)urlEncodedString;
- (nullable NSURL *)toURL;
- (NSString *)firstNonEmptyLine;
- (NSString *)truncatedToLength:(NSUInteger)length;
- (NSString *)localized;

@end

NS_ASSUME_NONNULL_END
