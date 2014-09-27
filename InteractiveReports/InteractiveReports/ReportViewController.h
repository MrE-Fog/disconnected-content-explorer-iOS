//
//  ReportViewController.h
//  InteractiveReports
//

#import <UIKit/UIKit.h>
#import "Report.h"
#import "NoteViewController.h"
#import "ReaderViewController.h"
#import <QuickLook/QuickLook.h>

@interface ReportViewController : UIViewController <UISplitViewControllerDelegate, UIScrollViewDelegate, ReaderViewControllerDelegate>
{

}

@property (strong, nonatomic) id detailItem;
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) NSURL *reportURL;
@property (strong, nonatomic) NSString *reportPath;
@property (strong, nonatomic) NSString *reportName;
@property (strong, nonatomic) NSString *reportFormat;
@property (strong, nonatomic) IBOutlet UINavigationItem *navBar;
@property (strong, nonatomic) Report *report;
@property (strong, nonatomic) NSString *srcScheme;
@property (strong, nonatomic) NSURL *srcURL;
@property (strong, nonatomic) NSDictionary *urlParams;
@property (strong, nonatomic) UILabel *unzipStatusLabel;
@property (nonatomic) BOOL singleReport;
@property (nonatomic) BOOL unzipComplete;

@end
