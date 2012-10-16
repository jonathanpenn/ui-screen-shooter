#import "NLLanguageViewController.h"

@interface NLLanguageViewController ()
@property (weak, nonatomic) IBOutlet UILabel *languageControl;
@end

@implementation NLLanguageViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLocale *locale = [NSLocale currentLocale];
    NSString *language = [locale displayNameForKey:NSLocaleIdentifier value:[NSLocale preferredLanguages][0]];
    self.languageControl.text = language;
}

@end
