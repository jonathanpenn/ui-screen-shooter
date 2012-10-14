#import "NLDetailViewController.h"

@interface NLDetailViewController ()
- (void)configureView;
@property (weak, nonatomic) IBOutlet UILabel *languageControl;
@end

@implementation NLDetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}

- (void)configureView
{
    if (self.detailItem) {
        self.detailDescriptionLabel.text = [self.detailItem description];
    }
    NSLocale *locale = [NSLocale currentLocale];
    NSString *language = [locale displayNameForKey:NSLocaleIdentifier value:[NSLocale preferredLanguages][0]];
    self.languageControl.text = language;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureView];
}

@end
