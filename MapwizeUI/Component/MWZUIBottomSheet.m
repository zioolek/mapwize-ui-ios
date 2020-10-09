#import "MWZUIBottomSheet.h"
#import "MWZUIPlaceMock.h"
#import "MWZUICollectionViewCell.h"
#import "MWZUIDefaultContentView.h"
#import "MWZUIFullContentView.h"
#import "MWZUIBottomSheetComponents.h"

@interface MWZUIBottomSheet () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (assign) CGFloat currentTranslation;
@property (assign) CGFloat initialTranslation;
@property (nonatomic) UIView* headerView;
@property (nonatomic) UICollectionView* headerImageCollectionView;
@property (nonatomic) UIView* contentView;
@property (nonatomic) MWZUIDefaultContentView* defaultContentView;
@property (nonatomic) MWZUIFullContentView* fullContentView;

@property (nonatomic) MWZUIPlaceMock* mock;

@property (nonatomic) MWZPlace* place;
@property (nonatomic) MWZPlacePreview* placePreview;
// STATE : HIDDEN, SMALL, SMALL+HEADER, FULL
//         0,      100,   200,          FULL


@property (assign) CGFloat defaultContentHeight;
@property (assign) CGFloat defaultHeaderHeight;
@property (assign) CGFloat minimizedContentHeight;
@property (assign) CGFloat minimizedHeaderHeight;
@property (assign) CGFloat maximizedContentHeight;
@property (assign) CGFloat maximizedHeaderHeight;
@property (nonatomic) NSLayoutConstraint* headerHeightConstraint;
@property (nonatomic) NSLayoutConstraint* selfTopConstraint;

@property (nonatomic) CGRect parentFrame;
@property (nonatomic) UIColor* color;

@end

@implementation MWZUIBottomSheet

- (instancetype)initWithFrame:(CGRect) frame color:(UIColor*)color
{
    self = [super initWithFrame:frame];
    if (self) {
        _parentFrame = frame;
        _color = color;
        //self.transform = CGAffineTransformMakeTranslation(0, _parentFrame.size.height);
        [self setupGestureRecognizer];
        [self setDefaultValuesFromFrame:frame];
        
    }
    return self;
}

- (void) setDefaultValuesFromFrame:(CGRect) parentFrame {
    _defaultContentHeight = 150;
    _defaultHeaderHeight = 90;
    _minimizedContentHeight = 100.0;
    _minimizedHeaderHeight = 0.0;
    _maximizedContentHeight = parentFrame.size.height * 2/3;
    _maximizedHeaderHeight = parentFrame.size.height * 1/3;
}

- (void) didMoveToSuperview {
    [self setupViews];
}

- (void) showPlacePreview:(MWZPlacePreview*)placePreview {
    _placePreview = placePreview;
    [_headerImageCollectionView reloadData];
    [_defaultContentView removeFromSuperview];
    [_fullContentView removeFromSuperview];
    _defaultContentView = [[MWZUIDefaultContentView alloc] initWithFrame:self.frame color:_color];
    _defaultContentView.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_defaultContentView];
    [[_defaultContentView.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor] setActive:YES];
    [[_defaultContentView.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor] setActive:YES];
    [[_defaultContentView.topAnchor constraintEqualToAnchor:_contentView.topAnchor] setActive:YES];
    [_defaultContentView setPlacePreview:placePreview];
    [_defaultContentView layoutIfNeeded];
    self.defaultContentHeight = _defaultContentView.frame.size.height + self.safeAreaInsets.bottom;
    [self animateToHeight:self.defaultContentHeight];
}

- (void) showPlace:(MWZPlace*)place language:(NSString*)language {
    _place = place;
    [_headerImageCollectionView reloadData];
    [_defaultContentView removeFromSuperview];
    [_fullContentView removeFromSuperview];
    _defaultContentView = [[MWZUIDefaultContentView alloc] initWithFrame:self.frame color:_color];
    _defaultContentView.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_defaultContentView];
    [[_defaultContentView.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor] setActive:YES];
    [[_defaultContentView.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor] setActive:YES];
    [[_defaultContentView.topAnchor constraintEqualToAnchor:_contentView.topAnchor] setActive:YES];
    
    _fullContentView = [[MWZUIFullContentView alloc] initWithFrame:self.frame color:_color];
    _fullContentView.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_fullContentView];
    [[_fullContentView.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor] setActive:YES];
    [[_fullContentView.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor] setActive:YES];
    [[_fullContentView.topAnchor constraintEqualToAnchor:_contentView.topAnchor] setActive:YES];
    [[_fullContentView.bottomAnchor constraintEqualToAnchor:_contentView.bottomAnchor] setActive:YES];
    [_fullContentView setHidden:YES];
    _fullContentView.alpha = 0.0;
    
    NSMutableArray<MWZUIIconTextButton*>* minimizedViewButtons = [_defaultContentView buildButtonsForPlace:place];
    NSMutableArray<MWZUIFullContentViewComponentButton*>* fullHeaderButtons = [_fullContentView buildHeaderButtonsForPlace:place language:language];
    NSMutableArray<MWZUIFullContentViewComponentRow*>* fullRows = [_fullContentView buildContentRowsForPlace:place language:language];
    MWZUIBottomSheetComponents* components = [[MWZUIBottomSheetComponents alloc] initWithHeaderButtons:fullHeaderButtons contentRows:fullRows minimizedViewButtons:minimizedViewButtons];
    if (_delegate && [_delegate respondsToSelector:@selector(requireComponentForPlace:withDefaultComponents:)]) {
        components = [_delegate requireComponentForPlace:place withDefaultComponents:components];
    }
    
    [_defaultContentView setContentForPlace:place language:language buttons:components.minimizedViewButtons];;
    [_fullContentView setContentForPlace:place language:language buttons:components.headerButtons rows:components.contentRows];
    
    [_defaultContentView layoutIfNeeded];
    self.defaultContentHeight = _defaultContentView.frame.size.height + self.safeAreaInsets.bottom;
    if (false) { //place.imageUrls && place.imageUrls.count > 0) {
        _maximizedHeaderHeight = _parentFrame.size.height * 1/3;
        [self animateToHeight:self.defaultHeaderHeight + self.defaultContentHeight];
    }
    else {
        _maximizedHeaderHeight = 0;
        [self animateToHeight:self.defaultContentHeight];
    }
    
}

- (void) showMock:(MWZUIPlaceMock*) mock {
    _mock = mock;
    [_headerImageCollectionView reloadData];
    [_defaultContentView removeFromSuperview];
    [_fullContentView removeFromSuperview];
    _defaultContentView = [[MWZUIDefaultContentView alloc] initWithFrame:self.frame color:_color];
    _defaultContentView.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_defaultContentView];
    [[_defaultContentView.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor] setActive:YES];
    [[_defaultContentView.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor] setActive:YES];
    [[_defaultContentView.topAnchor constraintEqualToAnchor:_contentView.topAnchor] setActive:YES];
    [_defaultContentView setMock:mock];
    [_defaultContentView layoutIfNeeded];
    
    _fullContentView = [[MWZUIFullContentView alloc] initWithFrame:self.frame color:_color];
    _fullContentView.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_fullContentView];
    [[_fullContentView.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor] setActive:YES];
    [[_fullContentView.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor] setActive:YES];
    [[_fullContentView.topAnchor constraintEqualToAnchor:_contentView.topAnchor] setActive:YES];
    [[_fullContentView.bottomAnchor constraintEqualToAnchor:_contentView.bottomAnchor] setActive:YES];
    [_fullContentView setHidden:YES];
    _fullContentView.alpha = 0.0;
    [_fullContentView setMock:_mock];
    
    self.defaultContentHeight = _defaultContentView.frame.size.height + self.safeAreaInsets.bottom;
    [self animateToHeight:self.defaultHeaderHeight + self.defaultContentHeight];
    //[self updateHeight:self.defaultHeaderHeight + self.defaultContentHeight];
    
}

- (void) setupViews {
    _selfTopConstraint = [self.topAnchor constraintEqualToAnchor:self.superview.topAnchor constant:_parentFrame.size.height];
    [_selfTopConstraint setActive:YES];
    [[self.heightAnchor constraintEqualToConstant:self.maximizedHeaderHeight + self.maximizedContentHeight] setActive:YES];
    _headerView = [[UIView alloc] initWithFrame:CGRectZero];
    _headerView.translatesAutoresizingMaskIntoConstraints = NO;
    _headerView.backgroundColor = [UIColor clearColor];
    _contentView = [[UIView alloc] initWithFrame:CGRectZero];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    _contentView.backgroundColor = [UIColor whiteColor];
    [self addSubview:_headerView];
    [self addSubview:_contentView];
    
    [[_headerView.topAnchor constraintEqualToAnchor:self.topAnchor] setActive:YES];
    [[_headerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor] setActive:YES];
    [[_headerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor] setActive:YES];
    _headerHeightConstraint = [_headerView.heightAnchor constraintEqualToConstant:0];
    [_headerHeightConstraint setActive:YES];
    
    [[_contentView.topAnchor constraintEqualToAnchor:_headerView.bottomAnchor] setActive:YES];
    [[_contentView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor] setActive:YES];
    [[_contentView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor] setActive:YES];
    [[_contentView.heightAnchor constraintEqualToAnchor:self.heightAnchor multiplier:0.75] setActive:YES];
    
    UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(self.frame.size.height/3, self.frame.size.height/3);
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    flowLayout.minimumInteritemSpacing = 40;
    flowLayout.minimumLineSpacing = 2;
    //flowLayout.minimumLineSpacing = 0;
    _headerImageCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    _headerImageCollectionView.dataSource = self;
    _headerImageCollectionView.delegate = self;
    _headerImageCollectionView.backgroundColor = [UIColor clearColor];
    _headerImageCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    _headerImageCollectionView.showsVerticalScrollIndicator = NO;
    _headerImageCollectionView.showsHorizontalScrollIndicator = NO;
    [_headerView addSubview:_headerImageCollectionView];
    [[_headerImageCollectionView.topAnchor constraintEqualToAnchor:_headerView.topAnchor] setActive:YES];
    [[_headerImageCollectionView.trailingAnchor constraintEqualToAnchor:_headerView.trailingAnchor] setActive:YES];
    [[_headerImageCollectionView.leadingAnchor constraintEqualToAnchor:_headerView.leadingAnchor] setActive:YES];
    [[_headerImageCollectionView.bottomAnchor constraintEqualToAnchor:_headerView.bottomAnchor] setActive:YES];
    [_headerImageCollectionView registerClass:[MWZUICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    
}

- (void) setupGestureRecognizer {
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragView:)];
    self.userInteractionEnabled = YES;
    [self addGestureRecognizer:panGesture];
}

- (void) dragView:(UIPanGestureRecognizer*) sender {
    CGPoint translation = [sender translationInView:sender.view.superview];
    if (sender.state == UIGestureRecognizerStateBegan) {
        _currentTranslation = self.frame.origin.y;
        [_defaultContentView setHidden:NO];
        [_fullContentView setHidden:NO];
    }
    [self updateHeight:self.frame.size.height - _currentTranslation - translation.y];
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [sender velocityInView:sender.view.superview];
        /*if (velocity.y < -500) {
            [self animateTo:0];
            return;
        }
        if (velocity.y > 500) {
            if (_fullHeight - _currentTranslation > _smallHeight) {
                [self animateTo:_fullHeight-_smallHeight];
            }
            else {
                [self animateTo:_fullHeight];
            }
            return;
        }*/
        
        
        double nextHeight = self.frame.size.height - _currentTranslation - translation.y;
        double closestHeight = self.frame.size.height;
        double closestDistance = fabs(nextHeight - closestHeight);
        
        if (fabs(nextHeight - self.defaultContentHeight - self.defaultHeaderHeight) < closestDistance) {
            closestDistance = fabs(nextHeight - self.defaultContentHeight - self.defaultHeaderHeight);
            closestHeight = self.defaultContentHeight + self.defaultHeaderHeight;
        }
        
        if (fabs(nextHeight - self.defaultContentHeight) < closestDistance) {
            closestDistance = fabs(nextHeight - self.defaultContentHeight);
            closestHeight = self.defaultContentHeight;
        }
        
        if (fabs(nextHeight - 0) < closestDistance) {
            closestHeight = 0;
        }
        
        
        
        [self animateToHeight:closestHeight];

    }
}

-(double) headerHeightFormula:(double)x {
    // 0:1
    // default:1
    // full : 0
    if (x <= self.defaultContentHeight + self.defaultHeaderHeight) {
        double x0 = self.defaultContentHeight;
        double x1 = self.defaultContentHeight + self.defaultHeaderHeight;
        double f0 = 0;
        double f1 = self.defaultHeaderHeight;
        return f0*((x-x1)/(x0-x1)) + f1*((x-x0)/(x1-x0));
    }
    else {
        double x0 = self.defaultContentHeight + self.defaultHeaderHeight;
        double x1 = self.frame.size.height;
        double f0 = self.defaultHeaderHeight;
        double f1 = self.frame.size.height / 4;
        return f0*((x-x1)/(x0-x1)) + f1*((x-x0)/(x1-x0));
    }
}

-(double) alphaFormula:(double)x {
    // 0:1
    // default:1
    // full : 0
    double x0 = 0;
    double x1 = self.defaultHeaderHeight + self.defaultContentHeight;
    double x2 = self.frame.size.height * 2 / 3;
    double f0 = 1;
    double f1 = 1;
    double f2 = 0;
    return f0*((x-x1)/(f0-x1))*((x-x2)/(f0-x2)) + f1*((x-x0)/(x1-x0))*((x-x2)/(x1-x2)) +
        f2*((x-x0)/(x2-x0))*((x-x1)/(x2-x1));
}

-(double) reversedAlphaFormula:(double)x {
    // 0:1
    // default:1
    // full : 0
    double x0 = 0;
    double x1 = self.frame.size.height * 2 / 3;
    double x2 = self.frame.size.height;
    double f0 = 0;
    double f1 = 0;
    double f2 = 1;
    return f0*((x-x1)/(f0-x1))*((x-x2)/(f0-x2)) + f1*((x-x0)/(x1-x0))*((x-x2)/(x1-x2)) +
        f2*((x-x0)/(x2-x0))*((x-x1)/(x2-x1));
}

- (void) updateHeight:(CGFloat) height {
    //self.transform = CGAffineTransformMakeTranslation(0, self.frame.size.height - height);
    _selfTopConstraint.constant = self.frame.size.height - height;
    _headerHeightConstraint.constant = [self headerHeightFormula:height];
    _defaultContentView.alpha = [self alphaFormula:height];
    _fullContentView.alpha = [self reversedAlphaFormula:height];
}

- (void) animateToHeight:(CGFloat) height {
    [self.superview layoutIfNeeded];
    [UIView animateWithDuration:0.3 animations:^{
        //self.transform = CGAffineTransformMakeTranslation(0, self.frame.size.height - height);
        self.selfTopConstraint.constant = self.frame.size.height - height;
        self.headerHeightConstraint.constant = [self headerHeightFormula:height];
        self.defaultContentView.alpha = [self alphaFormula:height];
        self.fullContentView.alpha = [self reversedAlphaFormula:height];
        [self.superview layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (self.defaultContentView.alpha == 0.0) {
            [self.defaultContentView setHidden:YES];
        }
        if (self.fullContentView.alpha == 0.0) {
            [self.fullContentView setHidden:YES];
        }
    }];
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    MWZUICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    if (!cell) {
        cell = [[MWZUICollectionViewCell alloc] init];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.mock.imageUrls[indexPath.row]]];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (imgData)
            {
                //Load the data into an UIImage:
                UIImage *image = [UIImage imageWithData:imgData];

                //Check if your image loaded successfully:
                if (image)
                {
                    [cell.superview layoutSubviews];
                    [UIView animateWithDuration:0.15 animations:^{
                        cell.imageView.alpha = 0;
                                        } completion:^(BOOL finished) {
                                            cell.imageView.image = image;
                                            [UIView animateWithDuration:0.15 animations:^{
                                                cell.imageView.alpha = 1;
                                            }];
                                        }];
                }
                else
                {
                    cell.imageView.image = [UIImage imageNamed:@"imagePlaceholder"
                                                      inBundle:[NSBundle bundleForClass:self.class]
                                 compatibleWithTraitCollection:nil];
                }
            }
            else
            {
                //Failed to get the image data:
                cell.imageView.image = [UIImage imageNamed:@"imagePlaceholder"
                                                  inBundle:[NSBundle bundleForClass:self.class]
                             compatibleWithTraitCollection:nil];
            }
        });
    });
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (!_mock) {
        return 3;
    }
    return [_mock.imageUrls count];
}


- (MWZUIBottomSheetComponents *)requireComponentForPlace:(MWZUIPlaceMock *)mock withDefaultComponents:(MWZUIBottomSheetComponents *)components {
    return components;
}

@end