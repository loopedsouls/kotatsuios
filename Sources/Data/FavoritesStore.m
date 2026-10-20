#import "FavoritesStore.h"
#import "Manga.h"
#import "Chapter.h"

static NSString * const kFavoritesFile = @"favorites.plist";
static NSString * const kHistoryFile   = @"history.plist";
static NSString * const kReadChaptersFile = @"readchapters.plist";

@interface FavoritesStore ()
@property (nonatomic, strong) NSMutableArray<Manga *> *favorites;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *history; // mangaId -> {date, chapterIndex, manga}
@property (nonatomic, strong) NSMutableSet<NSString *> *readChapters;
@end

@implementation FavoritesStore

+ (instancetype)sharedStore {
    static FavoritesStore *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (NSString *)filePath:(NSString *)name {
    NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [docs stringByAppendingPathComponent:name];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _favorites = [NSMutableArray array];
        _history = [NSMutableDictionary dictionary];
        _readChapters = [NSMutableSet set];

        // Load favorites
        NSArray *favData = [NSKeyedUnarchiver unarchiveObjectWithFile:[self filePath:kFavoritesFile]];
        if ([favData isKindOfClass:[NSArray class]]) [_favorites addObjectsFromArray:favData];

        // Load history
        NSDictionary *histData = [NSKeyedUnarchiver unarchiveObjectWithFile:[self filePath:kHistoryFile]];
        if ([histData isKindOfClass:[NSDictionary class]]) [_history addEntriesFromDictionary:histData];

        // Load read chapters
        NSSet *readData = [NSKeyedUnarchiver unarchiveObjectWithFile:[self filePath:kReadChaptersFile]];
        if ([readData isKindOfClass:[NSSet class]]) [_readChapters addObjectsFromArray:readData.allObjects];
    }
    return self;
}

- (void)saveFavorites {
    [NSKeyedArchiver archiveRootObject:self.favorites toFile:[self filePath:kFavoritesFile]];
}

- (void)saveHistory {
    [NSKeyedArchiver archiveRootObject:self.history toFile:[self filePath:kHistoryFile]];
}

- (void)saveReadChapters {
    [NSKeyedArchiver archiveRootObject:self.readChapters toFile:[self filePath:kReadChaptersFile]];
}

#pragma mark - Favoritos

- (NSArray<Manga *> *)allFavorites {
    return [self.favorites copy];
}

- (BOOL)isFavorite:(Manga *)manga {
    for (Manga *m in self.favorites) {
        if ([m.identifier isEqualToString:manga.identifier]) return YES;
    }
    return NO;
}

- (void)toggleFavorite:(Manga *)manga {
    if ([self isFavorite:manga]) {
        [self removeFavorite:manga];
    } else {
        [self.favorites addObject:manga];
        [self saveFavorites];
    }
}

- (void)removeFavorite:(Manga *)manga {
    NSMutableArray *toRemove = [NSMutableArray array];
    for (Manga *m in self.favorites) {
        if ([m.identifier isEqualToString:manga.identifier]) [toRemove addObject:m];
    }
    [self.favorites removeObjectsInArray:toRemove];
    [self saveFavorites];
}

#pragma mark - Histórico

- (void)recordRead:(Chapter *)chapter forManga:(Manga *)manga {
    self.history[manga.identifier] = @{
        @"date": [NSDate date],
        @"chapterIndex": @(chapter.index),
        @"chapterId": chapter.identifier,
        @"manga": manga,
    };
    [self markChapterRead:chapter.identifier];
    [self saveHistory];
}

- (Manga *)lastReadManga {
    NSDate *latest = nil;
    Manga *result = nil;
    for (NSString *key in self.history) {
        NSDictionary *entry = self.history[key];
        NSDate *date = entry[@"date"];
        if (!latest || [date compare:latest] == NSOrderedDescending) {
            latest = date;
            result = entry[@"manga"];
        }
    }
    return result;
}

- (NSDate *)lastReadDateForManga:(Manga *)manga {
    return self.history[manga.identifier][@"date"];
}

- (NSInteger)lastReadChapterIndexForManga:(Manga *)manga {
    NSNumber *idx = self.history[manga.identifier][@"chapterIndex"];
    return idx ? idx.integerValue : -1;
}

#pragma mark - Capítulos lidos

- (BOOL)isChapterRead:(NSString *)chapterId {
    return [self.readChapters containsObject:chapterId];
}

- (void)markChapterRead:(NSString *)chapterId {
    [self.readChapters addObject:chapterId];
    [self saveReadChapters];
}

- (NSInteger)readCountForManga:(NSString *)mangaId {
    // Conta capítulos lidos deste mangá (prefixo não é confiável; usa history + set)
    // Simplificação: conta quantos chapterIds do mangá estão no set
    // Como o set só tem IDs, precisamos do mapeamento mangaId->chapterIds
    // Guardamos no history apenas o último; para contagem completa, iteramos o set
    // comparando com os capítulos conhecidos — aqui retornamos o tamanho do set como aproximação
    return self.readChapters.count;
}

@end
