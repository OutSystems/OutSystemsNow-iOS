//
//  ApplicationTileListController.m
//  HubApp
//
//  Created by engineering on 07/04/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#import "ApplicationTileListController.h"
#import "ApplicationTileCell.h"
#import "Application.h"
#import "ApplicationViewController.h"
#import "DemoInfrastructure.h"
#import "TTTAttributedLabel.h"
#import "OSNavigationController.h"
#import "OSNavigationBarAlert.h"
#import "OfflineSupportController.h"
#import "Reachability.h"

@interface ApplicationTileListController ()

@property (weak, nonatomic) IBOutlet TTTAttributedLabel *noApplicationsAvailable;
@property (strong, nonatomic) NSMutableData *responseBuffer;
@property (strong, nonatomic) NSURL *applicationListURL;
@property (weak, nonatomic) IBOutlet UICollectionView *applicationsTileList;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak, nonatomic) NSData *responseData;

@property (strong,nonatomic) OSNavigationBarAlert *navBarAlert;
@property (strong, nonatomic) IBOutlet UIView *applicationListView;

@property (strong, nonatomic) Reachability *reachability;
@property BOOL isViewVisible;
@end

@implementation ApplicationTileListController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.applicationsTileList.hidden = YES;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
     
     [[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(handleNetworkChange:)
     name:kReachabilityChangedNotification object:nil];
     
    _navBarAlert = [[OSNavigationBarAlert alloc] init];
    
    [self.navigationController.view addSubview:_navBarAlert];
    
    [_navBarAlert createView];
    
    _reachability = [Reachability reachabilityForInternetConnection];
    [_reachability startNotifier];
    
    _isViewVisible = NO;
    
    _imageCache = [[NSCache alloc] init];
    [_imageCache setName:@"imageCache"];
}

-(void)viewWillDisappear:(BOOL)animated{
    [_navBarAlert hideAlert:NO];
}

-(void)viewDidDisappear:(BOOL)animated{
    _isViewVisible = NO;
    [_navBarAlert hideAlert:NO];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)reloadApplicationList {
    int timeoutInSeconds = 30;
    
    [self.loadingIndicator startAnimating];
    
    NSString *applicationListService;
    
    if(self.isDemoEnvironment) {
        applicationListService = [DemoInfrastructure getHostnameForService:@"applications"];
    } else {
        applicationListService = [self.infrastructure getHostnameForService:@"applications"];
    }
    
    self.applicationListURL = [NSURL URLWithString:applicationListService];
    
    
    // get the device dimensions
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    NSString *deviceUDID = [UIDevice currentDevice].identifierForVendor.UUIDString;
    
    NSString *post = [NSString stringWithFormat:@"devicetype=%@&screenWidth=%d&screenHeight=%d&deviceHwId=%@",
                      @"ios",
                      (int)screenBounds.size.width,
                      (int)screenBounds.size.height,
                      deviceUDID]; // hardware unique idenfifier
    
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    NSMutableURLRequest *myRequest = [NSMutableURLRequest requestWithURL:self.applicationListURL
                               // cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                               cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                           timeoutInterval:timeoutInSeconds];
 
    [myRequest setHTTPMethod:@"POST"];
    [myRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [myRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [myRequest setHTTPBody:postData];    
    
    [NSURLConnection connectionWithRequest:myRequest delegate:self];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    // accept invalid certificates for the demo server
    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
    NSInteger errorCode = httpResponse.statusCode;
    NSString *fileMIMEType = [[httpResponse MIMEType] lowercaseString];
    NSLog(@"response is %ld, %@", (long)errorCode, fileMIMEType);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    self.responseData = data;
    NSLog(@"received: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    [self.loadingIndicator stopAnimating];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if(self.responseData != nil) {
        NSError *e = nil;
        NSArray *response = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingMutableContainers error:&e];
        
        // clear previous applications
        [self.applicationList removeAllObjects];
        
        [self.applicationList addObjectsFromArray:response];
        
        if([self.applicationList count] == 0) {
            self.noApplicationsAvailable.hidden = NO;
            self.applicationsTileList.hidden = YES;
        } else {
            self.applicationsTileList.hidden = NO;
            self.noApplicationsAvailable.hidden = YES;
        }
    }
    
    [self.applicationsTileList reloadData];
    [self.loadingIndicator stopAnimating];
}

- (NSMutableArray *) applicationList {
    if(!_applicationList) {
        _applicationList = [[NSMutableArray alloc] init];
    }
    return _applicationList;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.toolbar.hidden = YES;
    
    OSNavigationController *navController = (OSNavigationController*)self.navigationController;
    [navController unlockInterfaceOrientation];

    BOOL networkAvailable = [OfflineSupportController isNetworkAvailable:_infrastructure];
    if(networkAvailable || self.isDemoEnvironment){
        [self hideOfflineMessage:NO];
    }
    else{
        [self showOfflineMessage:NO];
    }
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _isViewVisible = YES;
    
    if(self.isDemoEnvironment && self.applicationList.count == 0) {
        [self reloadApplicationList];
    } else {
        if([self.applicationList count] == 0) {
            self.noApplicationsAvailable.hidden = NO;
            self.applicationsTileList.hidden = YES;
        } else {
            self.applicationsTileList.hidden = NO;
            self.noApplicationsAvailable.hidden = YES;
        }
    }
    
    // check if deep link is valid
    if(self.deepLinkController && [self.deepLinkController hasValidSettings]){
        // proceed according to the deep link operation
        [self.deepLinkController resolveOperation:self];
    }
        
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)numberOfSectionsInCollectionView:
(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    return self.applicationList.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *simpleCellIdentifier = @"AppTileCell";

    ApplicationTileCell *cell = [collectionView
                                dequeueReusableCellWithReuseIdentifier:simpleCellIdentifier
                                forIndexPath:indexPath];
    
    if(![[UIDevice currentDevice].model hasPrefix:@"iPhone"])
    {
        [cell.layer setBorderWidth:0.5];
        [cell.layer setBorderColor:[UIColor grayColor].CGColor];
        cell.layer.cornerRadius = 10;
    }
    
    cell.applicationName.text = [[_applicationList objectAtIndex:indexPath.row] objectForKey:@"name"];
    cell.applicationDescription.text = [[_applicationList objectAtIndex:indexPath.row] objectForKey:@"description"];
    
    if(cell.applicationDescription.text.length == 0) {
        cell.applicationDescription.text = @"(no description)";
    }
    
    cell.applicationName.font = [UIFont fontWithName:@"OpenSans-Light" size:cell.applicationName.font.pointSize];

    int imageID = [[[_applicationList objectAtIndex:indexPath.row] objectForKey:@"imageId"] intValue];
    
    
    if(imageID != 0) {
        
        NSString *applicationImageService;
        
        if(self.isDemoEnvironment) {
            applicationImageService = [DemoInfrastructure getHostnameForService:@"applicationImage"];
        } else {
            applicationImageService = [self.infrastructure getHostnameForService:@"applicationImage"];
        }
        
        
        UIImage *cachedImage = [self.imageCache objectForKey: [NSNumber numberWithInteger:imageID]];
        
        if (cachedImage)
        {
            cell.applicationImage.image = cachedImage;
        }
        else
        {
        
            NSString * urlString = [NSString stringWithFormat:@"%@?id=%d",
                                    applicationImageService,
                                    imageID];
            NSURL* url = [NSURL URLWithString:urlString];
            
            int timeoutInSeconds = 30;
            
            NSURLRequest* request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:timeoutInSeconds];
            [NSURLConnection sendAsynchronousRequest:request
                                               queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse * response,
                                                       NSData * data,
                                                       NSError * error) {
                                       if (!error){
                                           cell.applicationImage.image = [[UIImage alloc] initWithData:data];
                                           
                                           [self.imageCache setObject:cell.applicationImage.image forKey:[NSNumber numberWithInteger:imageID]];
                                       }
                                       else {
                                           // set default
                                           cell.applicationImage.image = [UIImage imageNamed:@"NoAppImage.png"];
                                           cell.layer.shouldRasterize = YES;
                                           cell.layer.rasterizationScale = [UIScreen mainScreen].scale;
                                           
                                           [self.imageCache setObject:cell.applicationImage.image forKey:[NSNumber numberWithInteger:imageID]];
                                       }
                                   }];
        }
        
    } else {
        // set default image
        cell.applicationImage.image = [UIImage imageNamed:@"NoAppImage.png"];
        cell.layer.shouldRasterize = YES;
        cell.layer.rasterizationScale = [UIScreen mainScreen].scale;
    }
    
    cell.applicationImage.layer.cornerRadius = 5;
    
    return cell;
}


- (void)viewWillLayoutSubviews;
{
    [super viewWillLayoutSubviews];
    UICollectionViewFlowLayout *flowLayout = (id)self.applicationsTileList.collectionViewLayout;
    
    if([[UIDevice currentDevice].model hasPrefix:@"iPhone"])
    {
        if (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
            flowLayout.itemSize = CGSizeMake((self.applicationsTileList.frame.size.width / 4) - 1, 130);
        } else {
            flowLayout.itemSize = CGSizeMake((self.applicationsTileList.frame.size.width / 2) - 0.5, 130);
        }
        
        flowLayout.minimumInteritemSpacing = 1;
        flowLayout.minimumLineSpacing = 1;
        
    } else {
        if (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
            flowLayout.itemSize = CGSizeMake((self.applicationsTileList.frame.size.width / 3) - 10, 121);
        } else {
            flowLayout.itemSize = CGSizeMake((self.applicationsTileList.frame.size.width / 2) - 10, 121);
        }
        
        flowLayout.minimumInteritemSpacing = 10;
        flowLayout.minimumLineSpacing = 20;
    }

    [flowLayout invalidateLayout]; //force the elements to get laid out again with the new size
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *applicationHostname;
    
    if(self.isDemoEnvironment) {
        applicationHostname = DemoInfrastructure.hostname;
    } else {
        applicationHostname = self.infrastructure.hostname;
    }
    
    if ([[segue identifier] isEqualToString:@"OpenApplicationSegue"])
    {
        ApplicationViewController *appViewController =
        [segue destinationViewController];
        
        appViewController.isSingleApplication = NO;
        
        NSArray *myIndexPath = [self.applicationsTileList indexPathsForSelectedItems];
            
        long row = [myIndexPath[0] row];
            
        appViewController.application = [Application initWithJSON:[self.applicationList objectAtIndex:row] forHost:applicationHostname];
        appViewController.infrastructure = self.infrastructure;
    }
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{    
    [self performSegueWithIdentifier:@"OpenApplicationSegue" sender:self];
}


#pragma mark - Navigation Bar Alert
-(void)showNavigationBarAlert:(NSString*)message animated:(BOOL)animated{
    [_navBarAlert showAlert:message animated:animated];
}

-(void)hideNavigationBarAlert:(BOOL)animated{
    [_navBarAlert hideAlert:animated];
}


#pragma mark - Offline Support

- (void)handleNetworkChange:(NSNotification *)notice{
    NetworkStatus status = [_reachability currentReachabilityStatus];
    
        if (status == NotReachable) {
            NSLog(@"Network status: Offline");
            if(_isViewVisible)
                [self showOfflineMessage:YES];
            
        } else {
            NSLog(@"Network status: Online");
            if(_isViewVisible)
                [self hideOfflineMessage:YES];
        }
    
}

-(void)showOfflineMessage:(BOOL)animated{
    [self showNavigationBarAlert:@"Working Offline" animated:animated];

}

-(void)hideOfflineMessage:(BOOL)animated{
    [self hideNavigationBarAlert:animated];
}


// Handle device orientation changes
- (void)deviceOrientationDidChange: (NSNotification *)notification{
    [_navBarAlert navigationBarHeightChange:self.navigationController.navigationBar.frame.size.height];
}

@end
