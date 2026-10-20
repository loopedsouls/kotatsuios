#import "ReaderViewController.h"
#import "Chapter.h"
#import "Manga.h"
#import "MangaDexParser.h"
#import "FavoritesStore.h"

@interface ReaderViewController () <UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) Chapter *chapter;
@property (nonatomic, strong) Manga *manga;
@property (nonatomic, strong) NSArray<NSString *> *pageURLs;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIView *> *loadedPages;
@property (nonatomic, assign) NSInteger currentPage;
@end

@implementation ReaderViewController

- (instancetype)initWithChapter:(nullable Chapter *)chapter manga:(nullable Manga *)manga {
    self = [super init];
    if (self) {
        _chapter = chapter;
        _manga = manga;
        _loadedPages = [NSMutableDictionary dictionary];
        _pageURLs = @[];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.title = self.chapter.title ?: NSLocalizedString(@"Reader", nil);

    [self setupScrollView];
    [self setupPageControl];
    [self setupStatusBar];

    if (self.chapter.identifier.length > 0) {
        [self loadPages];
        if (self.manga) {
            [[FavoritesStore sharedStore] recordRead:self.chapter forManga:self.manga];
        }
    } else {
        self.statusLabel.text = NSLocalizedString(@"No chapter selected.", nil);
    }
}

- (void)setupScrollView {
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = 4.0;
    self.scrollView.delegate = self;
    [self.view addSubview:self.scrollView];
}

- (void)setupPageControl {
    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.numberOfPages = 1;
    self.pageControl.currentPage = 0;
    self.pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    self.pageControl.pageIndicatorTintColor = [UIColor darkGrayColor];
    self.pageControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.pageControl];

    [NSLayoutConstraint activateConstraints:@[
        [self.pageControl.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.pageControl.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-8.0],
    ]];
}

- (void)setupStatusBar {
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = NSLocalizedString(@"Loading…", nil);
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.spinner.color = [UIColor whiteColor];
    self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
    self.spinner.hidesWhenStopped = YES;
    [self.view addSubview:self.spinner];

    [NSLayoutConstraint activateConstraints:@[
        [self.statusLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.statusLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.statusLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:20.0],
        [self.statusLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20.0],

        [self.spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.spinner.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:12.0],
    ]];
    [self.spinner startAnimating];
}

#pragma mark - Loading

- (void)loadPages {
    __weak typeof(self) weakSelf = self;
    [[MangaDexParser sharedParser] fetchPageURLsForChapter:self.chapter
        completion:^(NSArray<NSString *> *pageURLs, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                if (error || pageURLs.count == 0) {
                    strongSelf.statusLabel.text = error.localizedDescription
                        ?: NSLocalizedString(@"No pages available for this chapter.", nil);
                    [strongSelf.spinner stopAnimating];
                    return;
                }
                [strongSelf.spinner stopAnimating];
                strongSelf.statusLabel.hidden = YES;
                strongSelf.pageURLs = pageURLs;
                strongSelf.pageControl.numberOfPages = pageURLs.count;
                [strongSelf layoutPages];
                [strongSelf loadVisiblePageImages];
            });
        }];
}

- (void)layoutPages {
    CGSize size = self.scrollView.bounds.size;
    self.scrollView.contentSize = CGSizeMake(size.width * self.pageURLs.count, size.height);
    for (NSInteger i = 0; i < self.pageURLs.count; i++) {
        UIView *pageView = self.loadedPages[@(i)];
        if (!pageView) {
            pageView = [[UIView alloc] initWithFrame:CGRectMake(i * size.width, 0, size.width, size.height)];
            pageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            pageView.backgroundColor = [UIColor blackColor];
            self.loadedPages[@(i)] = pageView;
            self.scrollView.userInteractionEnabled = YES;
            [self.scrollView addSubview:pageView];

            UIActivityIndicatorView *ps = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
            ps.color = [UIColor grayColor];
            ps.center = CGPointMake(size.width / 2.0, size.height / 2.0);
            ps.tag = 999;
            ps.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
                                  UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            [pageView addSubview:ps];
            [ps startAnimating];
        } else {
            pageView.frame = CGRectMake(i * size.width, 0, size.width, size.height);
        }
    }
}

- (void)loadVisiblePageImages {
    [self loadPageImageAtIndex:self.currentPage];
    if (self.currentPage + 1 < self.pageURLs.count) {
        [self loadPageImageAtIndex:self.currentPage + 1];
    }
}

- (void)loadPageImageAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.pageURLs.count) return;
    UIView *pageView = self.loadedPages[@(index)];
    if (!pageView || [pageView viewWithTag:100] != nil) return; // já carregada

    NSString *urlString = self.pageURLs[index];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;

    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error || data.length == 0) return;
            UIImage *image = [UIImage imageWithData:data];
            if (!image) return;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                UIView *pv = strongSelf.loadedPages[@(index)];
                if (!pv) return;

                UIImageView *iv = [[UIImageView alloc] initWithImage:image];
                iv.tag = 100;
                iv.contentMode = UIViewContentModeScaleAspectFit;
                iv.frame = pv.bounds;
                iv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [pv addSubview:iv];

                UIActivityIndicatorView *spinner = [pv viewWithTag:999];
                [spinner stopAnimating];
                spinner.hidden = YES;
            });
        }];
    [task resume];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.pageURLs.count == 0) return;
    NSInteger page = round(scrollView.contentOffset.x / scrollView.bounds.size.width);
    page = MAX(0, MIN(page, (NSInteger)self.pageURLs.count - 1));
    if (page != self.currentPage) {
        self.currentPage = page;
        self.pageControl.currentPage = page;
        [self loadVisiblePageImages];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    // Zoom na página visível
    UIView *pageView = self.loadedPages[@(self.currentPage)];
    return [pageView viewWithTag:100];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self layoutPages];
        CGPoint offset = CGPointMake(self.currentPage * size.width, 0);
        [self.scrollView setContentOffset:offset animated:NO];
    } completion:nil];
}

@end
