#import "Source.h"
#import "Manga.h"
#import "Chapter.h"

@implementation Source

- (instancetype)initWithIdentifier:(NSString *)identifier
                              name:(NSString *)name
                           baseURL:(NSString *)baseURL
                           iconURL:(nullable NSString *)iconURL
                             type:(SourceType)type
                          language:(SourceLanguage)language
                           isNSFW:(BOOL)isNSFW
                         isEnabled:(BOOL)isEnabled
                     customHeaders:(nullable NSDictionary *)customHeaders
                      customCookies:(nullable NSDictionary *)customCookies
                     parserClassName:(NSString *)parserClassName {
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _name = [name copy];
        _baseURL = [baseURL copy];
        _iconURL = iconURL ? [iconURL copy] : nil;
        _type = type;
        _language = language;
        _isNSFW = isNSFW;
        _isEnabled = isEnabled;
        _customHeaders = customHeaders ? [customHeaders copy] : @{};
        _customCookies = customCookies ? [customCookies copy] : @{};
        _parserClassName = [parserClassName copy];
        _lastUpdated = [NSDate date];
    }
    return self;
}

+ (instancetype)sourceWithDictionary:(NSDictionary *)dict {
    return [[self alloc] initWithIdentifier:dict[@"identifier"]
                                       name:dict[@"name"]
                                    baseURL:dict[@"baseURL"]
                                    iconURL:dict[@"iconURL"]
                                      type:[dict[@"type"] integerValue]
                                   language:[dict[@"language"] integerValue]
                                    isNSFW:[dict[@"isNSFW"] boolValue]
                                  isEnabled:[dict[@"isEnabled"] boolValue]
                              customHeaders:dict[@"customHeaders"]
                               customCookies:dict[@"customCookies"]
                              parserClassName:dict[@"parserClassName"]];
}

- (NSDictionary *)dictionaryRepresentation {
    return @{
        @"identifier": _identifier,
        @"name": _name,
        @"baseURL": _baseURL,
        @"iconURL": _iconURL,
        @"type": @(_type),
        @"language": @(_language),
        @"isNSFW": @(_isNSFW),
        @"isEnabled": @(_isEnabled),
        @"customHeaders": _customHeaders,
        @"customCookies": _customCookies,
        @"lastUpdated": _lastUpdated,
        @"parserClassName": _parserClassName
    };
}

- (id)copyWithZone:(NSZone *)zone {
    Source *copy = [[[self class] allocWithZone:zone] initWithIdentifier:_identifier
                                                                    name:_name
                                                                 baseURL:_baseURL
                                                                 iconURL:_iconURL
                                                                   type:_type
                                                              language:_language
                                                               isNSFW:_isNSFW
                                                             isEnabled:_isEnabled
                                                         customHeaders:_customHeaders
                                                          customCookies:_customCookies
                                                         parserClassName:_parserClassName];
    copy->_lastUpdated = _lastUpdated;
    return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_identifier forKey:@"identifier"];
    [coder encodeObject:_name forKey:@"name"];
    [coder encodeObject:_baseURL forKey:@"baseURL"];
    [coder encodeObject:_iconURL forKey:@"iconURL"];
    [coder encodeInteger:_type forKey:@"type"];
    [coder encodeInteger:_language forKey:@"language"];
    [coder encodeBool:_isNSFW forKey:@"isNSFW"];
    [coder encodeBool:_isEnabled forKey:@"isEnabled"];
    [coder encodeObject:_customHeaders forKey:@"customHeaders"];
    [coder encodeObject:_customCookies forKey:@"customCookies"];
    [coder encodeObject:_lastUpdated forKey:@"lastUpdated"];
    [coder encodeObject:_parserClassName forKey:@"parserClassName"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _identifier = [coder decodeObjectForKey:@"identifier"];
        _name = [coder decodeObjectForKey:@"name"];
        _baseURL = [coder decodeObjectForKey:@"baseURL"];
        _iconURL = [coder decodeObjectForKey:@"iconURL"];
        _type = [coder decodeIntegerForKey:@"type"];
        _language = [coder decodeIntegerForKey:@"language"];
        _isNSFW = [coder decodeBoolForKey:@"isNSFW"];
        _isEnabled = [coder decodeBoolForKey:@"isEnabled"];
        _customHeaders = [coder decodeObjectForKey:@"customHeaders"];
        _customCookies = [coder decodeObjectForKey:@"customCookies"];
        _lastUpdated = [coder decodeObjectForKey:@"lastUpdated"];
        _parserClassName = [coder decodeObjectForKey:@"parserClassName"];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[Source class]]) return NO;
    Source *other = (Source *)object;
    return [_identifier isEqualToString:other.identifier];
}

- (NSUInteger)hash {
    return [_identifier hash];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<Source: %@ (%@)>", _name, _identifier];
}

@end