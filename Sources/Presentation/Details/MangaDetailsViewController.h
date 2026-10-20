#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class Manga;

@interface MangaDetailsViewController : UIViewController

@property (nonatomic, copy, nullable) NSString *mangaTitle;
@property (nonatomic, strong, nullable) Manga *manga;

- (instancetype)initWithManga:(nullable Manga *)manga;

@end

NS_ASSUME_NONNULL_END
