#import "Chapter.h"

@implementation Chapter

- (instancetype)initWithIdentifier:(NSString *)identifier
                            title:(NSString *)title
                     mangaIdentifier:(NSString *)mangaIdentifier
                  sourceIdentifier:(NSString *)sourceIdentifier
                              index:(NSInteger)index
                          pageURLs:(NSArray<NSString *> *)pageURLs
                       dateUploaded:(nullable NSDate *)dateUploaded
                          isRead:(BOOL)isRead
                      isDownloaded:(BOOL)isDownloaded
                          volume:(nullable NSString *)volume
                     chapterNumber:(nullable NSString *)chapterNumber
                    languageCode:(nullable NSString *)languageCode {
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _title = [title copy];
        _mangaIdentifier = [mangaIdentifier copy];
        _sourceIdentifier = [sourceIdentifier copy];
        _index = index;
        _pageURLs = [pageURLs copy];
        _dateUploaded = dateUploaded;
        _isRead = isRead;
        _isDownloaded = isDownloaded;
        _volume = volume ? [volume copy] : nil;
        _chapterNumber = chapterNumber ? [chapterNumber copy] : nil;
        _languageCode = languageCode ? [languageCode copy] : nil;
        _pageCount = pageURLs.count;
    }
    return self;
}

+ (instancetype)chapterWithDictionary:(NSDictionary *)dict {
    return [[self alloc] initWithIdentifier:dict[@"identifier"]
                                       title:dict[@"title"]
                                mangaIdentifier:dict[@"mangaIdentifier"]
                             sourceIdentifier:dict[@"sourceIdentifier"]
                                         index:[dict[@"index"] integerValue]
                                     pageURLs:dict[@"pageURLs"] ?: @[]
                                  dateUploaded:dict[@"dateUploaded"]
                                     isRead:[dict[@"isRead"] boolValue]
                                 isDownloaded:[dict[@"isDownloaded"] boolValue]
                                     volume:dict[@"volume"]
                                chapterNumber:dict[@"chapterNumber"]
                               languageCode:dict[@"languageCode"]];
}

- (NSDictionary *)dictionaryRepresentation {
    return @{
        @"identifier": _identifier,
        @"title": _title,
        @"mangaIdentifier": _mangaIdentifier,
        @"sourceIdentifier": _sourceIdentifier,
        @"index": @(_index),
        @"pageURLs": _pageURLs,
        @"dateUploaded": _dateUploaded,
        @"isRead": @(_isRead),
        @"isDownloaded": @(_isDownloaded),
        @"volume": _volume,
        @"chapterNumber": _chapterNumber,
        @"languageCode": _languageCode,
        @"pageCount": @(_pageCount)
    };
}

- (id)copyWithZone:(NSZone *)zone {
    Chapter *copy = [[[self class] allocWithZone:zone] initWithIdentifier:_identifier
                                                                    title:_title
                                                             mangaIdentifier:_mangaIdentifier
                                                          sourceIdentifier:_sourceIdentifier
                                                                        index:_index
                                                                    pageURLs:_pageURLs
                                                             dateUploaded:_dateUploaded
                                                                isRead:_isRead
                                                            isDownloaded:_isDownloaded
                                                                    volume:_volume
                                                           chapterNumber:_chapterNumber
                                                          languageCode:_languageCode];
    return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_identifier forKey:@"identifier"];
    [coder encodeObject:_title forKey:@"title"];
    [coder encodeObject:_mangaIdentifier forKey:@"mangaIdentifier"];
    [coder encodeObject:_sourceIdentifier forKey:@"sourceIdentifier"];
    [coder encodeInteger:_index forKey:@"index"];
    [coder encodeObject:_pageURLs forKey:@"pageURLs"];
    [coder encodeObject:_dateUploaded forKey:@"dateUploaded"];
    [coder encodeBool:_isRead forKey:@"isRead"];
    [coder encodeBool:_isDownloaded forKey:@"isDownloaded"];
    [coder encodeObject:_volume forKey:@"volume"];
    [coder encodeObject:_chapterNumber forKey:@"chapterNumber"];
    [coder encodeObject:_languageCode forKey:@"languageCode"];
    [coder encodeInteger:_pageCount forKey:@"pageCount"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _identifier = [coder decodeObjectForKey:@"identifier"];
        _title = [coder decodeObjectForKey:@"title"];
        _mangaIdentifier = [coder decodeObjectForKey:@"mangaIdentifier"];
        _sourceIdentifier = [coder decodeObjectForKey:@"sourceIdentifier"];
        _index = [coder decodeIntegerForKey:@"index"];
        _pageURLs = [coder decodeObjectForKey:@"pageURLs"];
        _dateUploaded = [coder decodeObjectForKey:@"dateUploaded"];
        _isRead = [coder decodeBoolForKey:@"isRead"];
        _isDownloaded = [coder decodeBoolForKey:@"isDownloaded"];
        _volume = [coder decodeObjectForKey:@"volume"];
        _chapterNumber = [coder decodeObjectForKey:@"chapterNumber"];
        _languageCode = [coder decodeObjectForKey:@"languageCode"];
        _pageCount = [coder decodeIntegerForKey:@"pageCount"];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[Chapter class]]) return NO;
    Chapter *other = (Chapter *)object;
    return [_identifier isEqualToString:other.identifier] &&
           [_mangaIdentifier isEqualToString:other.mangaIdentifier];
}

- (NSUInteger)hash {
    return [_identifier hash] ^ [_mangaIdentifier hash];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<Chapter: %@ (%@)>", _title, _identifier];
}

@end