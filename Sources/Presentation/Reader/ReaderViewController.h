#import <UIKit/UIKit.h>

@class Chapter;
@class Manga;

NS_ASSUME_NONNULL_BEGIN

@interface ReaderViewController : UIViewController

- (instancetype)initWithChapter:(nullable Chapter *)chapter manga:(nullable Manga *)manga;

@end

NS_ASSUME_NONNULL_END
