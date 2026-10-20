#import "MangaDexParser.h"
#import "Manga.h"
#import "Chapter.h"
#import "NSString+Extensions.h"
#import "NSDate+Extensions.h"

static NSString * const kAPIBase = @"https://api.mangadex.org";
static NSString * const kUploadsBase = @"https://uploads.mangadex.org";

@implementation MangaDexParser

+ (instancetype)sharedParser {
    static MangaDexParser *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

#pragma mark - Helpers

+ (NSString *)coverURLForMangaId:(NSString *)mangaId coverFileName:(NSString *)fileName {
    if (mangaId.length == 0 || fileName.length == 0) return nil;
    return [NSString stringWithFormat:@"%@/covers/%@/%@", kUploadsBase, mangaId, fileName];
}

+ (NSDictionary *)jsonFromData:(NSData *)data error:(NSError **)error {
    if (!data) return nil;
    NSError *jsonError = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    if (jsonError && error) *error = jsonError;
    return [obj isKindOfClass:[NSDictionary class]] ? obj : nil;
}

+ (NSString *)titleFromTitles:(NSDictionary *)titles {
    if (![titles isKindOfClass:[NSDictionary class]]) return nil;
    // Prioridade: en > ja-ro > ko-ro > primeira disponível
    NSString *en = titles[@"en"];
    if (en.length > 0) return en;
    NSString *jaRo = titles[@"ja-ro"];
    if (jaRo.length > 0) return jaRo;
    NSString *koRo = titles[@"ko-ro"];
    if (koRo.length > 0) return koRo;
    for (NSString *key in titles) {
        NSString *val = titles[key];
        if ([val isKindOfClass:[NSString class]] && val.length > 0) return val;
    }
    return nil;
}

+ (NSString *)fileNameFromRelationships:(NSArray *)relationships type:(NSString *)type {
    for (NSDictionary *rel in relationships) {
        if (![rel isKindOfClass:[NSDictionary class]]) continue;
        if (![rel[@"type"] isEqualToString:type]) continue;
        NSDictionary *attrs = rel[@"attributes"];
        NSString *fileName = attrs[@"fileName"];
        if (fileName.length > 0) return fileName;
    }
    return nil;
}

+ (NSString *)authorNameFromRelationships:(NSArray *)relationships type:(NSString *)type {
    for (NSDictionary *rel in relationships) {
        if (![rel isKindOfClass:[NSDictionary class]]) continue;
        if (![rel[@"type"] isEqualToString:type]) continue;
        NSDictionary *attrs = rel[@"attributes"];
        NSString *name = attrs[@"name"];
        if (name.length > 0) return name;
    }
    return nil;
}

+ (MangaStatus)statusFromString:(NSString *)str {
    if ([str isEqualToString:@"ongoing"]) return MangaStatusOngoing;
    if ([str isEqualToString:@"completed"]) return MangaStatusCompleted;
    if ([str isEqualToString:@"hiatus"]) return MangaStatusHiatus;
    if ([str isEqualToString:@"cancelled"]) return MangaStatusCancelled;
    return MangaStatusUnknown;
}

+ (void)GET:(NSString *)urlString completion:(void (^)(NSDictionary *json, NSError *error))completion {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        completion(nil, [NSError errorWithDomain:@"MangaDex" code:-1
                                        userInfo:@{NSLocalizedDescriptionKey: @"URL inválida"}]);
        return;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = 20.0;
    [request setValue:@"KotatsuIOS/1.0" forHTTPHeaderField:@"User-Agent"];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        if (http.statusCode != 200) {
            completion(nil, [NSError errorWithDomain:@"MangaDex" code:http.statusCode
                                            userInfo:@{NSLocalizedDescriptionKey:
                                                       [NSString stringWithFormat:@"HTTP %ld", (long)http.statusCode]}]);
            return;
        }
        NSDictionary *json = [self jsonFromData:data error:nil];
        if (!json) {
            completion(nil, [NSError errorWithDomain:@"MangaDex" code:-2
                                            userInfo:@{NSLocalizedDescriptionKey: @"JSON inválido"}]);
            return;
        }
        completion(json, nil);
    }];
    [task resume];
}

#pragma mark - Manga list (popular / search)

+ (void)fetchMangaListWithURL:(NSString *)urlString
                   completion:(void (^)(NSArray<Manga *> *mangas, BOOL hasMore, NSError *error))completion {
    [self GET:urlString completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            completion(nil, NO, error);
            return;
        }
        NSArray *data = json[@"data"];
        if (![data isKindOfClass:[NSArray class]]) {
            completion(@[], NO, nil);
            return;
        }
        NSMutableArray<Manga *> *mangas = [NSMutableArray array];
        for (NSDictionary *item in data) {
            if (![item isKindOfClass:[NSDictionary class]]) continue;
            NSDictionary *attrs = item[@"attributes"];
            if (![attrs isKindOfClass:[NSDictionary class]]) continue;

            NSString *identifier = item[@"id"];
            NSString *title = [self titleFromTitles:attrs[@"title"]];
            if (identifier.length == 0 || title.length == 0) continue;

            // Capa
            NSString *coverFile = [self fileNameFromRelationships:item[@"relationships"] type:@"cover_art"];
            NSString *coverURL = [self coverURLForMangaId:identifier coverFileName:coverFile];

            // Autor
            NSString *author = [self authorNameFromRelationships:item[@"relationships"] type:@"author"];

            // Tags (gêneros)
            NSMutableArray<NSString *> *genres = [NSMutableArray array];
            for (NSDictionary *tag in attrs[@"tags"]) {
                NSString *tagName = [self titleFromTitles:tag[@"attributes"][@"name"]];
                if (tagName.length > 0) [genres addObject:tagName];
            }

            // Alt titles
            NSString *altTitle = nil;
            for (NSDictionary *alt in attrs[@"altTitles"]) {
                NSString *en = alt[@"en"];
                if (en.length > 0) { altTitle = en; break; }
            }

            Manga *manga = [[Manga alloc] initWithIdentifier:identifier
                                                        title:title
                                             sourceIdentifier:@"mangadex"
                                                     coverURL:coverURL
                                                      author:author
                                                      artist:[self authorNameFromRelationships:item[@"relationships"] type:@"artist"]
                                                  description:attrs[@"description"][@"en"]
                                                       genres:genres
                                                         tags:@[]
                                                       status:[self statusFromString:attrs[@"status"]]
                                                contentRating:ContentRatingSafe
                                                 chapterCount:0];
            manga.alternativeTitle = altTitle;
            [mangas addObject:manga];
        }
        BOOL hasMore = [json[@"total"] integerValue] > ([json[@"offset"] integerValue] + mangas.count);
        completion(mangas, hasMore, nil);
    }];
}

- (void)fetchPopularWithPage:(NSInteger)page
                  completion:(void (^)(NSArray<Manga *> *mangas, BOOL hasMore, NSError *error))completion {
    NSInteger limit = 20;
    NSInteger offset = (page - 1) * limit;
    NSString *url = [NSString stringWithFormat:
        // Paridade Kotlin: contentRating default = safe+suggestive+erotica+pornographic
        @"%@/manga?limit=%ld&offset=%ld&order[followedCount]=desc&includes[]=cover_art&includes[]=author&includes[]=artist&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica&contentRating[]=pornographic",
        kAPIBase, (long)limit, (long)offset];
    [MangaDexParser fetchMangaListWithURL:url completion:completion];
}

- (void)searchWithQuery:(NSString *)query
                   page:(NSInteger)page
             completion:(void (^)(NSArray<Manga *> *mangas, BOOL hasMore, NSError *error))completion {
    NSInteger limit = 20;
    NSInteger offset = (page - 1) * limit;
    NSString *encoded = [query urlEncodedString];
    NSString *url = [NSString stringWithFormat:
        @"%@/manga?limit=%ld&offset=%ld&title=%@&includes[]=cover_art&includes[]=author&includes[]=artist&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica&contentRating[]=pornographic",
        kAPIBase, (long)limit, (long)offset, encoded];
    [MangaDexParser fetchMangaListWithURL:url completion:completion];
}

#pragma mark - Details

- (void)fetchDetailsWithIdentifier:(NSString *)identifier
                        completion:(void (^)(Manga *manga, NSError *error))completion {
    NSString *url = [NSString stringWithFormat:
        @"%@/manga/%@?includes[]=cover_art&includes[]=author&includes[]=artist", kAPIBase, identifier];
    [MangaDexParser GET:url completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        NSDictionary *data = json[@"data"];
        NSDictionary *attrs = data[@"attributes"];
        if (!attrs) { completion(nil, nil); return; }

        NSString *title = [MangaDexParser titleFromTitles:attrs[@"title"]];
        NSString *coverFile = [MangaDexParser fileNameFromRelationships:data[@"relationships"] type:@"cover_art"];
        NSString *coverURL = [MangaDexParser coverURLForMangaId:identifier coverFileName:coverFile];

        NSMutableArray<NSString *> *genres = [NSMutableArray array];
        for (NSDictionary *tag in attrs[@"tags"]) {
            NSString *tagName = [MangaDexParser titleFromTitles:tag[@"attributes"][@"name"]];
            if (tagName.length > 0) [genres addObject:tagName];
        }

        Manga *manga = [[Manga alloc] initWithIdentifier:identifier
                                                    title:title ?: @""
                                         sourceIdentifier:@"mangadex"
                                                 coverURL:coverURL
                                                  author:[MangaDexParser authorNameFromRelationships:data[@"relationships"] type:@"author"]
                                                  artist:[MangaDexParser authorNameFromRelationships:data[@"relationships"] type:@"artist"]
                                              description:attrs[@"description"][@"en"]
                                                   genres:genres
                                                     tags:@[]
                                                   status:[MangaDexParser statusFromString:attrs[@"status"]]
                                            contentRating:ContentRatingSafe
                                             chapterCount:0];
        completion(manga, nil);
    }];
}

#pragma mark - Chapters

- (void)fetchChaptersForManga:(NSString *)mangaIdentifier
                   completion:(void (^)(NSArray<Chapter *> *chapters, NSError *error))completion {
    // Paridade com Kotlin: order[volume]=asc&order[chapter]=asc, todos os contentRatings
    NSString *url = [NSString stringWithFormat:
        @"%@/manga/%@/feed?limit=500&includes[]=scanlation_group&order[volume]=asc&order[chapter]=asc&offset=0&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica&contentRating[]=pornographic",
        kAPIBase, mangaIdentifier];
    [MangaDexParser GET:url completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        NSArray *data = json[@"data"];
        if (![data isKindOfClass:[NSArray class]]) { completion(@[], nil); return; }

        NSMutableArray<Chapter *> *chapters = [NSMutableArray array];
        for (NSDictionary *item in data) {
            if (![item isKindOfClass:[NSDictionary class]]) continue;
            NSDictionary *attrs = item[@"attributes"];
            if (![attrs isKindOfClass:[NSDictionary class]]) continue;

            NSString *chapterId = item[@"id"];
            if (chapterId.length == 0) continue;

            // Páginas externas não são suportadas
            if ([attrs[@"externalUrl"] isKindOfClass:[NSString class]]) continue;

            // NSNull-safe: campos podem vir como [NSNull null] em capítulos oficiais
            id rawTitle = attrs[@"title"];
            NSString *title = ([rawTitle isKindOfClass:[NSString class]]) ? rawTitle : nil;
            id rawChapter = attrs[@"chapter"];
            NSString *chapterNum = ([rawChapter isKindOfClass:[NSString class]]) ? rawChapter : @"";
            id rawVolume = attrs[@"volume"];
            NSString *volumeStr = ([rawVolume isKindOfClass:[NSString class]]) ? rawVolume : @"";
            id rawLang = attrs[@"translatedLanguage"];
            NSString *lang = ([rawLang isKindOfClass:[NSString class]]) ? rawLang : @"";

            NSString *displayTitle = title.length > 0
                ? [NSString stringWithFormat:@"Ch. %@ — %@", chapterNum, title]
                : [NSString stringWithFormat:@"Chapter %@", chapterNum];

            NSDate *uploadDate = nil;
            id rawDate = attrs[@"publishAt"];
            NSString *dateStr = ([rawDate isKindOfClass:[NSString class]]) ? rawDate : nil;
            if (dateStr.length > 0) {
                uploadDate = [NSDate dateFromISO8601String:dateStr];
            }

            double index = 0.0;
            if ([rawChapter isKindOfClass:[NSString class]]) index = [chapterNum doubleValue];

            Chapter *chapter = [[Chapter alloc] initWithIdentifier:chapterId
                                                              title:displayTitle
                                                   mangaIdentifier:mangaIdentifier
                                                  sourceIdentifier:@"mangadex"
                                                             index:index
                                                          pageURLs:@[]
                                                     dateUploaded:uploadDate
                                                            isRead:NO
                                                      isDownloaded:NO
                                                            volume:volumeStr
                                                     chapterNumber:chapterNum
                                                      languageCode:lang];
            [chapters addObject:chapter];
        }
        completion(chapters, nil);
    }];
}

#pragma mark - Pages

- (void)fetchPageURLsForChapter:(Chapter *)chapter
                     completion:(void (^)(NSArray<NSString *> *pageURLs, NSError *error))completion {
    NSString *url = [NSString stringWithFormat:@"%@/at-home/server/%@?forcePort443=false", kAPIBase, chapter.identifier];
    [MangaDexParser GET:url completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        NSString *baseURL = json[@"baseUrl"];
        NSDictionary *chapterData = json[@"chapter"];
        if (baseURL.length == 0 || ![chapterData isKindOfClass:[NSDictionary class]]) {
            completion(@[], nil);
            return;
        }
        NSString *hash = chapterData[@"hash"];
        NSArray *data = chapterData[@"data"];
        if (hash.length == 0 || ![data isKindOfClass:[NSArray class]]) {
            completion(@[], nil);
            return;
        }
        NSMutableArray<NSString *> *pages = [NSMutableArray array];
        for (NSString *pageFile in data) {
            NSString *pageURL = [NSString stringWithFormat:@"%@/data/%@/%@", baseURL, hash, pageFile];
            [pages addObject:pageURL];
        }
        completion(pages, nil);
    }];
}

@end
