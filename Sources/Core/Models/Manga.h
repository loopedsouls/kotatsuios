#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MangaStatus) {
    MangaStatusUnknown = 0,
    MangaStatusOngoing = 1,
    MangaStatusCompleted = 2,
    MangaStatusHiatus = 3,
    MangaStatusCancelled = 4
};

typedef NS_ENUM(NSInteger, ContentRating) {
    ContentRatingSafe = 0,
    ContentRatingSuggestive = 1,
    ContentRatingErotica = 2,
    ContentRatingPornographic = 3
};

@interface Manga : NSObject <NSCopying, NSCoding>

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, nullable) NSString *alternativeTitle;
@property (nonatomic, copy, nullable) NSString *descriptionText;
@property (nonatomic, copy, nullable) NSString *author;
@property (nonatomic, copy, nullable) NSString *artist;
@property (nonatomic, copy, nullable) NSString *coverURL;
@property (nonatomic, copy, nullable) NSString *bannerURL;
@property (nonatomic, strong, nullable) NSDate *lastUpdate;
@property (nonatomic, assign) MangaStatus status;
@property (nonatomic, assign) ContentRating contentRating;
@property (nonatomic, copy, readonly) NSArray<NSString *> *genres;
@property (nonatomic, copy, readonly) NSArray<NSString *> *tags;
@property (nonatomic, copy, readonly) NSString *sourceIdentifier;
@property (nonatomic, assign, getter=isFavorite) BOOL favorite;
@property (nonatomic, assign, getter=isTracked) BOOL tracked;
@property (nonatomic, assign) NSInteger chapterCount;
@property (nonatomic, assign) NSInteger lastReadChapterIndex;
@property (nonatomic, strong, nullable) NSDate *lastReadDate;

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
                      chapterCount:(NSInteger)chapterCount;

+ (instancetype)mangaWithDictionary:(NSDictionary *)dict;

- (NSDictionary *)dictionaryRepresentation;

@end

NS_ASSUME_NONNULL_END