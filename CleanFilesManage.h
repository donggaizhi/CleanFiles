//
//  CleanFilesManage.h
//  browser
//
//  Created by 董浩 on 15/9/6.
//
//

#import <Foundation/Foundation.h>

#define DESK_FILESIZE @"desk_filesize"
#define DESK_FILEDICT @"desk_filedict"

#define SizeUnit 1024

@class CleanFilesManage;

typedef enum  {
    CleanStateNone,
    CleanStateScanning,
    CleanStateFromWhiteListScanning,
    CleanStateScanFinish,
    CleanStateCleaning,
    CleanStateCleanFinish
}CleanState;

@protocol CleanFilesManageDelegate <NSObject>
@optional
//扫描中
- (void)cleanFilesManageScanning:(CleanFilesManage *)mgr appInfo:(NSDictionary *)appInfo;
//扫描完一个应用
- (void)cleanFilesManageScanOneAppFinish:(CleanFilesManage *)mgr appInfo:(NSDictionary *)appInfo;
//扫描完所有的应用
- (void)cleanFilesManageScanAllAppFinish:(CleanFilesManage *)mgr appInfo:(NSDictionary *)appInfo;

//清理中
- (void)cleanFilesManageCleaning:(CleanFilesManage *)mgr appInfo:(NSMutableDictionary *)appInfo;
//清理一个应用
- (void)cleanFilesManageCleanOneAppFinish:(CleanFilesManage *)mgr appInfo:(NSMutableDictionary *)appInfo;
//清理所有的应用
- (void)cleanFilesManageCleanAllAppFinish:(CleanFilesManage *)mgr appInfo:(NSMutableDictionary *)appInfo;

@end

@class PaaModel;

@interface CleanFilesManage : NSObject

@property (nonatomic, assign) CleanState cleanState;
@property (nonatomic, weak) id<CleanFilesManageDelegate> delegate;

+ (instancetype)shareInstance;

//文件是否存在
+ (BOOL)hasFile:(NSString *)fileName;

//是否是目录
+ (BOOL)isDict:(NSString *)path;

//获取白名单文件
+ (NSString *)getStateFile;

//获取白名单中开关所有状态
+ (NSDictionary *)readStateFile :(NSString *)fileName;

//修改switch文件的状态
+ (void)changStateInFile:(NSString *)key value:(NSString *)value;
+ (void)changStateInFile:(NSString *)fileName key:(NSString *)key value:(NSString *)value;

//获取手机所有应用的信息
+ (NSArray *)getAllAppInfo;

//获取手机用户权限的应用信息
//+ (NSArray *)getUserAppInfo;

//初始化白名单状态（生成文件）
+ (void)createWhiteListStateFile;
+ (void)createStateFile:(NSString *)fileName;

//long long 转成字符串
+ (NSString *)convertSize:(long long)totleSize ;

//扫描目录
- (void)ergodic:(NSString *)dictStr appInfo:(NSMutableDictionary *)appInfo callback:(void (^)(NSString *childPath)) block ;

//清理文件
- (void)cleanFiles;

//结束扫描或清理
- (void)stop;

//扫描所有应用的目录
- (void)scanAllAppDict :(NSArray *)allAppInfoArray;

//通过bundleID删除扫描的目录
- (void)deleteCleanDict:(NSString *)bundle;

//增加系统垃圾的信息
+ (PaaModel *)addSystemFilesInfo;

//使系统垃圾最后一个扫描
+ (NSArray *)changeSystemToShowFirst:(NSMutableArray *)array;

//获取空间使用情况
+ (NSString *) getDiskspace;

//////////////////////////////////////////////////////
//获取本应用的缓存
+ (NSString *)getCacheSize;
+ (void)clearCurrentCacheCompleteBlock:(void(^)())completeBlock;

@end
