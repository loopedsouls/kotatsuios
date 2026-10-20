#import "Manga.h"

@implementation Manga

- (instancetype)initWithIdentifier:(NSString *)identifier
                              title:(NSString *)title
                       sourceIdentifier:(NSString *)sourceIdentifier
                           coverURL:(nullable NSString *)coverURL
                           author:(nullable NSString *)author
                           artist:(nullable NSString *)artist
                        description:(nullable NSString *)description
                           genres:(NSArray<NSString *> *)genres
                            tags:(NSArray<NSString *> *)tags
                          status:(MangaStatus)status
                     contentRating:(ContentRating)contentRating
                      chapterCount:(NSInteger)chapterCount {
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _title = [title copy];
        _sourceIdentifier = [sourceIdentifier copy];
        _coverURL = coverURL ? [coverURL copy] : nil;
        _author = author ? [author copy] : nil;
        _artist = artist ? [artist copy] : nil;
        _descriptionText = description ? [description copy] : nil;
        _genres = [genres copy];
        _tags = [tags copy];
        _status = status;
        _contentRating = contentRating;
        _chapterCount = chapterCount;
        _favorite = NO;
        _tracked = NO;
        _lastReadChapterIndex = 0;
        _lastReadDate = nil;
        _lastUpdate = nil;
        _alternativeTitle = nil;
        _bannerURL = nil;
    }
    return self;
}

+ (instancetype)mangaWithDictionary:(NSDictionary *)dict {
    return [[self alloc] initWithIdentifier:dict[@"identifier"]
                                       title:dict[@"title"]
                                sourceIdentifier:dict[@"sourceIdentifier"]
                                    coverURL:dict[@"coverURL"]
                                    author:dict[@"author"]
                                    artist:dict[@"artist"]
                                 description:dict[@"description"]
                                    genres:dict[@"genres"] ?: @[]
                                     tags:dict[@"tags"] ?: @[]
                                   status:[dict[@"status"] integerValue]
                          contentRating:[dict[@"contentRating"] integerValue]
                           chapterCount:[dict[@"chapterCount"] integerValue]];
}

- (NSDictionary *)dictionaryRepresentation {
    return @{
        @"identifier": _identifier,
        @"title": _title,
        @"alternativeTitle": _alternativeTitle,
        @"description": _descriptionText,
        @"author": _author,
        @"artist": _artist,
        @"coverURL": _coverURL,
        @"bannerURL": _bannerURL,
        @"lastUpdate": _lastUpdate,
        @"status": @(_status),
        @"contentRating": @(_contentRating),
        @"genres": _genres,
        @"tags": _tags,
        @"sourceIdentifier": _sourceIdentifier,
        @"favorite": @(_favorite),
        @"tracked": @(_tracked),
        @"chapterCount": @(_chapterCount),
        @"lastReadChapterIndex": @(_lastReadChapterIndex),
        @"lastReadDate": _lastReadDate
    };
}

- (id)copyWithZone:(NSZone *)zone {
    Manga *copy = [[[self class] allocWithZone:zone] initWithIdentifier:_identifier
                                                                    title:_title
                                                             sourceIdentifier:_sourceIdentifier
                                                                 coverURL:_coverURL
                                                                 author:_author
                                                                 artist:_artist
                                                              description:_descriptionText
                                                                 genres:_genres
                                                                  tags:_tags
                                                                status:_status
                                                         contentRating:_contentRating
                                                          chapterCount:_chapterCount];
    copy.alternativeTitle = _alternativeTitle;
    copy.bannerURL = _bannerURL;
    copy.lastUpdate = _lastUpdate;
    copy.favorite = _favorite;
    copy.tracked = _tracked;
    copy.lastReadChapterIndex = _lastReadChapterIndex;
    copy.lastReadDate = _lastReadDate;
    return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_identifier forKey:@"identifier"];
    [coder encodeObject:_title forKey:@"title"];
    [coder encodeObject:_alternativeTitle forKey:@"alternativeTitle"];
    [coder encodeObject:_descriptionText forKey:@"description"];
    [coder encodeObject:_author forKey:@"author"];
    [coder encodeObject:_artist forKey:@"artist"];
    [coder encodeObject:_coverURL forKey:@"coverURL"];
    [coder encodeObject:_bannerURL forKey:@"bannerURL"];
    [coder encodeObject:_lastUpdate forKey:@"lastUpdate"];
    [coder encodeInteger:_status forKey:@"status"];
    [coder encodeInteger:_contentRating forKey:@"contentRating"];
    [coder encodeObject:_genres forKey:@"genres"];
    [coder encodeObject:_tags forKey:@"tags"];
    [coder encodeObject:_sourceIdentifier forKey:@"sourceIdentifier"];
    [coder encodeBool:_favorite forKey:@"favorite"];
    [coder encodeBool:_tracked forKey:@"tracked"];
    [coder encodeInteger:_chapterCount forKey:@"chapterCount"];
    [coder encodeInteger:_lastReadChapterIndex forKey:@"lastReadChapterIndex"];
    [coder encodeObject:_lastReadDate forKey:@"lastReadDate"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _identifier = [coder decodeObjectForKey:@"identifier"];
        _title = [coder decodeObjectForKey:@"title"];
        _alternativeTitle = [coder decodeObjectForKey:@"alternativeTitle"];
        _descriptionText = [coder decodeObjectForKey:@"description"];
        _author = [coder decodeObjectForKey:@"author"];
        _artist = [coder decodeObjectForKey:@"artist"];
        _coverURL = [coder decodeObjectForKey:@"coverURL"];
        _bannerURL = [coder decodeObjectForKey:@"bannerURL"];
        _lastUpdate = [coder decodeObjectForKey:@"lastUpdate"];
        _status = [coder decodeIntegerForKey:@"status"];
        _contentRating = [coder decodeIntegerForKey:@"contentRating"];
        _genres = [coder decodeObjectForKey:@"genres"];
        _tags = [coder decodeObjectForKey:@"tags"];
        _sourceIdentifier = [coder decodeObjectForKey:@"sourceIdentifier"];
        _favorite = [coder decodeBoolForKey:@"favorite"];
        _tracked = [coder decodeBoolForKey:@"tracked"];
        _chapterCount = [coder decodeIntegerForKey:@"chapterCount"];
        _lastReadChapterIndex = [coder decodeIntegerForKey:@"lastReadChapterIndex"];
        _lastReadDate = [coder decodeObjectForKey:@"lastReadDate"];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[Manga class]]) return NO;
    Manga *other = (Manga *)object;
    return [_identifier isEqualToString:other.identifier] &&
           [_sourceIdentifier isEqualToString:other.sourceIdentifier];
}

- (NSUInteger)hash {
    return [_identifier hash] ^ [_sourceIdentifier hash];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<Manga: %@ (%@)>", _title, _identifier];
}

@end