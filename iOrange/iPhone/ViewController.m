//
//  ViewController.m
//  iOrange
//
//  Created by XiangKai Yin on 5/18/15.
//  Copyright (c) 2015 yinxiangkai. All rights reserved.
//

#define DIC_EXPANDED @"expanded" //是否是展开 0收缩 1展开
#define kSectionHeight 50

#import "ViewController.h"
#import "ControllerScanCode.h"
#import "ViewWebSiteButton.h"
#import "ViewHomeSection.h"
#import "ViewGuideSiteButton.h"
#import "ViewCellControl.h"
#import "FilePathUtil.h"
#import "UtaWebView.h"
#import "NSStringEx.h"
#import "ApiConfig.h"

@interface ViewController () <UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate,UITextFieldDelegate>{
  
  __weak IBOutlet UIButton *_buttonSearch;
  __weak IBOutlet UIButton *_buttonTwoCode;
  __weak IBOutlet UITextField *_textFiledContent;
  
  
  __weak IBOutlet UIScrollView *_scrollViewContent;
  
  __weak IBOutlet UIView *_viewHomeOne;
  __weak IBOutlet UIScrollView *_viewHomeTwo;
  __weak IBOutlet UIScrollView *_viewHomeThree;
  __weak IBOutlet UIView *_viewSearch;
  __weak IBOutlet UIView *_viewTouch;
  __weak IBOutlet UIView *_viewMain;
  
  
  UITableView *_tableViewExpend;
  UIPageControl *_pageViewMark;
  UIView *_viewSiteShow;
  
  NSMutableArray *_DataArray;//记录所有section是否伸展
  NSArray *_arrayCateImageName;// 图片名称
  NSArray *_arrayCateName;//section名称
  NSArray *_arrayCateDetail;//详细说明
  NSInteger _lastSection;//记录上一个点击的section
  NSInteger _webSiteHeight;
  NSArray *_arrayContentSite;
  
  
}
@property (nonatomic,strong) __block UtaWebView *webViewMain;
@property (nonatomic,strong)void (^whenTouchEnd) (NSString *);

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.

  [self countMargin];
  [self showGuideSiteInView];
  [self showPageView];
  [self initDataSource];
  [self getCoolSitePath];
}

#pragma mark -
#pragma mark - events

- (void)onGestureSectionWithTop:(UITapGestureRecognizer *)recognizer {
  ViewHomeSection *viewSection = (ViewHomeSection *)[recognizer view];
  NSInteger section = viewSection.tag - 10;
  section = section + 1;
  
  if (_lastSection == section) {
    NSMutableDictionary *dic=[_DataArray objectAtIndex:section-1];
    int expanded=[[dic objectForKey:DIC_EXPANDED] intValue];
    [self collapseOrExpand:section-1 withExpanded:expanded];
    [_tableViewExpend reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationNone];
    _lastSection = section;
    if (expanded == 1) {
      [_tableViewExpend scrollsToTop];
    } else {
      dispatch_time_t when =  dispatch_time(DISPATCH_TIME_NOW, kDuration150ms * NSEC_PER_SEC);
      dispatch_after(when, dispatch_get_main_queue(), ^{
        CGPoint bottomOffset = CGPointMake(0, 44 * 4);
        [_tableViewExpend setContentOffset:bottomOffset animated:YES];
      });
    }
    return;
  }
  for (int i = 1; i<6; i++) {
    if (i != section) {
      [self collapseOrExpand:i-1 withExpanded:YES];
    } else {
      [self collapseOrExpand:i-1 withExpanded:NO];
      _lastSection = section;
    }
    [_tableViewExpend reloadSections:[NSIndexSet indexSetWithIndex:i] withRowAnimation:UITableViewRowAnimationNone];
  }
  dispatch_time_t when =  dispatch_time(DISPATCH_TIME_NOW, kDuration150ms * NSEC_PER_SEC);
  dispatch_after(when, dispatch_get_main_queue(), ^{
    CGPoint bottomOffset = CGPointMake(0, 44 * 4);
    [_tableViewExpend setContentOffset:bottomOffset animated:YES];
  });
}

#pragma mark- public Methods

#pragma mark - private Methods

-(void)collapseOrExpand:(NSInteger)section withExpanded:(BOOL)isExpand{

  NSMutableDictionary *dic=[_DataArray objectAtIndex:section];
  [dic setValue:[NSNumber numberWithInt:!isExpand]forKey:DIC_EXPANDED];
}

- (UIView *)showWebSitesInView {
  
  NSString *pathString = [[NSBundle mainBundle] pathForResource:@"HomeNavSite" ofType:@"plist"];
  NSArray *arraySite = [NSArray arrayWithContentsOfFile:pathString];
  
  int totalloc =3;
  CGFloat appvieww = (CGRectGetWidth(self.view.frame)-30)/3;
  CGFloat appviewh = iPhone5?(0.85*50):50;
  CGFloat margin = (self.view.frame.size.width-totalloc*appvieww)/(totalloc+1);
  CGFloat siteHeight = (appviewh + margin )* totalloc + totalloc * 3;
  
  UIView *viewShow = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _viewHomeOne.width, siteHeight)];
  [viewShow setBackgroundColor:[UIColor clearColor]];
  [_viewHomeOne addSubview:viewShow];
  _viewSiteShow = viewShow;
  
  for (int i = 0 ; i < [arraySite count]; i++) {
    int row=i/totalloc;//行号
    int loc=i%totalloc;//列号
    
    CGFloat appviewx=(margin+appvieww)*loc;
    CGFloat appviewy= (margin+appviewh)*row;
    
    ViewWebSiteButton *viewSiteButton = [[ViewWebSiteButton alloc] initWithFrame:
                                         CGRectMake(appviewx, appviewy, appvieww, appviewh)
                                          WithImgDict:arraySite[i]];
    viewSiteButton.touched = whenTouchEnd;
    [viewShow addSubview:viewSiteButton];
  }

  return viewShow;
}

- (void)countMargin {
  int totalloc =3;
  CGFloat appvieww = (CGRectGetWidth(self.view.frame)-30)/3;
  CGFloat appviewh = iPhone5?(0.85*50):50;
  CGFloat margin = (self.view.frame.size.width-totalloc*appvieww)/(totalloc+1);
  CGFloat siteHeight = (appviewh + margin )* totalloc + totalloc * 3  - margin;
  [self showCategoryTableWithMargin:margin withHeight:siteHeight];
}

- (void)showGuideSiteInView {
  NSString *pathString = [[NSBundle mainBundle] pathForResource:@"HomeGuideSite" ofType:@"plist"];
  NSArray *arraySite = [NSArray arrayWithContentsOfFile:pathString];
  CGFloat widthS = (self.view.width-22*5)/4;
  CGFloat heightS = iPhone5?(0.85 * 90):90;
  CGFloat margin = 22;
  int totalloc = 4;
  
  for (int i = 0; i<[arraySite count]; i++) {
    NSDictionary *dictSite = [arraySite objectAtIndex:i];
    int row = i / totalloc;
    int loc = i % totalloc;
    
    CGFloat appviewx = margin + (margin + widthS) * loc;
    CGFloat appviewy = margin + (margin + heightS) * row;
    
    ViewGuideSiteButton *siteView = [[ViewGuideSiteButton alloc] initWithFrame:CGRectMake(appviewx, appviewy, widthS, heightS) withDict:dictSite];
    siteView.touched = whenTouchEnd;
    [_viewHomeTwo addSubview:siteView];
    if (i == [arraySite count]-1) {
      int row = (i+1) / totalloc;
      int loc = (i+1) % totalloc;
      
      CGFloat appviewW = margin + (margin + widthS) * loc;
      CGFloat appviewH = margin + (margin + heightS) * row;
      ViewGuideSiteButton *siteViewNine = [[ViewGuideSiteButton alloc] initWithFrame:CGRectMake(appviewW, appviewH, widthS, heightS) withIconName:@"home_site_icon9" withSiteName:@""];
      siteViewNine.touched = whenTouchEnd;
      [_viewHomeTwo addSubview:siteViewNine];
    }
  }
  
}

//广告
- (void)showAdvertInView {
  
}

- (void)showCategoryTableWithMargin:(CGFloat)margin withHeight:(CGFloat)siteHeight {
  UITableView *tableCategory = [[UITableView alloc] initWithFrame:CGRectMake(margin, margin, self.view.width-margin * 2, siteHeight + kSectionHeight * 5 ) style:UITableViewStylePlain];
  tableCategory.backgroundColor = [UIColor clearColor];
  [_viewHomeOne addSubview:tableCategory];
  [tableCategory setSeparatorStyle:UITableViewCellSeparatorStyleNone];
  [tableCategory setShowsVerticalScrollIndicator:NO];
//  tableCategory.tableFooterView = [[UIView alloc] init];
  //使向右偏移的线填满
//  [tableCategory setSeparatorInset:UIEdgeInsetsZero];
  tableCategory.delegate = self;
  tableCategory.dataSource = self;
  tableCategory.scrollEnabled = YES;
  _tableViewExpend = tableCategory;
  
}

- (void)showPageView {
  UIPageControl *pageView = [[UIPageControl alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame)-65, CGRectGetWidth(self.view.frame), 8)];
  pageView.currentPageIndicatorTintColor = RGBA(125., 125., 125., 1.);
  pageView.pageIndicatorTintColor = [UIColor blackColor];
  pageView.numberOfPages = 3;
  pageView.currentPage = 0;
  [_viewMain addSubview:pageView];
  _pageViewMark = pageView;
}

static id _aSelf;
- (void)initDataSource {
  _aSelf = self;
  _scrollViewContent.contentSize = CGSizeMake(CGRectGetWidth(self.view.frame)*3, 0);
  _scrollViewContent.pagingEnabled = YES;
  _scrollViewContent.delegate = self;
  _scrollViewContent.showsHorizontalScrollIndicator = NO;
  
  _textFiledContent.delegate = self;
  
  [self loadWebView];
  
  //创建一个数组
  _DataArray=[[NSMutableArray alloc] init];
  for (int i = 0; i<5; i++) {
    NSMutableDictionary *dic=[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:0],DIC_EXPANDED,nil];
    [_DataArray addObject:dic];
  }
  //可以用plist 便于维护
  _arrayCateImageName = @[@"home_image_cool",@"home_image_sevice",@"home_image_movie",@"home_image_baike",@"home_image_now"];
  _arrayCateName = @[@"手机酷站",@"生活服务",@"影视音乐",@"趣味百科",@"最近访问"];
  _arrayCateDetail = @[@"",@"查询.资讯.服务",@"视频.综艺.音乐台",@"笑话.漫画.百科",@""];
  
  int totalloc =3;
  CGFloat appvieww = (CGRectGetWidth(self.view.frame)-30)/3;
  CGFloat appviewh = iPhone5?(0.85*50):50;
  CGFloat margin = (self.view.frame.size.width-totalloc*appvieww)/(totalloc+1);
  CGFloat siteHeight = (appviewh + margin )* totalloc + totalloc * 3 - margin;
  _webSiteHeight = siteHeight;
}

- (void)setLayerRadius:(UIView *)viewRadius rectCorner:(UIRectCorner)corner{
  UIBezierPath *maskPath=  [UIBezierPath bezierPathWithRoundedRect:viewRadius.bounds byRoundingCorners:corner cornerRadii:CGSizeMake(5, 5)];
  CAShapeLayer *maskLayer=[[CAShapeLayer alloc] init];
  maskLayer.frame=viewRadius.bounds;
  maskLayer.path=maskPath.CGPath;
  viewRadius.layer.mask=maskLayer;
  viewRadius.layer.masksToBounds=YES;
}

- (int)isExpanded:(NSInteger)section{
  NSDictionary *dic=[_DataArray objectAtIndex:section];
  int expanded=[[dic objectForKey:DIC_EXPANDED] intValue];
  return expanded;
}

- (void)getCoolSitePath {
  NSString *lastPath = [[NSBundle mainBundle] pathForResource:@"PhoneCoolSite" ofType:@"plist"];
  NSArray *array = [NSArray arrayWithContentsOfFile:lastPath];
  _arrayContentSite = array;
}

- (NSArray  *)arrayCutWithRow:(NSInteger)row withSection:(NSInteger)section {
  NSMutableArray *array = [NSMutableArray array];
  NSArray *sectionArray = [_arrayContentSite objectAtIndex:section-1];
  NSInteger m = 4 * row;

  for (NSInteger i = m; i<sectionArray.count; i++) {
    [array addObject:[sectionArray objectAtIndex:i]];
    if (array.count>=4) {
      return array;
    }
  }
  return array;
}

#pragma mark - 
#pragma mark - Webview Methods

- (void)loadWebView {
  UtaWebView *webView = [[UtaWebView alloc] initWithFrame:CGRectMake(0, _viewSearch.height, self.view.width, self.view.height - _viewSearch.height)];
  [_viewMain addSubview:webView];
  [_viewMain bringSubviewToFront:_viewTouch];
  [webView setHidden:YES];
  _webViewMain = webView;
}

- (void)setWebViewHidden:(BOOL) isHidden withLink:(NSString *)link {
  [_webViewMain setHidden:isHidden];
  [_webViewMain loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:link]]];
}

#pragma mark -  Block Methods

void (^whenTouchEnd)(NSString *) = ^ void (NSString *link) {
  [[_aSelf webViewMain] setHidden:NO];
  [[_aSelf webViewMain] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:link]]];
};

#pragma mark - Systems Methods

- (void)viewDidLayoutSubviews{
  
  [_scrollViewContent.constraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *layConstant, NSUInteger idx, BOOL *stop) {
    if (layConstant.firstItem == _viewHomeOne) {
      if (layConstant.firstAttribute == NSLayoutAttributeWidth) {
        layConstant.constant = _scrollViewContent.width;
      }
      if (layConstant.firstAttribute == NSLayoutAttributeHeight) {
        layConstant.constant = _scrollViewContent.height;
      }
    }
    if (layConstant.firstItem == _viewHomeTwo) {
      if (layConstant.firstAttribute == NSLayoutAttributeWidth) {
        layConstant.constant = _scrollViewContent.width;
      }
      if (layConstant.firstAttribute == NSLayoutAttributeLeft) {
        layConstant.constant = _scrollViewContent.width;
      }
      if (layConstant.firstAttribute == NSLayoutAttributeHeight) {
        layConstant.constant = _scrollViewContent.height;
      }
    }
    if (layConstant.firstItem == _viewHomeThree) {
      if (layConstant.firstAttribute == NSLayoutAttributeWidth) {
        layConstant.constant = _scrollViewContent.width;
      }
      if (layConstant.firstAttribute == NSLayoutAttributeLeft) {
        layConstant.constant = _scrollViewContent.width*2;
      }
    }
  }];
  
  [_scrollViewContent layoutSubviews];
  
}

- (IBAction)onTouchWithShow:(UIButton *)sender {
  switch (sender.tag) {
    case MainHomeButtonTypeHome:
      [_webViewMain loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@""]]];
      [_webViewMain setHidden:YES];
      break;
      
    default:
      break;
  }
}

- (IBAction)onTouchWithScan:(UIButton *)sender {
  ControllerScanCode *scanView = [[ControllerScanCode alloc] init];
  [self presentViewController:scanView animated:YES completion:nil];
}


#pragma mark - 
#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  NSString *link = textField.text;
  if (link.length) {
    if ([link hasPrefix:@"http://itunes.apple.com/"]
        || [link hasPrefix:@"https://itunes.apple.com/"]
        || [link hasPrefix:@"itms-apps://itunes.apple.com/"]) {
      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link]];
      return YES;
    }
    link =  [link getLinkWithText];
    [self setWebViewHidden:NO withLink:link];
    [self.view endEditing:YES];
  }
  return YES;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
  CGFloat f = scrollView.contentOffset.x /scrollView.width;
  _pageViewMark.currentPage = f;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (section == 0) {
    return 0;
  }
  section = section -1;
  NSMutableDictionary *dic=[_DataArray objectAtIndex:section];
  //判断是收缩还是展开
  if ([[dic objectForKey:DIC_EXPANDED]intValue]) {
    return 4;
    
  } else {
    return 0;
  }
  return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 6;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    return _webSiteHeight;
  }
  return kSectionHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell * cell = [[UITableViewCell alloc] initWithFrame:CGRectZero];
  cell.backgroundColor = RGBA(182., 182., 182., 0.5);
  if (indexPath.section == 5) {
    return cell;
  }
  ViewCellControl *viewS = [[ViewCellControl alloc] initWithFrame:CGRectMake(0, 0, tableView.width, cell.height)];
  viewS.touched = whenTouchEnd;
  [cell addSubview:viewS];
  [viewS setArraySite:[self arrayCutWithRow:indexPath.row withSection:indexPath.section]];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    return [self showWebSitesInView];
  }
  section = section-1;
  ViewHomeSection *viewSection = [[ViewHomeSection alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), kSectionHeight) withImageName:_arrayCateImageName[section] withLableName:_arrayCateName[section]];
  [viewSection setIsMarkDown:[self isExpanded:section]];
  [viewSection setBackgroundColor:RGBA(230., 230., 230., 1.)];
  [viewSection.labelDetail setText:_arrayCateDetail[section]];
  
  if (section == 0) {
    //圆角上面两个角
    [self setLayerRadius:viewSection rectCorner: UIRectCornerTopLeft|UIRectCornerTopRight];
    [viewSection setIsHiddenLine:NO];
  } else if (section == 4) {
    [self setLayerRadius:viewSection rectCorner: UIRectCornerBottomLeft|UIRectCornerBottomRight];
    [viewSection setIsHiddenLine:YES];
  } else {
    [viewSection setIsHiddenLine:NO];
  }
  UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                               action:@selector(onGestureSectionWithTop:)];
  viewSection.tag = section+10;
  [viewSection addGestureRecognizer:tapGesture];
  return viewSection;
}

@end
