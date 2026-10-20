#import <Foundation/Foundation.h>

@class Manga;
@class Chapter;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SourceType) {
    SourceTypeBuiltIn = 0,
    SourceTypeCustom,
    SourceTypeExtension
};

typedef NS_ENUM(NSInteger, SourceLanguage) {
    SourceLanguageAll = 0,
    SourceLanguageEnglish,
    SourceLanguageJapanese,
    SourceLanguageChinese,
    SourceLanguageKorean,
    SourceLanguageSpanish,
    SourceLanguageFrench,
    SourceLanguageGerman,
    SourceLanguagePortuguese,
    SourceLanguageItalian,
    SourceLanguageRussian,
    SourceLanguageArabic,
    SourceLanguageIndonesian,
    SourceLanguageThai,
    SourceLanguageVietnamese,
    SourceLanguageTurkish
};

@protocol SourceParser <NSObject>

@required
- (NSString *)sourceIdentifier;
- (NSString *)sourceName;
- (NSString *)sourceVersion;
- (NSArray<NSNumber *> *)supportedLanguages;
- (BOOL)supportsNSFW;
- (BOOL)supportsSearch;
- (BOOL)supportsPopular;
- (BOOL)supportsLatestUpdates;
- (BOOL)supportsGenreFilter;

@optional
- (void)fetchMangaListWithPage:(NSInteger)page
                        filters:(nullable NSDictionary *)filters
                      completion:(void (^)(NSArray<Manga *> * _Nullable mangas, BOOL hasMore, NSError * _Nullable error))completion;

- (void)fetchMangaDetailsWithIdentifier:(NSString *)identifier
                              completion:(void (^)(Manga * _Nullable manga, NSError * _Nullable error))completion;

- (void)fetchChapterListForManga:(NSString *)mangaIdentifier
                       completion:(void (^)(NSArray<Chapter *> * _Nullable chapters, NSError * _Nullable error))completion;

- (void)fetchPageURLsForChapter:(Chapter *)chapter
                      completion:(void (^)(NSArray<NSString *> * _Nullable pageURLs, NSError * _Nullable error))completion;

- (void)searchMangaWithQuery:(NSString *)query
                      page:(NSInteger)page
                  completion:(void (^)(NSArray<Manga *> * _Nullable mangas, BOOL hasMore, NSError * _Nullable error))completion;

- (void)fetchPopularMangaWithPage:(NSInteger)page
                       completion:(void (^)(NSArray<Manga *> * _Nullable mangas, BOOL hasMore, NSError * _Nullable error))completion;

- (void)fetchLatestUpdatesWithPage:(NSInteger)page
                        completion:(void (^)(NSArray<Manga *> * _Nullable mangas, BOOL hasMore, NSError * _Nullable error))completion;

- (NSArray<NSDictionary *> *)fetchGenreList;

@end

@interface Source : NSObject <NSCopying, NSCoding>

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *baseURL;
@property (nonatomic, copy, readonly) NSString *iconURL;
@property (nonatomic, assign, readonly) SourceType type;
@property (nonatomic, assign, readonly) SourceLanguage language;
@property (nonatomic, assign, readonly) BOOL isNSFW;
@property (nonatomic, assign, readonly) BOOL isEnabled;
@property (nonatomic, copy, readonly) NSDictionary *customHeaders;
@property (nonatomic, copy, readonly) NSDictionary *customCookies;
@property (nonatomic, strong, readonly) NSDate *lastUpdated;
@property (nonatomic, copy, readonly) NSString *parserClassName;

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
                     parserClassName:(NSString *)parserClassName;

+ (instancetype)sourceWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end

NS_ASSUME_NONNULL_END