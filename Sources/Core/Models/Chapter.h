#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Chapter : NSObject <NSCopying, NSCoding>

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *mangaIdentifier;
@property (nonatomic, copy, readonly) NSString *sourceIdentifier;
@property (nonatomic, assign, readonly) NSInteger index;
@property (nonatomic, copy, readonly) NSArray<NSString *> *pageURLs;
@property (nonatomic, strong, readonly) NSDate *dateUploaded;
@property (nonatomic, assign, readonly) BOOL isRead;
@property (nonatomic, assign, readonly) BOOL isDownloaded;
@property (nonatomic, copy, nullable) NSString *volume;
@property (nonatomic, copy, nullable) NSString *chapterNumber;
@property (nonatomic, copy, nullable) NSString *languageCode;
@property (nonatomic, assign) NSInteger pageCount;

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
                    languageCode:(nullable NSString *)languageCode;

+ (instancetype)chapterWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end

NS_ASSUME_NONNULL_END