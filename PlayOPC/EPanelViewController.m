//
//  EPanelViewController.m
//  PlayOPC
//
//  Created by Hiroki Ishiura on 2015/04/25.
//  Copyright (c) 2015 Hiroki Ishiura. All rights reserved.
//
//  Released under the MIT license
//  http://opensource.org/licenses/mit-license.php
//

#import "EPanelViewController.h"
#import "AppDelegate.h"
#import "AppCamera.h"
#import "CameraPropertyValueSelectionViewController.h"
#import "UIViewController+Alert.h"
#import "UIViewController+Threading.h"
#import "UITableViewController+Cell.h"

@interface EPanelViewController () <OLYCameraPropertyDelegate, ItemSelectionViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableViewCell *showApertureCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *showShutterCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *showExprevCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *showIsoCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *showTakemodeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *showExposeMovieSelectCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *showTakeDriveCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *showContinuousShootingVelocityCell;

@property (assign, nonatomic) BOOL startingActivity; ///< 画面を表示して活動を開始しているか否か
@property (strong, nonatomic) NSMutableDictionary *cameraPropertyObserver; ///< 監視するカメラプロパティ名とメソッド名の辞書

@end

#pragma mark -

@implementation EPanelViewController

#pragma mark -

- (void)viewDidLoad {
	DEBUG_LOG(@"");
	[super viewDidLoad];

	// ビューコントローラーの活動状態を初期化します。
	self.startingActivity = NO;

	// 監視するカメラプロパティ名とそれに紐づいた対応処理(メソッド名)を対とする辞書を用意して、
	// Objective-CのKVOチックに、カメラプロパティに変化があったらその個別処理を呼び出せるようにしてみます。
	NSMutableDictionary *cameraPropertyObserver = [[NSMutableDictionary alloc] init];
	[cameraPropertyObserver setObject:NSStringFromSelector(@selector(didChangeAperture)) forKey:CameraPropertyAperture];
	[cameraPropertyObserver setObject:NSStringFromSelector(@selector(didChangeShutter)) forKey:CameraPropertyShutter];
	[cameraPropertyObserver setObject:NSStringFromSelector(@selector(didChangeExprev)) forKey:CameraPropertyExprev];
	[cameraPropertyObserver setObject:NSStringFromSelector(@selector(didChangeIso)) forKey:CameraPropertyIso];
	[cameraPropertyObserver setObject:NSStringFromSelector(@selector(didChangeTakemode)) forKey:CameraPropertyTakemode];
	[cameraPropertyObserver setObject:NSStringFromSelector(@selector(didChangeExposeMovieSelect)) forKey:CameraPropertyExposeMovieSelect];
	[cameraPropertyObserver setObject:NSStringFromSelector(@selector(didChangeTakeDrive)) forKey:CameraPropertyTakeDrive];
	[cameraPropertyObserver setObject:NSStringFromSelector(@selector(didChangeContinuousShootingVelocity)) forKey:CameraPropertyContinuousShootingVelocity];
	self.cameraPropertyObserver = cameraPropertyObserver;
	// カメラプロパティ、カメラのプロパティを監視開始します。
	AppCamera *camera = GetAppCamera();
	[camera addCameraPropertyDelegate:self];
	[camera addObserver:self forKeyPath:CameraPropertyActualApertureValue options:0 context:@selector(didChangeActualApertureValue:)];
	[camera addObserver:self forKeyPath:CameraPropertyActualShutterSpeed options:0 context:@selector(didChangeActualShutterSpeed:)];
	[camera addObserver:self forKeyPath:CameraPropertyActualExposureCompensation options:0 context:@selector(didChangeActualExposureCompensation:)];
	[camera addObserver:self forKeyPath:CameraPropertyActualIsoSensitivity options:0 context:@selector(didChangeActualIsoSensitivity:)];
	
	// 画面表示を初期表示します。
	NSString *apertureTitle = [camera cameraPropertyLocalizedTitle:CameraPropertyAperture];
	NSString *shutterTitle = [camera cameraPropertyLocalizedTitle:CameraPropertyShutter];
	NSString *exprevTitle = [camera cameraPropertyLocalizedTitle:CameraPropertyExprev];
	NSString *isoTitle = [camera cameraPropertyLocalizedTitle:CameraPropertyIso];
	NSString *takemodeTitle = [camera cameraPropertyLocalizedTitle:CameraPropertyTakemode];
	NSString *exposeMovieSelectTitle = [camera cameraPropertyLocalizedTitle:CameraPropertyExposeMovieSelect];
	NSString *takeDriveTitle = [camera cameraPropertyLocalizedTitle:CameraPropertyTakeDrive];
	NSString *continuousShootingVelocityTitle = [camera cameraPropertyLocalizedTitle:CameraPropertyContinuousShootingVelocity];
	self.showApertureCell.textLabel.text = apertureTitle;
	self.showShutterCell.textLabel.text = shutterTitle;
	self.showExprevCell.textLabel.text = exprevTitle;
	self.showIsoCell.textLabel.text = isoTitle;
	self.showTakemodeCell.textLabel.text = takemodeTitle;
	self.showExposeMovieSelectCell.textLabel.text = exposeMovieSelectTitle;
	self.showTakeDriveCell.textLabel.text = takeDriveTitle;
	self.showContinuousShootingVelocityCell.textLabel.text = continuousShootingVelocityTitle;
	NSString *emptyDetailTextLabel = @" "; // テーブルセルのラベルを空欄にしょうとしてnilとか@""とかを設定するとなぜか不具合が起きます。
	self.showApertureCell.detailTextLabel.text = emptyDetailTextLabel;
	self.showShutterCell.detailTextLabel.text = emptyDetailTextLabel;
	self.showExprevCell.detailTextLabel.text = emptyDetailTextLabel;
	self.showIsoCell.detailTextLabel.text = emptyDetailTextLabel;
	self.showTakemodeCell.detailTextLabel.text = emptyDetailTextLabel;
	self.showExposeMovieSelectCell.detailTextLabel.text = emptyDetailTextLabel;
	self.showTakeDriveCell.detailTextLabel.text = emptyDetailTextLabel;
	self.showContinuousShootingVelocityCell.detailTextLabel.text = emptyDetailTextLabel;
	[self tableViewCell:self.showApertureCell enabled:NO];
	[self tableViewCell:self.showShutterCell enabled:NO];
	[self tableViewCell:self.showExprevCell enabled:NO];
	[self tableViewCell:self.showIsoCell enabled:NO];
	[self tableViewCell:self.showTakemodeCell enabled:NO];
	[self tableViewCell:self.showExposeMovieSelectCell enabled:NO];
	[self tableViewCell:self.showTakeDriveCell enabled:NO];
	[self tableViewCell:self.showContinuousShootingVelocityCell enabled:NO];
}

- (void)didReceiveMemoryWarning {
	DEBUG_LOG(@"");
	[super didReceiveMemoryWarning];
}

- (void)dealloc {
	DEBUG_LOG(@"");
	
	AppCamera *camera = GetAppCamera();
	[camera removeObserver:self forKeyPath:CameraPropertyActualApertureValue];
	[camera removeObserver:self forKeyPath:CameraPropertyActualShutterSpeed];
	[camera removeObserver:self forKeyPath:CameraPropertyActualExposureCompensation];
	[camera removeObserver:self forKeyPath:CameraPropertyActualIsoSensitivity];
	[camera removeCameraPropertyDelegate:self];
	_cameraPropertyObserver = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	DEBUG_LOG(@"");
	[super viewWillAppear:animated];
	
	// MARK: セグエで遷移して戻ってくるとたまに自動で行選択が解除されないようです。
	NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
	if (indexPath) {
		[self.tableView deselectRowAtIndexPath:indexPath animated:animated];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	DEBUG_LOG(@"");
	[super viewDidAppear:animated];

	if (self.isMovingToParentViewController) {
		[self didStartActivity];
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	DEBUG_LOG(@"");
	[super viewDidDisappear:animated];
	
	if (self.isMovingFromParentViewController) {
		[self didFinishActivity];
	}
}

#pragma mark -

/// ビューコントローラーが画面を表示して活動を開始する時に呼び出されます。
- (void)didStartActivity {
	DEBUG_LOG(@"");
	
	// すでに活動開始している場合は何もしません。
	if (self.startingActivity) {
		return;
	}

	// 表示を更新します。
	[self updateShowApertureCell];
	[self updateShowShutterCell];
	[self updateShowExprevCell];
	[self updateShowIsoCell];
	[self updateShowTakemodeCell];
	[self updateShowExposeMovieSelectCell];
	[self updateShowTakeDriveCell];
	[self updateShowContinuousShootingVelocityCell];
	
	// ビューコントローラーが活動を開始しました。
	self.startingActivity = YES;
}

/// ビューコントローラーが画面を破棄して活動を完了する時に呼び出されます。
- (void)didFinishActivity {
	DEBUG_LOG(@"");

	// すでに活動停止している場合は何もしません。
	if (!self.startingActivity) {
		return;
	}

	// 表示を更新します。
	[self tableViewCell:self.showApertureCell enabled:NO];
	[self tableViewCell:self.showShutterCell enabled:NO];
	[self tableViewCell:self.showExprevCell enabled:NO];
	[self tableViewCell:self.showIsoCell enabled:NO];
	[self tableViewCell:self.showTakemodeCell enabled:NO];
	[self tableViewCell:self.showExposeMovieSelectCell enabled:NO];
	[self tableViewCell:self.showTakeDriveCell enabled:NO];
	[self tableViewCell:self.showContinuousShootingVelocityCell enabled:NO];
	
	// ビューコントローラーが活動を停止しました。
	self.startingActivity = NO;
}

#pragma mark -

/// セグエを準備する(画面が遷移する)時に呼び出されます。
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	DEBUG_LOG(@"segue=%@", segue);
	
	// セグエに応じた画面遷移の準備処理を呼び出します。
	NSString *segueIdentifier = segue.identifier;
	if ([segueIdentifier isEqualToString:@"ShowAperture"]) {
		CameraPropertyValueSelectionViewController *viewController = segue.destinationViewController;
		viewController.property = CameraPropertyAperture;
		viewController.itemSelectionDeleage = self;
	} else if ([segueIdentifier isEqualToString:@"ShowShutter"]) {
		CameraPropertyValueSelectionViewController *viewController = segue.destinationViewController;
		viewController.property = CameraPropertyShutter;
		viewController.itemSelectionDeleage = self;
	} else if ([segueIdentifier isEqualToString:@"ShowExprev"]) {
		CameraPropertyValueSelectionViewController *viewController = segue.destinationViewController;
		viewController.property = CameraPropertyExprev;
		viewController.itemSelectionDeleage = self;
	} else if ([segueIdentifier isEqualToString:@"ShowIso"]) {
		CameraPropertyValueSelectionViewController *viewController = segue.destinationViewController;
		viewController.property = CameraPropertyIso;
		viewController.itemSelectionDeleage = self;
	} else if ([segueIdentifier isEqualToString:@"ShowTakemode"]) {
		CameraPropertyValueSelectionViewController *viewController = segue.destinationViewController;
		viewController.property = CameraPropertyTakemode;
		viewController.itemSelectionDeleage = self;
	} else if ([segueIdentifier isEqualToString:@"ShowExposeMovieSelect"]) {
		CameraPropertyValueSelectionViewController *viewController = segue.destinationViewController;
		viewController.property = CameraPropertyExposeMovieSelect;
		viewController.itemSelectionDeleage = self;
	} else if ([segueIdentifier isEqualToString:@"ShowTakeDrive"]) {
		CameraPropertyValueSelectionViewController *viewController = segue.destinationViewController;
		viewController.property = CameraPropertyTakeDrive;
		viewController.itemSelectionDeleage = self;
	} else if ([segueIdentifier isEqualToString:@"ShowContinuousShootingVelocity"]) {
		CameraPropertyValueSelectionViewController *viewController = segue.destinationViewController;
		viewController.property = CameraPropertyContinuousShootingVelocity;
		viewController.itemSelectionDeleage = self;
	} else {
		// 何もしません。
	}
}

/// カメラプロパティ値選択ビューコントローラで値が選択されると呼び出されます。
- (void)itemSelectionViewController:(ItemSelectionViewController *)controller didSelectedItemIndex:(NSUInteger)index {
	DEBUG_LOG(@"index=%ld", (long)index);
	
	// カメラプロパティに応じた処理を呼び出します。
	NSString *property = ((CameraPropertyValueSelectionViewController *)controller).property;
	if ([property isEqualToString:CameraPropertyAperture]) {
		[self didChangeAperture];
	} else if ([property isEqualToString:CameraPropertyShutter]) {
		[self didChangeShutter];
	} else if ([property isEqualToString:CameraPropertyExprev]) {
		[self didChangeExprev];
	} else if ([property isEqualToString:CameraPropertyIso]) {
		[self didChangeIso];
	} else if ([property isEqualToString:CameraPropertyTakemode]) {
		[self didChangeTakemode];
	} else if ([property isEqualToString:CameraPropertyExposeMovieSelect]) {
		[self didChangeExposeMovieSelect];
	} else if ([property isEqualToString:CameraPropertyTakeDrive]) {
		[self didChangeTakeDrive];
	} else if ([property isEqualToString:CameraPropertyContinuousShootingVelocity]) {
		[self didChangeContinuousShootingVelocity];
	} else {
		DEBUG_LOG(@"Unknown property: %@", property);
	}
}

/// キー値監視機構によって呼び出されます。
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	DEBUG_DETAIL_LOG(@"keyPath=%@", keyPath);
	
	// すでに活動停止している場合や何かの誤りでセレクタが取得できない場合は何もしません。
	if (!self.startingActivity) {
		return;
	}
	SEL selector = (SEL)context;
	if (!selector || ![self respondsToSelector:selector]) {
		return;
	}
	
	// メインスレッドでイベントハンドラを呼び出します。
	if ([NSThread isMainThread]) {
		[self performSelector:selector withObject:change afterDelay:0];
	} else {
		__weak EPanelViewController *weakSelf = self;
		[weakSelf executeAsynchronousBlockOnMainThread:^{
			DEBUG_LOG(@"weakSelf=%p", weakSelf);
			[weakSelf performSelector:selector withObject:change afterDelay:0];
		}];
	}
}

/// カメラプロパティの値に変更があった時に呼び出されます。
- (void)camera:(OLYCamera *)camera didChangeCameraProperty:(NSString *)name {
	DEBUG_LOG(@"name=%@", name);
	
	// すでに活動停止している場合や何かの誤りでセレクタが取得できない場合は何もしません。
	if (!self.startingActivity) {
		return;
	}
	SEL selector = NSSelectorFromString(self.cameraPropertyObserver[name]);
	if (!selector || ![self respondsToSelector:selector]) {
		return;
	}
	
	// メインスレッドでイベントハンドラを呼び出します。
	if ([NSThread isMainThread]) {
		[self performSelector:selector withObject:nil afterDelay:0];
	} else {
		__weak EPanelViewController *weakSelf = self;
		[weakSelf executeAsynchronousBlockOnMainThread:^{
			DEBUG_LOG(@"weakSelf=%p", weakSelf);
			[weakSelf performSelector:selector withObject:nil afterDelay:0];
		}];
	}
}

#pragma mark -

/// カメラおよびレンズで使用しているF値の値が変わった時に呼び出されます。
- (void)didChangeActualApertureValue:(NSDictionary *)change {
	DEBUG_LOG(@"");
	
	// 画面表示を更新します。
	[self updateShowApertureCell];
}

/// カメラで使用しているシャッター速度の値が変わった時に呼び出されます。
- (void)didChangeActualShutterSpeed:(NSDictionary *)change {
	DEBUG_LOG(@"");
	
	// 画面表示を更新します。
	[self updateShowShutterCell];
}

/// カメラで使用している露出補正値の値が変わった時に呼び出されます。
- (void)didChangeActualExposureCompensation:(NSDictionary *)change {
	DEBUG_LOG(@"");
	
	// 画面表示を更新します。
	[self updateShowExprevCell];
}

/// カメラで使用しているISO感度の値が変わった時に呼び出されます。
- (void)didChangeActualIsoSensitivity:(NSDictionary *)change {
	DEBUG_LOG(@"");
	
	// 画面表示を更新します。
	[self updateShowIsoCell];
}

/// 絞り値の値が変わった時に呼び出されます。
- (void)didChangeAperture {
	DEBUG_LOG(@"");
	
	// 画面表示を更新します。
	[self updateShowApertureCell];
}

/// シャッター速度の値が変わった時に呼び出されます。
- (void)didChangeShutter {
	DEBUG_LOG(@"");
	
	// 画面表示を更新します。
	[self updateShowShutterCell];
}

/// 露出補正値の値が変わった時に呼び出されます。
- (void)didChangeExprev {
	DEBUG_LOG(@"");
	
	// 画面表示を更新します。
	[self updateShowExprevCell];
}

/// ISO感度の値が変わった時に呼び出されます。
- (void)didChangeIso {
	DEBUG_LOG(@"");
	
	// 画面表示を更新します。
	[self updateShowIsoCell];
}

/// 撮影モードの値が変わった時に呼び出されます。
- (void)didChangeTakemode {
	DEBUG_LOG(@"");
	
	// 画面表示を更新します。
	[self updateShowTakemodeCell];
	
	// カメラプロパティの撮影モード(TAKEMODE)が変更されると、その他大勢のカメラプロパティの設定可不可状態が変化するため、
	// 最新のカメラプロパティ値設定可不可を元にそれぞれのセルの有効無効を設定し直します。
	AppCamera *camera = GetAppCamera();
	[self tableViewCell:self.showApertureCell enabled:[camera canSetCameraProperty:CameraPropertyAperture]];
	[self tableViewCell:self.showShutterCell enabled:[camera canSetCameraProperty:CameraPropertyShutter]];
	[self tableViewCell:self.showExprevCell enabled:[camera canSetCameraProperty:CameraPropertyExprev]];
	[self tableViewCell:self.showIsoCell enabled:[camera canSetCameraProperty:CameraPropertyIso]];
	[self tableViewCell:self.showExposeMovieSelectCell enabled:[camera canSetCameraProperty:CameraPropertyExposeMovieSelect]];
	[self tableViewCell:self.showTakeDriveCell enabled:[camera canSetCameraProperty:CameraPropertyTakeDrive]];
	[self tableViewCell:self.showContinuousShootingVelocityCell enabled:[camera canSetCameraProperty:CameraPropertyContinuousShootingVelocity]];
}

/// 動画撮影モードの値が変わった時に呼び出されます。
- (void)didChangeExposeMovieSelect {
	DEBUG_LOG(@"");
	
	// 画面表示を更新します。
	[self updateShowExposeMovieSelectCell];

	// カメラプロパティの動画撮影モード(EXPOSE_MOVIE_SELECT)が変更されると、その他大勢のカメラプロパティの設定可不可状態が変化するため、
	// 最新のカメラプロパティ値設定可不可を元にそれぞれのセルの有効無効を設定し直します。
	AppCamera *camera = GetAppCamera();
	[self tableViewCell:self.showApertureCell enabled:[camera canSetCameraProperty:CameraPropertyAperture]];
	[self tableViewCell:self.showShutterCell enabled:[camera canSetCameraProperty:CameraPropertyShutter]];
	[self tableViewCell:self.showExprevCell enabled:[camera canSetCameraProperty:CameraPropertyExprev]];
	[self tableViewCell:self.showIsoCell enabled:[camera canSetCameraProperty:CameraPropertyIso]];
	[self tableViewCell:self.showTakemodeCell enabled:[camera canSetCameraProperty:CameraPropertyTakemode]];
	[self tableViewCell:self.showTakeDriveCell enabled:[camera canSetCameraProperty:CameraPropertyTakeDrive]];
	[self tableViewCell:self.showContinuousShootingVelocityCell enabled:[camera canSetCameraProperty:CameraPropertyContinuousShootingVelocity]];
}

/// ドライブモードの値が変わった時に呼び出されます。
- (void)didChangeTakeDrive {
	DEBUG_LOG(@"");
	
	// 画面表示を更新します。
	[self updateShowTakeDriveCell];
}

/// 連写速度の値が変わった時に呼び出されます。
- (void)didChangeContinuousShootingVelocity {
	DEBUG_LOG(@"");
	
	// 画面表示を更新します。
	[self updateShowContinuousShootingVelocityCell];
}

#pragma mark -

/// 絞り値を表示します。
- (void)updateShowApertureCell {
	DEBUG_LOG(@"");
	
#if 0 // カメラに設定したカメラプロパティ値を表示するならこのブロックを有効にしてください。
	[self updateCameraPropertyCell:self.showApertureCell name:CameraPropertyAperture completion:nil];
#else // カメラが使用している現在値を表示するならこのブロックを有効にしてください。
	AppCamera *camera = GetAppCamera();
	NSString *actualApertureValue = camera.actualApertureValue;
	if (actualApertureValue) {
		NSString *actualApertureValueTitle = [camera cameraPropertyValueLocalizedTitle:actualApertureValue];
		self.showApertureCell.detailTextLabel.text = actualApertureValueTitle;
	} else {
		self.showApertureCell.detailTextLabel.text = NSLocalizedString(@"Unknown", nil);
	}
	[self tableViewCell:self.showApertureCell enabled:[camera canSetCameraProperty:CameraPropertyAperture]];
#endif
}

/// シャッター速度を表示します。
- (void)updateShowShutterCell {
	DEBUG_LOG(@"");
	
#if 0 // カメラに設定したカメラプロパティ値を表示するならこのブロックを有効にしてください。
	[self updateCameraPropertyCell:self.showShutterCell name:CameraPropertyShutter completion:nil];
#else // カメラが使用している現在値を表示するならこのブロックを有効にしてください。
	AppCamera *camera = GetAppCamera();
	NSString *actualShutterSpeed = camera.actualShutterSpeed;
	if (actualShutterSpeed) {
		NSString *actualShutterSpeedTitle = [camera cameraPropertyValueLocalizedTitle:actualShutterSpeed];
		self.showShutterCell.detailTextLabel.text = actualShutterSpeedTitle;
	} else {
		self.showShutterCell.detailTextLabel.text = NSLocalizedString(@"Unknown", nil);
	}
	[self tableViewCell:self.showShutterCell enabled:[camera canSetCameraProperty:CameraPropertyShutter]];
#endif
}

/// 露出補正値を表示します。
- (void)updateShowExprevCell {
	DEBUG_LOG(@"");
	
#if 0 // カメラに設定したカメラプロパティ値を表示するならこのブロックを有効にしてください。
	[self updateCameraPropertyCell:self.showExprevCell name:CameraPropertyExprev completion:nil];
#else // カメラが使用している現在値を表示するならこのブロックを有効にしてください。
	AppCamera *camera = GetAppCamera();
	NSString *actualExposureCompensation = camera.actualExposureCompensation;
	if (actualExposureCompensation) {
		NSString *actualExposureCompensationTitle = [camera cameraPropertyValueLocalizedTitle:actualExposureCompensation];
		self.showExprevCell.detailTextLabel.text = actualExposureCompensationTitle;
	} else {
		self.showExprevCell.detailTextLabel.text = NSLocalizedString(@"Unknown", nil);
	}
	[self tableViewCell:self.showExprevCell enabled:[camera canSetCameraProperty:CameraPropertyExprev]];
#endif
}

/// ISO感度を表示します。
- (void)updateShowIsoCell {
	DEBUG_LOG(@"");
	
#if 0 // カメラに設定したカメラプロパティ値を表示するならこのブロックを有効にしてください。
	[self updateCameraPropertyCell:self.showIsoCell name:CameraPropertyIso completion:nil];
#else // カメラが使用している現在値を表示するならこのブロックを有効にしてください。
	AppCamera *camera = GetAppCamera();
	NSString *actualIsoSensitivity = camera.actualIsoSensitivity;
	if (actualIsoSensitivity) {
		NSString *actualIsoSensitivityTitle = [camera cameraPropertyValueLocalizedTitle:actualIsoSensitivity];
		self.showIsoCell.detailTextLabel.text = actualIsoSensitivityTitle;
	} else {
		self.showIsoCell.detailTextLabel.text = NSLocalizedString(@"Unknown", nil);
	}
	[self tableViewCell:self.showIsoCell enabled:[camera canSetCameraProperty:CameraPropertyIso]];
#endif
}

/// 撮影モードを表示します。
- (void)updateShowTakemodeCell {
	DEBUG_LOG(@"");
	
	[self updateCameraPropertyCell:self.showTakemodeCell name:CameraPropertyTakemode completion:nil];
}

/// 動画撮影モードを表示します。
- (void)updateShowExposeMovieSelectCell {
	DEBUG_LOG(@"");
	
	[self updateCameraPropertyCell:self.showExposeMovieSelectCell name:CameraPropertyExposeMovieSelect completion:nil];
}

/// ドライブモードを表示します。
- (void)updateShowTakeDriveCell {
	DEBUG_LOG(@"");
	
	[self updateCameraPropertyCell:self.showTakeDriveCell name:CameraPropertyTakeDrive completion:nil];
}

/// 連写速度を表示します。
- (void)updateShowContinuousShootingVelocityCell {
	DEBUG_LOG(@"");
	
	[self updateCameraPropertyCell:self.showContinuousShootingVelocityCell name:CameraPropertyContinuousShootingVelocity completion:nil];
}

/// カメラプロパティ値を表示します。
- (void)updateCameraPropertyCell:(UITableViewCell *)cell name:(NSString *)name completion:(void (^)(NSString *value))completion {
	DEBUG_LOG(@"name=%@", name);
	
	__weak UITableViewCell *weakCell = cell;
	__weak EPanelViewController *weakSelf = self;
	BOOL userInteractionEnabled = weakCell.userInteractionEnabled;
	weakCell.userInteractionEnabled = NO; // 表示内容が確定するまでは操作禁止にします。
	[weakSelf executeAsynchronousBlock:^{
		DEBUG_LOG(@"weakSelf=%p", weakSelf);
		
		// カメラプロパティを取得します。
		AppCamera *camera = GetAppCamera();
		NSError *error = nil;
		NSString *propertyValue = [camera cameraPropertyValue:name error:&error];
		if (!propertyValue) {
			// カメラプロパティが取得できませんでした。
			// エラーを無視します。
			DEBUG_LOG(@"An error occurred, but ignores it.");
			[weakSelf executeAsynchronousBlockOnMainThread:^{
				weakCell.userInteractionEnabled = userInteractionEnabled;
				weakCell.detailTextLabel.text = NSLocalizedString(@"Unknown", nil);
				[weakSelf tableViewCell:weakCell enabled:[camera canSetCameraProperty:name]];
				if (completion) {
					completion(propertyValue);
				}
			}];
			return;
		}
		DEBUG_LOG(@"propertyValue=%@", propertyValue);
		// 取得した値を表示用の文言に変換します。
		NSString *propertyValueTitle = [camera cameraPropertyValueLocalizedTitle:propertyValue];
		// 表示を更新します。
		[weakSelf executeAsynchronousBlockOnMainThread:^{
			weakCell.userInteractionEnabled = userInteractionEnabled;
			weakCell.detailTextLabel.text = propertyValueTitle;
			if (weakCell.accessoryType != UITableViewCellAccessoryNone) {
				[weakSelf tableViewCell:weakCell enabled:[camera canSetCameraProperty:name]];
			}
			if (completion) {
				completion(propertyValue);
			}
		}];
	}];
}

@end
