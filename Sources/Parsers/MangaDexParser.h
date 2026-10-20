#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class Manga;
@class Chapter;

/// Parser da API do MangaDex (api.mangadex.org)
/// Equivalente Kotlin: kotatsu-parsers MultiMangaParser (MangaDex)
@interface MangaDexParser : NSObject

+ (instancetype)sharedParser;

/// GET /manga?limit=..&offset=..&order[followedCount]=desc
- (void)fetchPopularWithPage:(NSInteger)page
                  completion:(void (^)(NSArray<Manga *> *mangas, BOOL hasMore, NSError * _Nullable error))completion;

/// GET /manga?title=..&limit=..&offset=..
- (void)searchWithQuery:(NSString *)query
                   page:(NSInteger)page
             completion:(void (^)(NSArray<Manga *> *mangas, BOOL hasMore, NSError * _Nullable error))completion;

/// GET /manga/{id} (com includes[]=cover_art,author,artist)
- (void)fetchDetailsWithIdentifier:(NSString *)identifier
                        completion:(void (^)(Manga * _Nullable manga, NSError * _Nullable error))completion;

/// GET /manga/{id}/feed?translatedLanguage[]=en&order[chapter]=desc&limit=500
- (void)fetchChaptersForManga:(NSString *)mangaIdentifier
                   completion:(void (^)(NSArray<Chapter *> * _Nullable chapters, NSError * _Nullable error))completion;

/// GET /at-home/server/{chapterId}
- (void)fetchPageURLsForChapter:(Chapter *)chapter
                     completion:(void (^)(NSArray<NSString *> * _Nullable pageURLs, NSError * _Nullable error))completion;

/// URL da capa: https://uploads.mangadex.org/covers/{mangaId}/{fileName}
+ (NSString *)coverURLForMangaId:(NSString *)mangaId coverFileName:(nullable NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
