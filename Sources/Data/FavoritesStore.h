#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class Manga;
@class Chapter;

/// Persistência simples (NSKeyedArchiver) — equivalente ao Room DB do Kotatsu Android
/// Escopo: favoritos, histórico de leitura e progresso de capítulos
@interface FavoritesStore : NSObject

+ (instancetype)sharedStore;

#pragma mark - Favoritos

- (NSArray<Manga *> *)allFavorites;
- (BOOL)isFavorite:(Manga *)manga;
- (void)toggleFavorite:(Manga *)manga;
- (void)removeFavorite:(Manga *)manga;

#pragma mark - Histórico

/// Registra leitura de um capítulo (atualiza lastReadDate e capítulo atual)
- (void)recordRead:(Chapter *)chapter forManga:(Manga *)manga;
/// Última leitura (para "Continue reading" na Library)
- (nullable Manga *)lastReadManga;
- (nullable NSDate *)lastReadDateForManga:(Manga *)manga;
/// Índice do último capítulo lido (-1 se nunca leu)
- (NSInteger)lastReadChapterIndexForManga:(Manga *)manga;

#pragma mark - Capítulos lidos

- (BOOL)isChapterRead:(NSString *)chapterId;
- (void)markChapterRead:(NSString *)chapterId;
- (NSInteger)readCountForManga:(NSString *)mangaId;

@end

NS_ASSUME_NONNULL_END
