//
//  QBAssetCollectionViewController.m
//  QBImagePickerController
//
//  Created by questbeat on 2013/01/21.
//  Copyright (c) 2013年 Katsuma Tanaka. All rights reserved.
//

#import "QBAssetCollectionViewController.h"

// Views
#import "QBImagePickerAssetCell.h"
#import "QBImagePickerFooterView.h"

@interface QBAssetCollectionViewController ()

@property (nonatomic, retain) NSMutableArray *assets;
@property (nonatomic, retain) NSMutableOrderedSet *selectedAssets;

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UIBarButtonItem *doneButton;

- (void)reloadData;
- (void)updateRightBarButtonItem;
- (void)done;
- (void)cancel;

@end

@implementation QBAssetCollectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self) {
        /* Initialization */
        self.assets = [NSMutableArray array];
        self.selectedAssets = [NSMutableOrderedSet orderedSet];
        
        self.imageSize = CGSizeMake(75, 75);
        
        // Table View
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.allowsSelection = YES;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.view addSubview:tableView];
        self.tableView = tableView;
        [tableView release];
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Reload
    [self reloadData];
    
    if(self.fullScreenLayoutEnabled) {
        // Set bar styles
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationController.navigationBar.translucent = YES;
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:NO];
        
        CGFloat top = 0;
        if(![[UIApplication sharedApplication] isStatusBarHidden]) top = top + 20;
        if(!self.navigationController.navigationBarHidden) top = top + 44;
        self.tableView.contentInset = UIEdgeInsetsMake(top, 0, 0, 0);
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(top, 0, 0, 0);
        
        [self setWantsFullScreenLayout:YES];
    }
    
    // Scroll to bottom
    [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height) animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Flash scroll indicators
    [self.tableView flashScrollIndicators];
}

- (void)setShowsCancelButton:(BOOL)showsCancelButton
{
    _showsCancelButton = showsCancelButton;
    
    [self updateRightBarButtonItem];
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection
{
    _allowsMultipleSelection = allowsMultipleSelection;
    
    [self updateRightBarButtonItem];
}

- (void)dealloc
{
    [_assetsGroup release];
    
    [_assets release];
    [_selectedAssets release];
    
    [_tableView release];
    [_doneButton release];
    
    [super dealloc];
}


#pragma mark - Instance Methods

- (void)reloadData
{
    // Reload assets
    [self.assetsGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if(result) {
            [self.assets addObject:result];
        }
    }];
    
    [self.tableView reloadData];
    
    // Set footer view
    if(self.filterType == QBImagePickerFilterTypeAllAssets && [self.delegate respondsToSelector:@selector(assetCollectionViewController:descriptionForNumberOfPhotos:numberOfVideos:)]) {
        [self.assetsGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
        NSUInteger numberOfPhotos = self.assetsGroup.numberOfAssets;
        
        [self.assetsGroup setAssetsFilter:[ALAssetsFilter allVideos]];
        NSUInteger numberOfVideos = self.assetsGroup.numberOfAssets;
        
        [self.assetsGroup setAssetsFilter:[ALAssetsFilter allAssets]];
        
        QBImagePickerFooterView *footerView = [[QBImagePickerFooterView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 48)];
        footerView.titleLabel.text = [self.delegate assetCollectionViewController:self descriptionForNumberOfPhotos:numberOfPhotos numberOfVideos:numberOfVideos];
        
        self.tableView.tableFooterView = footerView;
        [footerView release];
    } else {
        QBImagePickerFooterView *footerView = [[QBImagePickerFooterView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 4)];
        
        self.tableView.tableFooterView = footerView;
        [footerView release];
    }
}

- (void)updateRightBarButtonItem
{
    if(self.allowsMultipleSelection) {
        // Set done button
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
        doneButton.enabled = NO;
        
        [self.navigationItem setRightBarButtonItem:doneButton animated:NO];
        self.doneButton = doneButton;
        [doneButton release];
    } else if(self.showsCancelButton) {
        // Set cancel button
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
        
        [self.navigationItem setRightBarButtonItem:cancelButton animated:NO];
        [cancelButton release];
    } else {
        [self.navigationItem setRightBarButtonItem:nil animated:NO];
    }
}

- (void)done
{
    [self.delegate assetCollectionViewController:self didFinishPickingAssets:self.selectedAssets.array];
}

- (void)cancel
{
    [self.delegate assetCollectionViewControllerDidCancel:self];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRowsInSection = 0;
    
    switch(section) {
        case 0: case 1:
        {
            numberOfRowsInSection = (self.allowsMultipleSelection) ? 1 : 0;
        }
            break;
        case 2:
        {
            NSInteger numberOfAssetsInRow = self.view.bounds.size.width / self.imageSize.width;
            numberOfRowsInSection = self.assets.count / numberOfAssetsInRow;
            if((self.assets.count - numberOfRowsInSection * numberOfAssetsInRow) > 0) numberOfRowsInSection++;
        }
            break;
    }
    
    return numberOfRowsInSection;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    switch(indexPath.section) {
        case 0:
        {
            NSString *cellIdentifier = @"HeaderCell";
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if(cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            }
            
            if(self.selectedAssets.count == self.assets.count) {
                cell.textLabel.text = @"すべての写真の選択を解除";
                
                // Set accessory view
                UIImageView *accessoryView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 23, 23)];
                accessoryView.image = [UIImage imageNamed:@"QBImagePickerController.bundle/minus.png"];
                
                accessoryView.layer.shadowColor = [[UIColor colorWithWhite:0 alpha:1.0] CGColor];
                accessoryView.layer.shadowOpacity = 0.70;
                accessoryView.layer.shadowOffset = CGSizeMake(0, 1.4);
                accessoryView.layer.shadowRadius = 2;
                
                cell.accessoryView = accessoryView;
                [accessoryView release];
            } else {
                cell.textLabel.text = @"すべての写真を選択";
                
                // Set accessory view
                UIImageView *accessoryView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 23, 23)];
                accessoryView.image = [UIImage imageNamed:@"QBImagePickerController.bundle/plus.png"];
                
                accessoryView.layer.shadowColor = [[UIColor colorWithWhite:0 alpha:1.0] CGColor];
                accessoryView.layer.shadowOpacity = 0.70;
                accessoryView.layer.shadowOffset = CGSizeMake(0, 1.4);
                accessoryView.layer.shadowRadius = 2;
                
                cell.accessoryView = accessoryView;
                [accessoryView release];
            }
        }
            break;
        case 1:
        {
            NSString *cellIdentifier = @"HeaderCell";
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if(cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                // Set background view
                UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 1)];
                backgroundView.backgroundColor = [UIColor colorWithWhite:0.878 alpha:1.0];
                
                cell.backgroundView = backgroundView;
                [backgroundView release];
            }
        }
            break;
        case 2:
        {
            NSString *cellIdentifier = @"SeparatorCell";
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if(cell == nil) {
                NSInteger numberOfAssetsInRow = self.view.bounds.size.width / self.imageSize.width;
                CGFloat margin = round((self.view.bounds.size.width - self.imageSize.width * numberOfAssetsInRow) / (numberOfAssetsInRow + 1));
                
                cell = [[[QBImagePickerAssetCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier imageSize:self.imageSize numberOfAssets:numberOfAssetsInRow margin:margin] autorelease];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                [(QBImagePickerAssetCell *)cell setDelegate:self];
                [(QBImagePickerAssetCell *)cell setAllowsMultipleSelection:self.allowsMultipleSelection];
            }
            
            // Set assets
            NSInteger numberOfAssetsInRow = self.view.bounds.size.width / self.imageSize.width;
            NSInteger offset = numberOfAssetsInRow * indexPath.row;
            NSInteger numberOfAssetsToSet = (offset + numberOfAssetsInRow > self.assets.count) ? (self.assets.count - offset) : numberOfAssetsInRow;
            
            NSMutableArray *assets = [NSMutableArray array];
            for(NSUInteger i = 0; i < numberOfAssetsToSet; i++) {
                ALAsset *asset = [self.assets objectAtIndex:(offset + i)];
                
                [assets addObject:asset];
            }
            
            [(QBImagePickerAssetCell *)cell setAssets:assets];
            
            // Set selection states
            for(NSUInteger i = 0; i < numberOfAssetsToSet; i++) {
                ALAsset *asset = [self.assets objectAtIndex:(offset + i)];
                
                if([self.selectedAssets containsObject:asset]) {
                    [(QBImagePickerAssetCell *)cell selectAssetAtIndex:i];
                }
            }
        }
            break;
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat heightForRow = 0;
    
    switch(indexPath.section) {
        case 0:
        {
            heightForRow = 44;
        }
            break;
        case 1:
        {
            heightForRow = 1;
        }
            break;
        case 2:
        {
            NSInteger numberOfAssetsInRow = self.view.bounds.size.width / self.imageSize.width;
            CGFloat margin = round((self.view.bounds.size.width - self.imageSize.width * numberOfAssetsInRow) / (numberOfAssetsInRow + 1));
            heightForRow = margin + self.imageSize.height;
        }
            break;
    }
    
    return heightForRow;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0 && indexPath.row == 0) {
        if(self.selectedAssets.count == self.assets.count) {
            // Deselect all assets
            for(NSUInteger i = 0; i < [tableView numberOfRowsInSection:2]; i++) {
                QBImagePickerAssetCell *cell = (QBImagePickerAssetCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:2]];
                [cell deselectAllAssets];
            }
        } else {
            // Select all assets
            for(NSUInteger i = 0; i < [tableView numberOfRowsInSection:2]; i++) {
                QBImagePickerAssetCell *cell = (QBImagePickerAssetCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:2]];
                [cell selectAllAssets];
            }
        }
        
        // Update header text
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        // Cancel table view selection
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}


#pragma mark - QBImagePickerAssetCellDelegate

- (BOOL)assetCell:(QBImagePickerAssetCell *)assetCell canSelectAssetAtIndex:(NSUInteger)index
{
    BOOL canSelect = YES;
    
    if(self.allowsMultipleSelection && self.limitMaximumNumberOfSelection) {
        canSelect = (self.selectedAssets.count < self.maximumNumberOfSelection);
    }
    
    return canSelect;
}

- (void)assetCell:(QBImagePickerAssetCell *)assetCell didChangeAssetSelectionState:(BOOL)selected atIndex:(NSUInteger)index
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:assetCell];
    
    NSInteger numberOfAssetsInRow = self.view.bounds.size.width / self.imageSize.width;
    NSInteger assetIndex = indexPath.row * numberOfAssetsInRow + index;
    ALAsset *asset = [self.assets objectAtIndex:assetIndex];
    
    if(self.allowsMultipleSelection) {
        if(selected) {
            [self.selectedAssets addObject:asset];
        } else {
            [self.selectedAssets removeObject:asset];
        }
        
        if(self.limitMinimumNumberOfSelection) {
            self.doneButton.enabled = (self.selectedAssets.count >= self.minimumNumberOfSelection);
        } else {
            self.doneButton.enabled = (self.selectedAssets.count > 0);
        }
        
        // Update header text
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    } else {
        [self.delegate assetCollectionViewController:self didFinishPickingAsset:asset];
    }
}

@end