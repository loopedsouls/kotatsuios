#import "MangaDetailsViewController.h"
#import "Manga.h"
#import "Chapter.h"
#import "ReaderViewController.h"
#import "MangaDexParser.h"
#import "FavoritesStore.h"

static NSString * const kChapterCellIdentifier = @"ChapterCell";

@interface MangaDetailsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<Chapter *> *chapters;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *authorLabel;
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UILabel *chaptersHeaderLabel;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UIView *headerView;
@end

@implementation MangaDetailsViewController

- (instancetype)initWithManga:(nullable Manga *)manga {
    self = [super init];
    if (self) {
        _manga = manga;
        _mangaTitle = manga.title ?: NSLocalizedString(@"Manga", nil);
        _chapters = @[];
    }
    return self;
}

- (instancetype)init {
    return [self initWithManga:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.mangaTitle;
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    [self setupTableView];
    [self setupHeader];
    [self setupFavoriteButton];
    [self loadContent];
}

- (void)setupFavoriteButton {
    BOOL fav = [[FavoritesStore sharedStore] isFavorite:self.manga];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:(fav ? @"★" : @"☆")
                style:UIBarButtonItemStylePlain
               target:self
               action:@selector(toggleFavorite)];
    self.navigationItem.rightBarButtonItem.tintColor = fav
        ? [UIColor systemYellowColor]
        : [UIColor labelColor];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kChapterCellIdentifier];
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.1)];
    [self.view addSubview:self.tableView];
}

- (void)setupHeader {
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 220)];
    self.headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.headerView.backgroundColor = [UIColor secondarySystemBackgroundColor];

    self.coverImageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 16, 100, 150)];
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverImageView.clipsToBounds = YES;
    self.coverImageView.layer.cornerRadius = 8.0;
    self.coverImageView.backgroundColor = [UIColor tertiarySystemBackgroundColor];
    [self.headerView addSubview:self.coverImageView];

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(132, 16, self.view.bounds.size.width - 148, 44)];
    self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    self.titleLabel.textColor = [UIColor labelColor];
    self.titleLabel.numberOfLines = 2;
    [self.headerView addSubview:self.titleLabel];

    self.authorLabel = [[UILabel alloc] initWithFrame:CGRectMake(132, 64, self.view.bounds.size.width - 148, 20)];
    self.authorLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.authorLabel.textColor = [UIColor secondaryLabelColor];
    [self.headerView addSubview:self.authorLabel];

    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(132, 88, self.view.bounds.size.width - 148, 20)];
    self.statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.statusLabel.textColor = [UIColor secondaryLabelColor];
    [self.headerView addSubview:self.statusLabel];

    self.descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 176, self.view.bounds.size.width - 32, 40)];
    self.descriptionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.descriptionLabel.textColor = [UIColor secondaryLabelColor];
    self.descriptionLabel.numberOfLines = 2;
    [self.headerView addSubview:self.descriptionLabel];

    self.chaptersHeaderLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, 200, 44)];
    self.chaptersHeaderLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.chaptersHeaderLabel.text = NSLocalizedString(@"Chapters", nil);
    [self.headerView addSubview:self.chaptersHeaderLabel];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.spinner.frame = CGRectMake(self.view.bounds.size.width - 44, 12, 24, 24);
    self.spinner.hidesWhenStopped = YES;
    [self.headerView addSubview:self.spinner];

    self.tableView.tableHeaderView = self.headerView;
}

- (void)loadContent {
    if (!self.manga) return;

    self.titleLabel.text = self.manga.title;
    self.authorLabel.text = self.manga.author ?: @"";
    self.statusLabel.text = [self statusText];
    self.descriptionLabel.text = self.manga.descriptionText ?: @"";

    // Capa
    if (self.manga.coverURL.length > 0) {
        __weak typeof(self) weakSelf = self;
        NSURL *url = [NSURL URLWithString:self.manga.coverURL];
        if (url) {
            [[[NSURLSession sharedSession] dataTaskWithURL:url
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (error || data.length == 0) return;
                    UIImage *img = [UIImage imageWithData:data];
                    if (!img) return;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.coverImageView.image = img;
                    });
                }] resume];
        }
    }

    // Capítulos
    [self.spinner startAnimating];
    __weak typeof(self) weakSelf = self;
    [[MangaDexParser sharedParser] fetchChaptersForManga:self.manga.identifier
        completion:^(NSArray<Chapter *> *chapters, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                [strongSelf.spinner stopAnimating];
                if (error) {
                    strongSelf.chaptersHeaderLabel.text = NSLocalizedString(@"Failed to load chapters", nil);
                    return;
                }
                strongSelf.chapters = chapters;
                strongSelf.chaptersHeaderLabel.text = [NSString stringWithFormat:
                    NSLocalizedString(@"Chapters (%lu)", nil), (unsigned long)chapters.count];
                [strongSelf.tableView reloadData];
            });
        }];
}

- (NSString *)statusText {
    switch (self.manga.status) {
        case MangaStatusOngoing:   return NSLocalizedString(@"Ongoing", nil);
        case MangaStatusCompleted: return NSLocalizedString(@"Completed", nil);
        case MangaStatusHiatus:    return NSLocalizedString(@"Hiatus", nil);
        case MangaStatusCancelled: return NSLocalizedString(@"Cancelled", nil);
        default:                   return NSLocalizedString(@"Unknown status", nil);
    }
}

- (void)toggleFavorite {
    [[FavoritesStore sharedStore] toggleFavorite:self.manga];
    BOOL fav = [[FavoritesStore sharedStore] isFavorite:self.manga];
    self.navigationItem.rightBarButtonItem.title = fav ? @"★" : @"☆";
    self.navigationItem.rightBarButtonItem.tintColor = fav
        ? [UIColor systemYellowColor]
        : [UIColor labelColor];
}

- (void)loadChapters:(NSArray<Chapter *> *)chapters {
    self.chapters = chapters;
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.chapters.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kChapterCellIdentifier
                                                           forIndexPath:indexPath];
    Chapter *chapter = self.chapters[indexPath.row];
    cell.textLabel.text = chapter.title;
    cell.textLabel.numberOfLines = 2;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Chapter *chapter = self.chapters[indexPath.row];
    ReaderViewController *reader = [[ReaderViewController alloc] initWithChapter:chapter manga:self.manga];
    [self.navigationController pushViewController:reader animated:YES];
}

@end
