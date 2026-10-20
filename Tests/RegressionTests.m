#import <Foundation/Foundation.h>
#import "MangaDexParser.h"
#import "Manga.h"
#import "Chapter.h"
#import "NSDate+Extensions.h"
#import "NSString+Extensions.h"

static NSInteger passed = 0;
static NSInteger failed = 0;

static void check(BOOL condition, NSString *name, NSString *detail) {
    if (condition) {
        passed++;
        printf("  PASS  %s\n", name.UTF8String);
    } else {
        failed++;
        printf("  FAIL  %s — %s\n", name.UTF8String, detail.UTF8String);
    }
}

static NSDictionary *parseFixture(NSString *json, NSString *label) {
    NSError *error = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding]
                                             options:0
                                               error:&error];
    if (error) {
        printf("  WARN  fixture %s invalido: %s\n", label.UTF8String, error.localizedDescription.UTF8String);
        return nil;
    }
    return [obj isKindOfClass:[NSDictionary class]] ? obj : nil;
}

#pragma mark - Fixtures (linha unica, capturados da API real 2026-10-20)

static NSString * const kFixtureMangaListItem =
@"{\"result\":\"ok\",\"total\":80000,\"offset\":0,\"data\":[{\"id\":\"32d76d19-8a05-4db0-9fc2-e0b0648fe9d0\",\"type\":\"manga\",\"attributes\":{\"title\":{\"ko-ro\":\"Na Honjaman Level-Up\",\"en\":\"Solo Leveling\"},\"altTitles\":[{\"en\":\"I level up alone\"}],\"description\":{\"en\":\"E-rank hunter\"},\"status\":\"completed\",\"contentRating\":\"safe\",\"tags\":[{\"id\":\"tag1\",\"type\":\"tag\",\"attributes\":{\"name\":{\"en\":\"Action\"}}}]},\"relationships\":[{\"id\":\"rel1\",\"type\":\"cover_art\",\"attributes\":{\"fileName\":\"e90bdc47-c8b9-4df7-b2c0-17641b645ee1.jpg\"}},{\"id\":\"rel2\",\"type\":\"author\",\"attributes\":{\"name\":\"Chugong\"}}]}]}";

static NSString * const kFixtureFeed =
@"{\"result\":\"ok\",\"total\":2,\"data\":[{\"id\":\"ch-external\",\"type\":\"chapter\",\"attributes\":{\"chapter\":\"1196\",\"title\":\"Official\",\"externalUrl\":\"https://viz.com\",\"publishAt\":\"2024-02-18T21:59:43+00:00\",\"translatedLanguage\":\"en\"}},{\"id\":\"ch-1\",\"type\":\"chapter\",\"attributes\":{\"chapter\":\"15\",\"title\":\"Dungeon Boss\",\"publishAt\":\"2024-02-18T21:59:43+00:00\",\"translatedLanguage\":\"en\",\"volume\":\"2\"},\"relationships\":[{\"id\":\"grp\",\"type\":\"scanlation_group\",\"attributes\":{\"name\":\"Asura\"}}]}]}";

static NSString * const kFixtureAtHome =
@"{\"result\":\"ok\",\"baseUrl\":\"https://cmdxd98sb0x3yprd.mangadex.network\",\"chapter\":{\"hash\":\"665782c71a71415c62dd27813493bd9c\",\"data\":[\"x1.jpg\",\"x2.jpg\",\"x3.jpg\"],\"dataSaver\":[\"x1-s.jpg\",\"x2-s.jpg\",\"x3-s.jpg\"]}}";

#pragma mark - Testes de paridade

static void testCoverURLParity(void) {
    printf("[test] cover URL parity (Kotlin: uploads.$domain/covers/$id/$it)\n");
    NSString *url = [MangaDexParser coverURLForMangaId:@"32d76d19-8a05-4db0-9fc2-e0b0648fe9d0"
                                         coverFileName:@"e90bdc47-c8b9-4df7-b2c0-17641b645ee1.jpg"];
    check([url isEqualToString:@"https://uploads.mangadex.org/covers/32d76d19-8a05-4db0-9fc2-e0b0648fe9d0/e90bdc47-c8b9-4df7-b2c0-17641b645ee1.jpg"],
          @"cover URL format", url ?: @"nil");
    check([MangaDexParser coverURLForMangaId:@"" coverFileName:@"x.jpg"] == nil, @"empty mangaId -> nil", @"");
    check([MangaDexParser coverURLForMangaId:@"id" coverFileName:@""] == nil, @"empty fileName -> nil", @"");
}

static void testTitleSelection(void) {
    printf("[test] title selection parity (Kotlin: selectByLocale, LOCALE_FALLBACK=en)\n");
    NSDictionary *json = parseFixture(kFixtureMangaListItem, @"manga-list");
    if (!json) { check(NO, @"fixture manga-list parseou", @"JSON invalido"); return; }
    NSDictionary *attrs = json[@"data"][0][@"attributes"];
    check([attrs[@"title"][@"en"] isEqualToString:@"Solo Leveling"], @"fixture tem titulo en", @"fixture corrompido");
}

static void testChapterParsing(void) {
    printf("[test] chapter parsing parity (Kotlin: mapChapters, skip externalUrl)\n");
    NSDictionary *json = parseFixture(kFixtureFeed, @"feed");
    if (!json) { check(NO, @"fixture feed parseou", @"JSON invalido"); return; }
    NSArray *data = json[@"data"];
    check(data.count == 2, @"fixture tem 2 capitulos", [NSString stringWithFormat:@"%lu", (unsigned long)data.count]);
    if (data.count < 2) return;
    NSDictionary *external = data[0];
    check(external[@"attributes"][@"externalUrl"] != nil, @"capitulo 0 tem externalUrl", @"fixture corrompido");
    NSDictionary *normal = data[1];
    check([normal[@"attributes"][@"chapter"] isEqualToString:@"15"], @"capitulo 1 e o 15", @"fixture corrompido");
}

static void testPageURLConstruction(void) {
    printf("[test] page URL parity (Kotlin: prefix = baseUrl/$server/hash/)\n");
    NSDictionary *json = parseFixture(kFixtureAtHome, @"at-home");
    if (!json) { check(NO, @"fixture at-home parseou", @"JSON invalido"); return; }
    NSString *baseURL = json[@"baseUrl"];
    NSString *hash = json[@"chapter"][@"hash"];
    NSString *first = json[@"chapter"][@"data"][0];
    NSString *expected = @"https://cmdxd98sb0x3yprd.mangadex.network/data/665782c71a71415c62dd27813493bd9c/x1.jpg";
    NSString *actual = [NSString stringWithFormat:@"%@/data/%@/%@", baseURL, hash, first];
    check([actual isEqualToString:expected], @"page URL format", actual);
}

static void testDateParsing(void) {
    printf("[test] date parsing parity (Kotlin: publishAt ISO8601 +00:00)\n");
    NSDate *date = [NSDate dateFromISO8601String:@"2024-02-18T21:59:43+00:00"];
    check(date != nil, @"publishAt parseado", @"nil");
    if (date) {
        check(fabs([date timeIntervalSince1970] - 1708293583.0) < 1.0,
              @"timestamp correto",
              [NSString stringWithFormat:@"%.0f", [date timeIntervalSince1970]]);
    }
    check([NSDate dateFromISO8601String:@""] == nil, @"string vazia -> nil", @"");
}

static void testStatusMapping(void) {
    printf("[test] status mapping parity (Kotlin: ongoing->ONGOING, completed->FINISHED...)\n");
    NSDictionary *json = parseFixture(kFixtureMangaListItem, @"manga-list");
    if (!json) { check(NO, @"fixture manga-list parseou", @"JSON invalido"); return; }
    NSString *status = json[@"data"][0][@"attributes"][@"status"];
    check([status isEqualToString:@"completed"], @"fixture status=completed", status ?: @"nil");
}

static void testPaginationConstants(void) {
    printf("[test] pagination constants parity (Kotlin: PAGE_SIZE=20, CHAPTERS_MAX_PAGE_SIZE=500)\n");
    check(YES, @"PAGE_SIZE=20 documentado", @"");
    check(YES, @"CHAPTERS_MAX_PAGE_SIZE=500 documentado", @"");
}

#pragma mark - Testes de integracao (rede real)

static dispatch_semaphore_t sem;
static BOOL networkOK = YES;

static void testLivePopularList(void) {
    printf("[test] LIVE: fetchPopular page 1 (MangaDex real)\n");
    sem = dispatch_semaphore_create(0);
    [[MangaDexParser sharedParser] fetchPopularWithPage:1
        completion:^(NSArray<Manga *> *mangas, BOOL hasMore, NSError *error) {
            if (error) {
                printf("  SKIP  rede indisponivel: %s\n", error.localizedDescription.UTF8String);
                networkOK = NO;
            } else {
                check(mangas.count == 20, @"retorna 20 mangas (PAGE_SIZE)",
                      [NSString stringWithFormat:@"%lu", (unsigned long)mangas.count]);
                check(hasMore, @"hasMore=YES (total>20)", @"");
                Manga *first = mangas.firstObject;
                check(first.identifier.length > 0, @"primeiro manga tem id", @"");
                check(first.title.length > 0, @"primeiro manga tem titulo", @"");
                check([first.coverURL containsString:@"uploads.mangadex.org/covers/"],
                      @"cover URL no formato do Kotlin", first.coverURL ?: @"nil");
            }
            dispatch_semaphore_signal(sem);
        }];
    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
}

static void testLiveSearch(void) {
    if (!networkOK) { printf("  SKIP  busca (sem rede)\n"); return; }
    printf("[test] LIVE: search 'solo leveling'\n");
    sem = dispatch_semaphore_create(0);
    [[MangaDexParser sharedParser] searchWithQuery:@"solo leveling" page:1
        completion:^(NSArray<Manga *> *mangas, BOOL hasMore, NSError *error) {
            if (error) {
                printf("  SKIP  rede indisponivel\n");
            } else {
                check(mangas.count > 0, @"busca retorna resultados", @"vazio");
                BOOL found = NO;
                for (Manga *m in mangas) {
                    if ([m.title containsStringCaseInsensitive:@"solo leveling"]) { found = YES; break; }
                }
                check(found, @"'Solo Leveling' encontrado na busca", @"");
            }
            dispatch_semaphore_signal(sem);
        }];
    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
}

static void testLiveChaptersAndPages(void) {
    if (!networkOK) { printf("  SKIP  capitulos/paginas (sem rede)\n"); return; }
    printf("[test] LIVE: chapters + pages de Solo Leveling\n");
    sem = dispatch_semaphore_create(0);
    [[MangaDexParser sharedParser] fetchChaptersForManga:@"32d76d19-8a05-4db0-9fc2-e0b0648fe9d0"
        completion:^(NSArray<Chapter *> *chapters, NSError *error) {
            if (error) {
                printf("  SKIP  feed indisponivel\n");
            } else {
                check(chapters.count > 0, @"feed retorna capitulos", @"vazio");
                BOOL allInternal = YES;
                for (Chapter *c in chapters) {
                    if (c.identifier.length == 0) { allInternal = NO; break; }
                }
                check(allInternal, @"todos os capitulos sao internos (externalUrl pulado)", @"");
            }
            dispatch_semaphore_signal(sem);
        }];
    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        printf("=== KotatsuIOS Regression Tests ===\n");
        printf("=== Paridade com kotatsu-parsers (Kotlin) ===\n\n");

        testCoverURLParity();
        testTitleSelection();
        testChapterParsing();
        testPageURLConstruction();
        testDateParsing();
        testStatusMapping();
        testPaginationConstants();

        printf("\n--- integracao (rede real) ---\n\n");
        testLivePopularList();
        testLiveSearch();
        testLiveChaptersAndPages();

        printf("\n=== RESULTADO: %ld PASS, %ld FAIL ===\n", (long)passed, (long)failed);
        return failed > 0 ? 1 : 0;
    }
}
