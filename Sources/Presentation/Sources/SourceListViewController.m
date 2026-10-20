#import "SourceListViewController.h"

static NSString * const kCellIdentifier = @"SourceCell";

@implementation SourceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Sources", nil);
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
    [self.view addSubview:self.tableView];

    self.sources = @[
        @{ @"name": @"MangaDex", @"language": @"EN", @"enabled": @YES },
        @{ @"name": @"Manganato", @"language": @"EN", @"enabled": @YES },
        @{ @"name": @"Bato.to", @"language": @"EN", @"enabled": @NO },
    ];
    [self reloadData];
}

- (void)reloadData {
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sources.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier
                                                           forIndexPath:indexPath];
    NSDictionary *source = self.sources[indexPath.row];
    cell.textLabel.text = source[@"name"];
    cell.detailTextLabel.text = source[@"language"];
    cell.imageView.image = [UIImage systemImageNamed:@"book"];
    UISwitch *toggle = [[UISwitch alloc] init];
    toggle.on = [source[@"enabled"] boolValue];
    toggle.tag = indexPath.row;
    [toggle addTarget:self action:@selector(sourceToggled:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = toggle;
    return cell;
}

- (void)sourceToggled:(UISwitch *)sender {
    NSMutableDictionary *source = [self.sources[sender.tag] mutableCopy];
    source[@"enabled"] = @(sender.on);
    NSMutableArray *sources = [self.sources mutableCopy];
    sources[sender.tag] = source;
    self.sources = sources;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
