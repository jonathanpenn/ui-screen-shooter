#import "NLHelloViewController.h"
#import "NLLanguageViewController.h"

@interface NLHelloViewController ()
@property (weak, nonatomic) IBOutlet UIButton *button;
@end

@implementation NLHelloViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSString *greeting = NSLocalizedString(@"Hello", nil);
    [self.button setTitle:greeting forState:UIControlStateNormal];
}

@end
