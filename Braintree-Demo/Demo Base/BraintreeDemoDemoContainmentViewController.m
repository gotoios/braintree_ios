#import "BraintreeDemoDemoContainmentViewController.h"

#import <InAppSettingsKit/IASKAppSettingsViewController.h>
#import <InAppSettingsKit/IASKSettingsReader.h>
#import <PureLayout/PureLayout.h>
#import <BraintreeCore/BraintreeCore.h>

#import "BraintreeDemoMerchantAPI.h"
#import "BraintreeDemoBaseViewController.h"
#import "BraintreeDemoIntegrationViewController.h"
#import "BraintreeDemoSlideNavigationController.h"
#import "BraintreeDemoSettings.h"

@interface BraintreeDemoDemoContainmentViewController () <IASKSettingsDelegate, SlideNavigationControllerDelegate, IntegrationViewControllerDelegate>
@property (nonatomic, strong) UIBarButtonItem *statusItem;
@property (nonatomic, strong) id <BTTokenized> latestTokenizedPayment;
@property (nonatomic, strong) BraintreeDemoBaseViewController *currentDemoViewController;
@property (nonatomic, strong) UIViewController *rightMenu;
@end

@implementation BraintreeDemoDemoContainmentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupToolbar];
    [self reloadIntegration];
    [self setupRightMenu];
}

- (void)setupToolbar {
    UIBarButtonItem *flexSpaceLeft = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
    UIBarButtonItem *flexSpaceRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                    target:nil
                                                                                    action:nil];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.numberOfLines = 0;
    [button setTitle:@"Ready" forState:UIControlStateNormal];
    [button.titleLabel setTextColor:[UIColor whiteColor]];
    [button addTarget:self action:@selector(tappedStatus) forControlEvents:UIControlEventTouchUpInside];
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.titleLabel.font = [UIFont systemFontOfSize:14];
    CGRect f = self.navigationController.navigationBar.frame;
    [button setFrame:CGRectMake(0, 0, f.size.width, f.size.height)];
    // Use custom view with button so the text can span multiple lines
    self.statusItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.statusItem.enabled = NO;
    self.toolbarItems = @[flexSpaceLeft, self.statusItem, flexSpaceRight];
}

- (void)setupRightMenu {
    BraintreeDemoIntegrationViewController *ivc = [[BraintreeDemoIntegrationViewController alloc] init];
    ivc.delegate = self;
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ivc];
    self.rightMenu = nc;
    [BraintreeDemoSlideNavigationController sharedInstance].rightMenu = self.rightMenu;
}

- (BOOL)slideNavigationControllerShouldDisplayRightMenu {
    return YES;
}


#pragma mark - UI Updates

- (void)setLatestTokenizedPayment:(id)latestPaymentMethodOrNonce {
    _latestTokenizedPayment = latestPaymentMethodOrNonce;

    if (latestPaymentMethodOrNonce) {
        self.statusItem.enabled = YES;
    }
}

- (void)updateStatus:(NSString *)status {
    [(UIButton *)self.statusItem.customView setTitle:status forState:UIControlStateNormal];
    NSLog(@"%@", ((UIButton *)self.statusItem.customView).titleLabel.text);
}


#pragma mark - UI Handlers

- (void)tappedStatus {
    NSLog(@"Tapped status!");

    if (self.latestTokenizedPayment) {
        NSString *nonce = self.latestTokenizedPayment.paymentMethodNonce;
        [self updateStatus:@"Creating Transaction…"];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [[BraintreeDemoMerchantAPI sharedService] makeTransactionWithPaymentMethodNonce:nonce
                                                                             completion:^(NSString *transactionId, NSError *error){
                                                                                 [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                                                                 self.latestTokenizedPayment = nil;
                                                                                 if (error) {
                                                                                     [self updateStatus:error.localizedDescription];
                                                                                 } else {
                                                                                     [self updateStatus:transactionId];
                                                                                 }
                                                                             }];
    }
}

- (IBAction)tappedRefresh {
    [self reloadIntegration];
}

- (IBAction)tappedSettings {
    IASKAppSettingsViewController *appSettingsViewController = [[IASKAppSettingsViewController alloc] init];
    appSettingsViewController.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:appSettingsViewController];
    [self presentViewController:nav animated:YES completion:nil];
}


#pragma mark - Demo Integration Lifecycle


- (void)reloadIntegration {
    if (self.currentDemoViewController) {
        [self.currentDemoViewController willMoveToParentViewController:nil];
        [self.currentDemoViewController removeFromParentViewController];
        [self.currentDemoViewController.view removeFromSuperview];
    }

    self.title = @"Braintree";

    if ([BraintreeDemoSettings useClientKey]) {
        [self updateStatus:@"Using Client Key"];

        // For now, we assume that if we're using a Client Key, then we're not using a Customer.
        NSString *clientKey;
        switch ([BraintreeDemoSettings currentEnvironment]) {
            case BraintreeDemoTransactionServiceEnvironmentSandboxBraintreeSampleMerchant:
                clientKey = @"sandbox_9dbg82cq_dcpspy2brwdjr3qn";
                break;
            case BraintreeDemoTransactionServiceEnvironmentProductionExecutiveSampleMerchant:
                // TODO: replace with production client key
                clientKey = @"production_testing_integration_merchant_id";
                break;
            case BraintreeDemoTransactionServiceEnvironmentCustomMerchant:
            default:
                clientKey = @"development_testing_integration_merchant_id";
                break;
        }

        self.currentDemoViewController = [self instantiateCurrentIntegrationViewControllerWithClientKey:clientKey];
        return;
    }

    [self updateStatus:@"Fetching Client Token…"];

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    [[BraintreeDemoMerchantAPI sharedService] createCustomerAndFetchClientTokenWithCompletion:^(NSString *clientToken, NSError *error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (error) {
            [self updateStatus:error.localizedDescription];
        } else {
            [self updateStatus:@"Using Client Token"];
            self.currentDemoViewController = [self instantiateCurrentIntegrationViewControllerWithClientToken:clientToken];
        }
    }];
}

- (void)setCurrentDemoViewController:(BraintreeDemoBaseViewController *)currentDemoViewController {
    _currentDemoViewController = currentDemoViewController;
    
    if (!_currentDemoViewController) {
        [self updateStatus:@"Demo not available"];
        return;
    }

    [self updateStatus:[NSString stringWithFormat:@"Presenting %@", NSStringFromClass([_currentDemoViewController class])]];
    _currentDemoViewController.progressBlock = [self progressBlock];
    _currentDemoViewController.completionBlock = [self completionBlock];
    
    [self containIntegrationViewController:_currentDemoViewController];
    
    self.title = _currentDemoViewController.title;
}

- (BraintreeDemoBaseViewController *)instantiateCurrentIntegrationViewControllerWithClientToken:(NSString *)clientToken {
    NSString *integrationName = [[NSUserDefaults standardUserDefaults] stringForKey:@"BraintreeDemoSettingsIntegration"];
    NSLog(@"Loading integration: %@", integrationName);

    Class integrationClass = NSClassFromString(integrationName);
    if (![integrationClass isSubclassOfClass:[BraintreeDemoBaseViewController class]]) {
        NSLog(@"%@ is not a valid BraintreeDemoBaseViewController", integrationName);
        return nil;
    }

    return [(BraintreeDemoBaseViewController *)[integrationClass alloc] initWithClientToken:clientToken];
}

- (BraintreeDemoBaseViewController *)instantiateCurrentIntegrationViewControllerWithClientKey:(NSString *)clientKey {
    NSString *integrationName = [[NSUserDefaults standardUserDefaults] stringForKey:@"BraintreeDemoSettingsIntegration"];
    NSLog(@"Loading integration: %@", integrationName);

    Class integrationClass = NSClassFromString(integrationName);
    if (![integrationClass isSubclassOfClass:[BraintreeDemoBaseViewController class]]) {
        NSLog(@"%@ is not a valid BraintreeDemoBaseViewController", integrationName);
        return nil;
    }

    return [(BraintreeDemoBaseViewController *)[integrationClass alloc] initWithClientKey:clientKey];
}

- (void)containIntegrationViewController:(UIViewController *)viewController {
    [self addChildViewController:viewController];

    [self.view addSubview:viewController.view];

    [viewController.view autoPinToTopLayoutGuideOfViewController:self withInset:0];
    [viewController.view autoPinToBottomLayoutGuideOfViewController:self withInset:0];
    [viewController.view autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [viewController.view autoPinEdgeToSuperviewEdge:ALEdgeTrailing];

    [viewController didMoveToParentViewController:self];
}


#pragma mark - Progress and Completion Blocks

- (void (^)(NSString *message))progressBlock {
    // This class is responsible for retaining the progress block
    static id block;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        block = ^(NSString *message){
            [self updateStatus:message];
        };
    });
    return block;
}

- (void (^)(id <BTTokenized> tokenized))completionBlock {
    // This class is responsible for retaining the completion block
    static id block;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        block = ^(id tokenized){
            self.latestTokenizedPayment = tokenized;
            [self updateStatus:[NSString stringWithFormat:@"Got a nonce. Tap to make a transaction."]];
        };
    });
    return block;
}


#pragma mark IASKSettingsDelegate

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender {
    [sender dismissViewControllerAnimated:YES completion:nil];
    [self reloadIntegration];
}

#pragma mark IntegrationViewControllerDelegate

- (void)integrationViewController:(__unused BraintreeDemoIntegrationViewController *)integrationViewController didChangeAppSetting:(__unused NSDictionary *)appSetting {
    [self reloadIntegration];
}

@end