//
//  RootViewController.mm
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import <notify.h>

#import "HUDHelper.h"
#import "MainButton.h"
#import "MainApplication.h"
#import "HUDPresetPosition.h"
#import "RootViewController.h"
#import "UIApplication+Private.h"
#import "HUDRootViewController.h"

#define HUD_TRANSITION_DURATION 0.25

static BOOL _gShouldToggleHUDAfterLaunch = NO;
static const CGFloat _gTopButtonConstraintsConstantCompact = 46.f;
static const CGFloat _gTopButtonConstraintsConstantRegular = 28.f;
static const CGFloat _gTopButtonConstraintsConstantRegularPad = 46.f;
static const CGFloat _gAuthorLabelBottomConstraintConstantCompact = -20.f;
static const CGFloat _gAuthorLabelBottomConstraintConstantRegular = -80.f;

@implementation RootViewController {
    NSMutableDictionary *_userDefaults;
    MainButton *_mainButton;
    UIButton *_settingsButton;
    UIButton *_topLeftButton;
    UIButton *_topRightButton;
    UIButton *_topCenterButton;
    UIButton *_topCenterMostButton;
    UILabel *_authorLabel;
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;
    UILabel *_statusLabel;
    UIView *_statusIndicator;
    UIVisualEffectView *_previewCard;
    UILabel *_previewTitleLabel;
    UILabel *_previewValueLabel;
    UISegmentedControl *_displayModeControl;
    CAGradientLayer *_backgroundGradient;
    BOOL _supportsCenterMost;
    NSLayoutConstraint *_topLeftConstraint;
    NSLayoutConstraint *_topRightConstraint;
    NSLayoutConstraint *_topCenterConstraint;
    NSLayoutConstraint *_authorLabelBottomConstraint;
    BOOL _isRemoteHUDActive;
    HUDRootViewController *_localHUDRootViewController;  // Only for debugging
    UIImpactFeedbackGenerator *_impactFeedbackGenerator;
}

+ (void)setShouldToggleHUDAfterLaunch:(BOOL)flag
{
    _gShouldToggleHUDAfterLaunch = flag;
}

+ (BOOL)shouldToggleHUDAfterLaunch
{
    return _gShouldToggleHUDAfterLaunch;
}

- (BOOL)isHUDEnabled
{
    return IsHUDEnabled();
}

- (void)setHUDEnabled:(BOOL)enabled
{
    SetHUDEnabled(enabled);
}

- (void)registerNotifications
{
    int token;
    notify_register_dispatch(NOTIFY_RELOAD_APP, &token, dispatch_get_main_queue(), ^(int token) {
        [self loadUserDefaults:YES];
    });

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleHUDNotificationReceived:) name:kToggleHUDAfterLaunchNotificationName object:nil];
}

- (void)loadView
{
    CGRect bounds = UIScreen.mainScreen.bounds;

    self.view = [[UIView alloc] initWithFrame:bounds];
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    self.backgroundView = [[UIView alloc] initWithFrame:bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.backgroundColor = [UIColor systemBackgroundColor];
    [self.view addSubview:self.backgroundView];

    _backgroundGradient = [CAGradientLayer layer];
    _backgroundGradient.startPoint = CGPointMake(0.0, 0.0);
    _backgroundGradient.endPoint = CGPointMake(1.0, 1.0);
    [self.backgroundView.layer insertSublayer:_backgroundGradient atIndex:0];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.text = @"TrollSpeed";
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleLargeTitle];
    _titleLabel.adjustsFontForContentSizeCategory = YES;
    _titleLabel.textColor = [UIColor labelColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [_titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.backgroundView addSubview:_titleLabel];

    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.text = NSLocalizedString(@"Network speed and FPS, always in sight.", nil);
    _subtitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    _subtitleLabel.adjustsFontForContentSizeCategory = YES;
    _subtitleLabel.textColor = [UIColor secondaryLabelColor];
    _subtitleLabel.textAlignment = NSTextAlignmentCenter;
    _subtitleLabel.numberOfLines = 2;
    [_subtitleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.backgroundView addSubview:_subtitleLabel];

    UIBlurEffect *previewEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial];
    _previewCard = [[UIVisualEffectView alloc] initWithEffect:previewEffect];
    _previewCard.layer.cornerRadius = 22.0;
    _previewCard.layer.cornerCurve = kCACornerCurveContinuous;
    _previewCard.clipsToBounds = YES;
    _previewCard.accessibilityLabel = NSLocalizedString(@"HUD Preview", nil);
    [_previewCard setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.backgroundView addSubview:_previewCard];

    _previewTitleLabel = [[UILabel alloc] init];
    _previewTitleLabel.text = NSLocalizedString(@"HUD Preview", nil);
    _previewTitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    _previewTitleLabel.adjustsFontForContentSizeCategory = YES;
    _previewTitleLabel.textColor = [UIColor secondaryLabelColor];
    [_previewTitleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_previewCard.contentView addSubview:_previewTitleLabel];

    _previewValueLabel = [[UILabel alloc] init];
    _previewValueLabel.font = [UIFont monospacedDigitSystemFontOfSize:17.0 weight:UIFontWeightSemibold];
    _previewValueLabel.textColor = [UIColor labelColor];
    _previewValueLabel.textAlignment = NSTextAlignmentCenter;
    [_previewValueLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_previewCard.contentView addSubview:_previewValueLabel];

    _displayModeControl = [[UISegmentedControl alloc] initWithItems:@[
        NSLocalizedString(@"Speed", nil),
        NSLocalizedString(@"FPS", nil),
    ]];
    _displayModeControl.selectedSegmentIndex = [self displayMode] ? 1 : 0;
    _displayModeControl.accessibilityLabel = NSLocalizedString(@"Display Mode", nil);
    [_displayModeControl addTarget:self action:@selector(displayModeChanged:) forControlEvents:UIControlEventValueChanged];
    [_displayModeControl setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_previewCard.contentView addSubview:_displayModeControl];

    [NSLayoutConstraint activateConstraints:@[
        [_previewCard.centerXAnchor constraintEqualToAnchor:self.backgroundView.safeAreaLayoutGuide.centerXAnchor],
        [_previewCard.widthAnchor constraintGreaterThanOrEqualToConstant:280.0f],
        [_previewCard.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.backgroundView.safeAreaLayoutGuide.leadingAnchor constant:24.0f],
        [_previewCard.trailingAnchor constraintLessThanOrEqualToAnchor:self.backgroundView.safeAreaLayoutGuide.trailingAnchor constant:-24.0f],
        [_previewCard.heightAnchor constraintGreaterThanOrEqualToConstant:126.0f],
        [_previewTitleLabel.topAnchor constraintEqualToAnchor:_previewCard.contentView.topAnchor constant:14.0f],
        [_previewTitleLabel.centerXAnchor constraintEqualToAnchor:_previewCard.contentView.centerXAnchor],
        [_previewValueLabel.topAnchor constraintEqualToAnchor:_previewTitleLabel.bottomAnchor constant:6.0f],
        [_previewValueLabel.centerXAnchor constraintEqualToAnchor:_previewCard.contentView.centerXAnchor],
        [_displayModeControl.topAnchor constraintEqualToAnchor:_previewValueLabel.bottomAnchor constant:12.0f],
        [_displayModeControl.leadingAnchor constraintEqualToAnchor:_previewCard.contentView.leadingAnchor constant:14.0f],
        [_displayModeControl.trailingAnchor constraintEqualToAnchor:_previewCard.contentView.trailingAnchor constant:-14.0f],
        [_displayModeControl.bottomAnchor constraintEqualToAnchor:_previewCard.contentView.bottomAnchor constant:-14.0f],
    ]];

    [self updatePreviewContent];

    _topLeftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_topLeftButton setTintColor:[UIColor whiteColor]];
    [_topLeftButton addTarget:self action:@selector(tapTopLeftButton:) forControlEvents:UIControlEventTouchUpInside];
    [_topLeftButton setImage:[UIImage systemImageNamed:@"arrow.up.left"] forState:UIControlStateNormal];
    _topLeftButton.accessibilityLabel = NSLocalizedString(@"Top left", nil);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_topLeftButton setAdjustsImageWhenHighlighted:NO];
#pragma clang diagnostic pop
    [self.backgroundView addSubview:_topLeftButton];
    if (@available(iOS 15.0, *))
    {
        UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
        [config setCornerStyle:UIButtonConfigurationCornerStyleLarge];
        [_topLeftButton setConfiguration:config];
    }
    UILayoutGuide *safeArea = self.backgroundView.safeAreaLayoutGuide;
    [_topLeftButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    _topLeftConstraint = [_topLeftButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:_gTopButtonConstraintsConstantRegular];
    [NSLayoutConstraint activateConstraints:@[
        _topLeftConstraint,
        [_topLeftButton.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:20.0f],
        [_topLeftButton.widthAnchor constraintEqualToConstant:44.0f],
        [_topLeftButton.heightAnchor constraintEqualToConstant:44.0f],
    ]];

    _topRightButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_topRightButton setTintColor:[UIColor whiteColor]];
    [_topRightButton addTarget:self action:@selector(tapTopRightButton:) forControlEvents:UIControlEventTouchUpInside];
    [_topRightButton setImage:[UIImage systemImageNamed:@"arrow.up.right"] forState:UIControlStateNormal];
    _topRightButton.accessibilityLabel = NSLocalizedString(@"Top right", nil);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_topRightButton setAdjustsImageWhenHighlighted:NO];
#pragma clang diagnostic pop
    [self.backgroundView addSubview:_topRightButton];
    if (@available(iOS 15.0, *))
    {
        UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
        [config setCornerStyle:UIButtonConfigurationCornerStyleLarge];
        [_topRightButton setConfiguration:config];
    }
    [_topRightButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    _topRightConstraint = [_topRightButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:_gTopButtonConstraintsConstantRegular];
    [NSLayoutConstraint activateConstraints:@[
        _topRightConstraint,
        [_topRightButton.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-20.0f],
        [_topRightButton.widthAnchor constraintEqualToConstant:44.0f],
        [_topRightButton.heightAnchor constraintEqualToConstant:44.0f],
    ]];

    _topCenterButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_topCenterButton setTintColor:[UIColor whiteColor]];
    [_topCenterButton addTarget:self action:@selector(tapTopCenterButton:) forControlEvents:UIControlEventTouchUpInside];
    [_topCenterButton setImage:[UIImage systemImageNamed:@"arrow.up"] forState:UIControlStateNormal];
    _topCenterButton.accessibilityLabel = NSLocalizedString(@"Top center", nil);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_topCenterButton setAdjustsImageWhenHighlighted:NO];
#pragma clang diagnostic pop
    [self.backgroundView addSubview:_topCenterButton];
    if (@available(iOS 15.0, *))
    {
        UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
        [config setCornerStyle:UIButtonConfigurationCornerStyleLarge];
        [_topCenterButton setConfiguration:config];
    }
    [_topCenterButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    _topCenterConstraint = [_topCenterButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:_gTopButtonConstraintsConstantRegular];
    [NSLayoutConstraint activateConstraints:@[
        _topCenterConstraint,
        [_topCenterButton.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [_topCenterButton.widthAnchor constraintEqualToConstant:44.0f],
        [_topCenterButton.heightAnchor constraintEqualToConstant:44.0f],
    ]];

    [self reloadModeButtonState];

    _mainButton = [MainButton buttonWithType:UIButtonTypeSystem];
    [_mainButton setTintColor:[UIColor whiteColor]];
    [_mainButton addTarget:self action:@selector(tapMainButton:) forControlEvents:UIControlEventTouchUpInside];
    _mainButton.layer.cornerRadius = 18.0;
    _mainButton.layer.cornerCurve = kCACornerCurveContinuous;
    _mainButton.clipsToBounds = YES;
    _mainButton.titleLabel.adjustsFontForContentSizeCategory = YES;
    _mainButton.accessibilityHint = NSLocalizedString(@"Turns the floating display on or off.", nil);
    if (@available(iOS 15.0, *))
    {
        UIButtonConfiguration *config = [UIButtonConfiguration tintedButtonConfiguration];
        [config setTitleTextAttributesTransformer:^NSDictionary <NSAttributedStringKey, id> * _Nonnull(NSDictionary <NSAttributedStringKey, id> * _Nonnull textAttributes) {
            NSMutableDictionary *newAttributes = [textAttributes mutableCopy];
            [newAttributes setObject:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline] forKey:NSFontAttributeName];
            return newAttributes;
        }];
        [config setCornerStyle:UIButtonConfigurationCornerStyleLarge];
        [_mainButton setConfiguration:config];
    }
    else
    {
        [_mainButton.titleLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]];
    }
    [self.backgroundView addSubview:_mainButton];

    [_mainButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_mainButton.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [_mainButton.centerYAnchor constraintEqualToAnchor:self.backgroundView.centerYAnchor],
        [_mainButton.widthAnchor constraintGreaterThanOrEqualToConstant:240.0f],
        [_mainButton.heightAnchor constraintGreaterThanOrEqualToConstant:64.0f],
        [_mainButton.leadingAnchor constraintGreaterThanOrEqualToAnchor:safeArea.leadingAnchor constant:24.0f],
        [_mainButton.trailingAnchor constraintLessThanOrEqualToAnchor:safeArea.trailingAnchor constant:-24.0f],
    ]];

    _statusIndicator = [[UIView alloc] init];
    _statusIndicator.layer.cornerRadius = 4.0;
    [_statusIndicator setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.backgroundView addSubview:_statusIndicator];

    _statusLabel = [[UILabel alloc] init];
    _statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    _statusLabel.adjustsFontForContentSizeCategory = YES;
    _statusLabel.textColor = [UIColor secondaryLabelColor];
    [_statusLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.backgroundView addSubview:_statusLabel];

    _settingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_settingsButton setTintColor:[UIColor whiteColor]];
    [_settingsButton addTarget:self action:@selector(tapSettingsButton:) forControlEvents:UIControlEventTouchUpInside];
    [_settingsButton setImage:[UIImage systemImageNamed:@"gear"] forState:UIControlStateNormal];
    _settingsButton.accessibilityLabel = NSLocalizedString(@"Settings", nil);
    [self.backgroundView addSubview:_settingsButton];
    if (@available(iOS 15.0, *))
    {
        UIButtonConfiguration *config = [UIButtonConfiguration tintedButtonConfiguration];
        [config setCornerStyle:UIButtonConfigurationCornerStyleLarge];
        [_settingsButton setConfiguration:config];
    }
    [_settingsButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_titleLabel.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [_titleLabel.bottomAnchor constraintEqualToAnchor:_subtitleLabel.topAnchor constant:-6.0f],
        [_titleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:safeArea.leadingAnchor constant:24.0f],
        [_subtitleLabel.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [_subtitleLabel.bottomAnchor constraintEqualToAnchor:_previewCard.topAnchor constant:-16.0f],
        [_subtitleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:safeArea.leadingAnchor constant:24.0f],
        [_subtitleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:safeArea.trailingAnchor constant:-24.0f],
        [_statusIndicator.widthAnchor constraintEqualToConstant:8.0f],
        [_statusIndicator.heightAnchor constraintEqualToConstant:8.0f],
        [_statusIndicator.centerYAnchor constraintEqualToAnchor:_statusLabel.centerYAnchor],
        [_statusIndicator.trailingAnchor constraintEqualToAnchor:_statusLabel.leadingAnchor constant:-8.0f],
        [_statusLabel.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor constant:8.0f],
        [_statusLabel.topAnchor constraintEqualToAnchor:_mainButton.bottomAnchor constant:16.0f],
        [_previewCard.bottomAnchor constraintEqualToAnchor:_mainButton.topAnchor constant:-20.0f],
        [_settingsButton.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-20.0f],
        [_settingsButton.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [_settingsButton.widthAnchor constraintGreaterThanOrEqualToConstant:116.0f],
        [_settingsButton.heightAnchor constraintEqualToConstant:44.0f],
    ]];

    _authorLabel = [[UILabel alloc] init];
    [_authorLabel setNumberOfLines:0];
    [_authorLabel setTextAlignment:NSTextAlignmentCenter];
    [_authorLabel setTextColor:[UIColor whiteColor]];
    [_authorLabel setFont:[UIFont systemFontOfSize:14.0]];
    [_authorLabel sizeToFit];
    [self.backgroundView addSubview:_authorLabel];

    _authorLabelBottomConstraint = [_authorLabel.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:_gAuthorLabelBottomConstraintConstantRegular];
    [_authorLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        _authorLabelBottomConstraint,
        [_authorLabel.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
    ]];

    UITapGestureRecognizer *authorTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAuthorLabel:)];
    [_authorLabel setUserInteractionEnabled:YES];
    [_authorLabel addGestureRecognizer:authorTapGesture];

    [self verticalSizeClassUpdated];
    [self reloadMainButtonState];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _backgroundGradient.frame = self.backgroundView.bounds;
    _supportsCenterMost = CGRectGetMinY(self.view.window.safeAreaLayoutGuide.layoutFrame) >= 51;
}

- (void)updateVisualStyle
{
    UIColor *topColor = [UIColor systemBackgroundColor];
    UIColor *accentColor = [[UIColor systemTealColor] colorWithAlphaComponent:(self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? 0.28 : 0.18)];
    _backgroundGradient.colors = @[(id)topColor.CGColor, (id)accentColor.CGColor];

    NSArray<UIButton *> *positionButtons = @[_topLeftButton, _topCenterButton, _topRightButton];
    for (UIButton *button in positionButtons) {
        UIColor *backgroundColor = button.isSelected ? [UIColor systemTealColor] : [UIColor tertiarySystemFillColor];
        UIColor *foregroundColor = button.isSelected ? [UIColor whiteColor] : [UIColor labelColor];
        if (@available(iOS 15.0, *)) {
            UIButtonConfiguration *configuration = button.configuration;
            configuration.baseBackgroundColor = backgroundColor;
            configuration.baseForegroundColor = foregroundColor;
            button.configuration = configuration;
        } else {
            button.backgroundColor = backgroundColor;
            button.tintColor = foregroundColor;
        }
        button.layer.cornerRadius = 22.0;
        button.layer.cornerCurve = kCACornerCurveContinuous;
    }

    if (@available(iOS 15.0, *)) {
        UIButtonConfiguration *configuration = _settingsButton.configuration;
        configuration.title = NSLocalizedString(@"Settings", nil);
        configuration.image = [UIImage systemImageNamed:@"gearshape.fill"];
        configuration.imagePadding = 8.0;
        configuration.baseBackgroundColor = [UIColor tertiarySystemFillColor];
        configuration.baseForegroundColor = [UIColor labelColor];
        _settingsButton.configuration = configuration;
    } else {
        [_settingsButton setTitle:NSLocalizedString(@"Settings", nil) forState:UIControlStateNormal];
        [_settingsButton setImage:[UIImage systemImageNamed:@"gearshape.fill"] forState:UIControlStateNormal];
        _settingsButton.imageEdgeInsets = UIEdgeInsetsMake(0.0, -4.0, 0.0, 4.0);
        _settingsButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 4.0, 0.0, -4.0);
        _settingsButton.backgroundColor = [UIColor tertiarySystemFillColor];
        _settingsButton.tintColor = [UIColor labelColor];
    }
    _settingsButton.layer.cornerRadius = 22.0;
    _settingsButton.layer.cornerCurve = kCACornerCurveContinuous;
}

- (void)updatePreviewContent
{
    BOOL showsFPS = (_displayModeControl.selectedSegmentIndex == 1);
    _previewValueLabel.text = showsFPS ? @"60 FPS" : @"↓ 233 KB/s   ↑ 128 KB/s";
    _previewCard.accessibilityValue = showsFPS ? NSLocalizedString(@"FPS preview", nil) : NSLocalizedString(@"Network speed preview", nil);
}

- (void)displayModeChanged:(UISegmentedControl *)sender
{
    [self setDisplayMode:(sender.selectedSegmentIndex == 1)];
    [self updatePreviewContent];
    UISelectionFeedbackGenerator *feedback = [[UISelectionFeedbackGenerator alloc] init];
    [feedback selectionChanged];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _impactFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];

    [self registerNotifications];
    [self updateVisualStyle];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self toggleHUDAfterLaunch];
}

- (void)toggleHUDNotificationReceived:(NSNotification *)notification {
    NSString *toggleAction = notification.userInfo[kToggleHUDAfterLaunchNotificationActionKey];
    if (!toggleAction) {
        [self toggleHUDAfterLaunch];
    } else if ([toggleAction isEqualToString:kToggleHUDAfterLaunchNotificationActionToggleOn]) {
        [self toggleOnHUDAfterLaunch];
    } else if ([toggleAction isEqualToString:kToggleHUDAfterLaunchNotificationActionToggleOff]) {
        [self toggleOffHUDAfterLaunch];
    }
}

- (void)toggleHUDAfterLaunch {
    if ([RootViewController shouldToggleHUDAfterLaunch]) {
        [RootViewController setShouldToggleHUDAfterLaunch:NO];
        [self tapMainButton:_mainButton];
        [[UIApplication sharedApplication] suspend];
    }
}

- (void)toggleOnHUDAfterLaunch {
    if ([RootViewController shouldToggleHUDAfterLaunch]) {
        [RootViewController setShouldToggleHUDAfterLaunch:NO];
        if (!_isRemoteHUDActive) {
            [self tapMainButton:_mainButton];
        }
        [[UIApplication sharedApplication] suspend];
    }
}

- (void)toggleOffHUDAfterLaunch {
    if ([RootViewController shouldToggleHUDAfterLaunch]) {
        [RootViewController setShouldToggleHUDAfterLaunch:NO];
        if (_isRemoteHUDActive) {
            [self tapMainButton:_mainButton];
        }
        [[UIApplication sharedApplication] suspend];
    }
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Developer Area", nil) message:NSLocalizedString(@"Choose an action below.", nil) preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", nil) style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Reset Settings", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self resetUserDefaults];
        }]];
#if DEBUG && !TARGET_OS_SIMULATOR
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Memory Pressure", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            SimulateMemoryPressure();
        }]];
#endif
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)resetUserDefaults
{
    // Reset user defaults
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if (bundleIdentifier) {
        [GetStandardUserDefaults() removePersistentDomainForName:bundleIdentifier];
        [GetStandardUserDefaults() synchronize];
    }

    // Reset custom user defaults
    BOOL removed = [[NSFileManager defaultManager] removeItemAtPath:(JBROOT_PATH_NSSTRING(USER_DEFAULTS_PATH)) error:nil];
    if (removed)
    {
        // Terminate HUD
        [self setHUDEnabled:NO];

        // Terminate App
        [[UIApplication sharedApplication] terminateWithSuccess];
    }
}

- (void)loadUserDefaults:(BOOL)forceReload
{
    if (forceReload || !_userDefaults) {
        _userDefaults = [[NSDictionary dictionaryWithContentsOfFile:(JBROOT_PATH_NSSTRING(USER_DEFAULTS_PATH))] mutableCopy] ?: [NSMutableDictionary dictionary];
    }
}

- (void)saveUserDefaults
{
    [_userDefaults writeToFile:(JBROOT_PATH_NSSTRING(USER_DEFAULTS_PATH)) atomically:YES];
    notify_post(NOTIFY_RELOAD_HUD);
}

- (BOOL)isLandscapeOrientation
{
    UIInterfaceOrientation orientation;
    orientation = self.view.window.windowScene.interfaceOrientation;
    BOOL isLandscape;
    if (orientation == UIInterfaceOrientationUnknown) {
        isLandscape = CGRectGetWidth(self.view.bounds) > CGRectGetHeight(self.view.bounds);
    } else {
        isLandscape = UIInterfaceOrientationIsLandscape(orientation);
    }
    return isLandscape;
}

- (HUDUserDefaultsKey)selectedModeKeyForCurrentOrientation
{
    return [self isLandscapeOrientation] ? HUDUserDefaultsKeySelectedModeLandscape : HUDUserDefaultsKeySelectedMode;
}

- (HUDPresetPosition)selectedModeForCurrentOrientation
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:[self selectedModeKeyForCurrentOrientation]];
    return mode != nil ? (HUDPresetPosition)[mode integerValue] : HUDPresetPositionTopCenter;
}

- (void)setSelectedModeForCurrentOrientation:(HUDPresetPosition)selectedMode
{
    [self loadUserDefaults:NO];
    // Remove some keys that are not persistent
    if ([self isLandscapeOrientation]) {
        [_userDefaults removeObjectForKey:HUDUserDefaultsKeyCurrentLandscapePositionY];
    } else {
        [_userDefaults removeObjectForKey:HUDUserDefaultsKeyCurrentPositionY];
    }
    [_userDefaults setObject:@(selectedMode) forKey:[self selectedModeKeyForCurrentOrientation]];
    [self saveUserDefaults];
}

- (BOOL)passthroughMode
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyPassthroughMode];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setPassthroughMode:(BOOL)passthroughMode
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(passthroughMode) forKey:HUDUserDefaultsKeyPassthroughMode];
    [self saveUserDefaults];
}

- (BOOL)singleLineMode
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeySingleLineMode];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setSingleLineMode:(BOOL)singleLineMode
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(singleLineMode) forKey:HUDUserDefaultsKeySingleLineMode];
    [self saveUserDefaults];
}

- (BOOL)usesBitrate
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesBitrate];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setUsesBitrate:(BOOL)usesBitrate
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(usesBitrate) forKey:HUDUserDefaultsKeyUsesBitrate];
    [self saveUserDefaults];
}

- (BOOL)usesArrowPrefixes
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesArrowPrefixes];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setUsesArrowPrefixes:(BOOL)usesArrowPrefixes
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(usesArrowPrefixes) forKey:HUDUserDefaultsKeyUsesArrowPrefixes];
    [self saveUserDefaults];
}

- (BOOL)usesLargeFont
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesLargeFont];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setUsesLargeFont:(BOOL)usesLargeFont
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(usesLargeFont) forKey:HUDUserDefaultsKeyUsesLargeFont];
    [self saveUserDefaults];
}

- (BOOL)usesRotation
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesRotation];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setUsesRotation:(BOOL)usesRotation
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(usesRotation) forKey:HUDUserDefaultsKeyUsesRotation];
    [self saveUserDefaults];
}

- (BOOL)usesInvertedColor
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesInvertedColor];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setUsesInvertedColor:(BOOL)usesInvertedColor
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(usesInvertedColor) forKey:HUDUserDefaultsKeyUsesInvertedColor];
    [self saveUserDefaults];
}

- (BOOL)keepInPlace
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyKeepInPlace];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setKeepInPlace:(BOOL)keepInPlace
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(keepInPlace) forKey:HUDUserDefaultsKeyKeepInPlace];
    [self saveUserDefaults];
}

- (BOOL)hideAtSnapshot
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyHideAtSnapshot];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setHideAtSnapshot:(BOOL)hideAtSnapshot
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(hideAtSnapshot) forKey:HUDUserDefaultsKeyHideAtSnapshot];
    [self saveUserDefaults];
}

- (BOOL)displayMode
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyDisplayMode];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setDisplayMode:(BOOL)displayMode
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(displayMode) forKey:HUDUserDefaultsKeyDisplayMode];
    [self saveUserDefaults];
}

- (void)reloadMainButtonState
{
    _isRemoteHUDActive = [self isHUDEnabled];

    static NSAttributedString *hintAttributedString = nil;
    static NSAttributedString *creditsAttributedString = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *defaultAttributes = @{
            NSForegroundColorAttributeName: [UIColor secondaryLabelColor],
            NSFontAttributeName: [UIFont systemFontOfSize:14],
        };

        NSMutableParagraphStyle *creditsParaStyle = [[NSMutableParagraphStyle alloc] init];
        creditsParaStyle.lineHeightMultiple = 1.2;
        creditsParaStyle.alignment = NSTextAlignmentCenter;

        NSDictionary *creditsAttributes = @{
            NSForegroundColorAttributeName: [UIColor secondaryLabelColor],
            NSFontAttributeName: [UIFont systemFontOfSize:14],
            NSParagraphStyleAttributeName: creditsParaStyle,
        };

        NSString *hintText = NSLocalizedString(@"You can quit this app now.\nThe HUD will persist on your screen.", nil);
        hintAttributedString = [[NSAttributedString alloc] initWithString:hintText attributes:defaultAttributes];

        NSTextAttachment *githubIcon = [NSTextAttachment textAttachmentWithImage:[UIImage imageNamed:@"github-mark-white"]];
        [githubIcon setBounds:CGRectMake(0, 0, 14, 14)];

        NSTextAttachment *i18nIcon = [NSTextAttachment textAttachmentWithImage:[UIImage systemImageNamed:@"character.bubble.fill"]];
        [i18nIcon setBounds:CGRectMake(0, 0, 14, 14)];

        NSAttributedString *githubIconText = [NSAttributedString attributedStringWithAttachment:githubIcon];
        NSMutableAttributedString *githubIconTextFull = [[NSMutableAttributedString alloc] initWithAttributedString:githubIconText];
        [githubIconTextFull appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:creditsAttributes]];

        NSAttributedString *i18nIconText = [NSAttributedString attributedStringWithAttachment:i18nIcon];
        NSMutableAttributedString *i18nIconTextFull = [[NSMutableAttributedString alloc] initWithAttributedString:i18nIconText];
        [i18nIconTextFull appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:creditsAttributes]];

        NSString *creditsText = NSLocalizedString(@"Made with ♥ by @GITHUB@Lessica and @GITHUB@jmpews\nTranslation @TRANSLATION@", nil);
        NSMutableAttributedString *creditsAttributedText = [[NSMutableAttributedString alloc] initWithString:creditsText attributes:creditsAttributes];

        // replace all "@GITHUB@" with github icon
        NSRange atRange;

        atRange = [creditsAttributedText.string rangeOfString:@"@GITHUB@"];
        while (atRange.location != NSNotFound) {
            [creditsAttributedText replaceCharactersInRange:atRange withAttributedString:githubIconTextFull];
            atRange = [creditsAttributedText.string rangeOfString:@"@GITHUB@"];
        }

        // replace all "@TRANSLATION@" with character bubble
        atRange = [creditsAttributedText.string rangeOfString:@"@TRANSLATION@"];
        while (atRange.location != NSNotFound) {
            [creditsAttributedText replaceCharactersInRange:atRange withAttributedString:i18nIconTextFull];
            atRange = [creditsAttributedText.string rangeOfString:@"@TRANSLATION@"];
        }

        creditsAttributedString = creditsAttributedText;
    });

    __weak typeof(self) weakSelf = self;
    [UIView transitionWithView:self.backgroundView duration:HUD_TRANSITION_DURATION options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSString *mainTitle = strongSelf->_isRemoteHUDActive ? NSLocalizedString(@"Exit HUD", nil) : NSLocalizedString(@"Open HUD", nil);
        UIImage *mainImage = [UIImage systemImageNamed:(strongSelf->_isRemoteHUDActive ? @"stop.fill" : @"play.fill")];
        UIColor *mainColor = strongSelf->_isRemoteHUDActive ? [UIColor systemRedColor] : [UIColor systemTealColor];
        if (@available(iOS 15.0, *)) {
            UIButtonConfiguration *configuration = strongSelf->_mainButton.configuration;
            configuration.title = mainTitle;
            configuration.image = mainImage;
            configuration.imagePadding = 10.0;
            configuration.baseBackgroundColor = mainColor;
            configuration.baseForegroundColor = [UIColor whiteColor];
            strongSelf->_mainButton.configuration = configuration;
        } else {
            [strongSelf->_mainButton setTitle:mainTitle forState:UIControlStateNormal];
            [strongSelf->_mainButton setImage:mainImage forState:UIControlStateNormal];
            strongSelf->_mainButton.tintColor = [UIColor whiteColor];
            strongSelf->_mainButton.backgroundColor = mainColor;
            strongSelf->_mainButton.contentEdgeInsets = UIEdgeInsetsMake(16.0, 24.0, 16.0, 24.0);
            strongSelf->_mainButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 10.0, 0.0, 0.0);
        }
        strongSelf->_mainButton.accessibilityValue = strongSelf->_isRemoteHUDActive ? NSLocalizedString(@"Active", nil) : NSLocalizedString(@"Inactive", nil);
        strongSelf->_statusLabel.text = strongSelf->_isRemoteHUDActive ? NSLocalizedString(@"HUD is active", nil) : NSLocalizedString(@"HUD is inactive", nil);
        strongSelf->_statusIndicator.backgroundColor = strongSelf->_isRemoteHUDActive ? [UIColor systemGreenColor] : [UIColor tertiaryLabelColor];
        [strongSelf->_authorLabel setAttributedText:(strongSelf->_isRemoteHUDActive ? hintAttributedString : creditsAttributedString)];
    } completion:nil];
}

- (void)presentTopCenterMostHints
{
    if (!_isRemoteHUDActive) {
        return;
    }
    [_authorLabel setText:NSLocalizedString(@"Tap that button on the center again,\nto toggle ON/OFF “Dynamic Island” mode.", nil)];
}

- (BOOL)settingHighlightedWithKey:(NSString * _Nonnull)key
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:key];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)settingDidSelectWithKey:(NSString * _Nonnull)key
{
    BOOL highlighted = [self settingHighlightedWithKey:key];
    [_userDefaults setObject:@(!highlighted) forKey:key];
    [self saveUserDefaults];
}

- (void)reloadModeButtonState
{
    HUDPresetPosition selectedMode = [self selectedModeForCurrentOrientation];
    BOOL isCentered = (selectedMode == HUDPresetPositionTopCenter || selectedMode == HUDPresetPositionTopCenterMost);
    BOOL isCenteredMost = (selectedMode == HUDPresetPositionTopCenterMost);
    [_topLeftButton setSelected:(selectedMode == HUDPresetPositionTopLeft)];
    [_topCenterButton setSelected:isCentered];
    [_topRightButton setSelected:(selectedMode == HUDPresetPositionTopRight)];
    UIImage *topCenterImage = (isCenteredMost ? [UIImage systemImageNamed:@"arrow.up.to.line"] : [UIImage systemImageNamed:@"arrow.up"]);
    [_topCenterButton setImage:topCenterImage forState:UIControlStateNormal];
    [self updateVisualStyle];
}

- (void)tapAuthorLabel:(UITapGestureRecognizer *)sender
{
    if (_isRemoteHUDActive) {
        return;
    }
    NSString *repoURLString = @"https://trollspeed.app";
    NSURL *repoURL = [NSURL URLWithString:repoURLString];
    [[UIApplication sharedApplication] openURL:repoURL options:@{} completionHandler:nil];
}

- (void)tapTopLeftButton:(UIButton *)sender
{
    log_debug(OS_LOG_DEFAULT, "- [RootViewController tapTopLeftButton:%{public}@]", sender);
    [self setSelectedModeForCurrentOrientation:HUDPresetPositionTopLeft];
    [self reloadModeButtonState];
}

- (void)tapTopRightButton:(UIButton *)sender
{
    log_debug(OS_LOG_DEFAULT, "- [RootViewController tapTopRightButton:%{public}@]", sender);
    [self setSelectedModeForCurrentOrientation:HUDPresetPositionTopRight];
    [self reloadModeButtonState];
}

- (void)tapTopCenterButton:(UIButton *)sender
{
    log_debug(OS_LOG_DEFAULT, "- [RootViewController tapTopCenterButton:%{public}@]", sender);
    HUDPresetPosition selectedMode = [self selectedModeForCurrentOrientation];
    BOOL isCenteredMost = (selectedMode == HUDPresetPositionTopCenterMost);
    if (!sender.isSelected || !_supportsCenterMost) {
        [self setSelectedModeForCurrentOrientation:HUDPresetPositionTopCenter];
        if (_supportsCenterMost) {
            [self presentTopCenterMostHints];
        }
    } else {
        if (isCenteredMost) {
            [self setSelectedModeForCurrentOrientation:HUDPresetPositionTopCenter];
        } else {
            [self setSelectedModeForCurrentOrientation:HUDPresetPositionTopCenterMost];
        }
    }
    [self reloadModeButtonState];
}

- (void)tapMainButton:(UIButton *)sender
{
    log_debug(OS_LOG_DEFAULT, "- [RootViewController tapMainButton:%{public}@]", sender);

    BOOL isNowEnabled = [self isHUDEnabled];
    [self setHUDEnabled:!isNowEnabled];
    isNowEnabled = !isNowEnabled;

    if (isNowEnabled)
    {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

        [_impactFeedbackGenerator prepare];
        int anyToken;
        __weak typeof(self) weakSelf = self;
        notify_register_dispatch(NOTIFY_LAUNCHED_HUD, &anyToken, dispatch_get_main_queue(), ^(int token) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            notify_cancel(token);
            [strongSelf->_impactFeedbackGenerator impactOccurred];
            dispatch_semaphore_signal(semaphore);
        });

        [self.backgroundView setUserInteractionEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            intptr_t timedOut = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)));
            dispatch_async(dispatch_get_main_queue(), ^{
                if (timedOut) {
                    log_error(OS_LOG_DEFAULT, "Timed out waiting for HUD to launch");
                }
                [self reloadMainButtonState];
                [self.backgroundView setUserInteractionEnabled:YES];
            });
        });
    }
    else
    {
        [self.backgroundView setUserInteractionEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self reloadMainButtonState];
            [self.backgroundView setUserInteractionEnabled:YES];
        });
    }
}

- (void)tapSettingsButton:(UIButton *)sender
{
    if (![_mainButton isEnabled]) return;
    log_debug(OS_LOG_DEFAULT, "- [RootViewController tapSettingsButton:%{public}@]", sender);

    TSSettingsController *settingsViewController = [[TSSettingsController alloc] init];
    settingsViewController.delegate = self;
    settingsViewController.alreadyLaunched = _isRemoteHUDActive;

    SPLarkTransitioningDelegate *transitioningDelegate = [[SPLarkTransitioningDelegate alloc] init];
    settingsViewController.transitioningDelegate = transitioningDelegate;
    settingsViewController.modalPresentationStyle = UIModalPresentationCustom;
    settingsViewController.modalPresentationCapturesStatusBarAppearance = YES;
    [self presentViewController:settingsViewController animated:YES completion:nil];
}

- (void)verticalSizeClassUpdated
{
    UIUserInterfaceSizeClass verticalClass = self.traitCollection.verticalSizeClass;
    BOOL isPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
    if (verticalClass == UIUserInterfaceSizeClassCompact) {
        CGFloat topConstant = _gTopButtonConstraintsConstantCompact;
        [_settingsButton setHidden:YES];
        [_titleLabel setHidden:YES];
        [_subtitleLabel setHidden:YES];
        [_previewCard setHidden:YES];
        [_statusLabel setHidden:YES];
        [_statusIndicator setHidden:YES];
        [_authorLabelBottomConstraint setConstant:_gAuthorLabelBottomConstraintConstantCompact];
        [_topLeftConstraint setConstant:topConstant];
        [_topRightConstraint setConstant:topConstant];
        [_topCenterConstraint setConstant:topConstant];
    } else {
        CGFloat topConstant = isPad ? _gTopButtonConstraintsConstantRegularPad : _gTopButtonConstraintsConstantRegular;
        [_settingsButton setHidden:NO];
        [_titleLabel setHidden:NO];
        [_subtitleLabel setHidden:NO];
        [_previewCard setHidden:NO];
        [_statusLabel setHidden:NO];
        [_statusIndicator setHidden:NO];
        [_authorLabelBottomConstraint setConstant:_gAuthorLabelBottomConstraintConstantRegular];
        [_topLeftConstraint setConstant:topConstant];
        [_topRightConstraint setConstant:topConstant];
        [_topCenterConstraint setConstant:topConstant];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    [self verticalSizeClassUpdated];
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateVisualStyle];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self reloadModeButtonState];
    } completion:nil];
}

@end
