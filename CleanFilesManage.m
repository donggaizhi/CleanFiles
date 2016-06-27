//
//  CleanFilesManage.m
//  browser
//
//  Created by 董浩 on 15/9/6.
//
//

#import "CleanFilesManage.h"
#import "FileUtil.h"
#import "PaaUtil.h"
#import "PaaModel.h"
#import "CleanFilesEx.h"

#define freshUnit SizeUnit*100
#define WHITELIST_STATE_FILE @"whitelist_iphone.plist"
#define DESK_VAR_LOGS_CRASHREPORTER @"deskVarLogsCrashReporter"

#define MAINDICT @"mainDict"
#define SUBDICT @"subDict"
#define SUBFILESSIZE @"subFilesSize"

static id _instance;

@interface CleanFilesManage()
//@property (nonatomic, strong) NSFileManager *mgr;
@property (nonatomic, assign) long long totalSize;
@property (nonatomic, assign) long long middleSize;
@property (nonatomic, assign) long long subFilesSize;
@property (nonatomic, strong) NSMutableArray *childPathArray;
@property (nonatomic, strong) NSMutableArray *subPathArray;
@property (nonatomic, strong) NSMutableArray *allDictArray;

@end

@implementation CleanFilesManage

- (NSMutableArray *)childPathArray{
    if (!_childPathArray) {
        _childPathArray = [NSMutableArray array];
    }
    return _childPathArray;
}

- (NSMutableArray *)subPathArray {
    if (!_subPathArray) {
        _subPathArray = [NSMutableArray array];
    }
    return _subPathArray;
}

- (NSMutableArray *)allDictArray {
    if (!_allDictArray) {
        _allDictArray = [NSMutableArray array];
    }
    return _allDictArray;
}

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

- (id)copyWithZone:(NSZone *)zone{
    return _instance;
}

#pragma mark - 遍历所有应用的文件
- (void)scanAllAppDict :(NSArray *)allAppInfoArray {
    if (self.cleanState != CleanStateScanning && self.cleanState != CleanStateFromWhiteListScanning) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.cleanState == CleanStateScanning) {
            [self.allDictArray removeAllObjects];
        }
        
        [allAppInfoArray enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (self.cleanState == CleanStateNone || self.delegate == nil) *stop = YES;
            PaaModel *model = obj;
            NSMutableArray *allScanArray = [NSMutableArray array];
            NSString *appID = model.identifier;
            if ([appID isEqualToString:@"systemFiles"]) {
                [allScanArray addObjectsFromArray:[CleanFilesManage systemFilesDict]];
            } else {
                NSString *cachesPath = [[model.doc stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Library/Caches"];
                if (cachesPath && [CleanFilesManage isDict:cachesPath]) {
                    [allScanArray addObject:cachesPath];
                }
                NSString *tmpPath = [[model.doc stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"tmp"];
                if (tmpPath && [CleanFilesManage isDict:tmpPath]) {
                    [allScanArray addObject:tmpPath];
                }
                NSString *cookiesPath = [[model.doc stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Library/Cookies"];
                if ([CleanFilesManage isDict:cookiesPath]) {
                    [allScanArray addObject:cookiesPath];
                }
            }
            
            NSMutableDictionary *appInfo = [NSMutableDictionary dictionary];
            appInfo[DESK_APPNAME] = model.ln;
            appInfo[DESK_APPID] = model.identifier;
            appInfo[DESK_APPICON] = model.icon;
            
            self.totalSize = 0;
            self.childPathArray = nil;
            
            [allScanArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (self.cleanState == CleanStateNone || self.delegate == nil) *stop = YES;
                self.subPathArray = nil;
                self.subFilesSize = 0;
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                dict[MAINDICT] = obj;
                [self ergodic:obj appInfo:appInfo callback:^(NSString *childPath) {
                    [self ergodic:appInfo path:childPath];
                }];
                dict[SUBDICT] = [self.subPathArray copy];
                dict[SUBFILESSIZE] = @(self.subFilesSize);
                [self.childPathArray addObject:dict];
            }];
            appInfo[DESK_FILESIZE] = @(self.totalSize);
            
            if ([self.delegate respondsToSelector:@selector(cleanFilesManageScanOneAppFinish:appInfo:)]) {
                if (self.cleanState == CleanStateNone || self.delegate == nil) *stop = YES;
                [self.delegate cleanFilesManageScanOneAppFinish:self appInfo:appInfo];
            }
            appInfo[DESK_FILEDICT] = [self.childPathArray copy];
            if (self.childPathArray.count != 0) {
                [self.allDictArray insertObject:appInfo atIndex:0];
            }
        }];
        
        if (self.cleanState == CleanStateNone || self.delegate == nil) {
            [self cleanAll];
            return;
        }
        if ([self.delegate respondsToSelector:@selector(cleanFilesManageScanAllAppFinish:appInfo:)]) {
            if (self.cleanState == CleanStateNone || self.delegate == nil) return;
            [self.delegate cleanFilesManageScanAllAppFinish:self appInfo:nil];
        }
        self.cleanState = CleanStateScanFinish;
    });
    
    return;
}

- (void)ergodic:(NSString *)dictStr appInfo:(NSMutableDictionary *)appInfo callback:(void (^)(NSString *childPath)) block {
    if (self.cleanState == CleanStateNone || self.delegate == nil) {
        [self cleanAll];
        return;
    }
    
    if ([CleanFilesManage isDict:dictStr]) {
        NSArray *tmpArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dictStr error:nil];
        for (NSString *dictPath in tmpArray) {
            if (self.cleanState == CleanStateNone || self.delegate == nil) {
                [self cleanAll];
                return;
            }
            [self ergodic:[dictStr stringByAppendingPathComponent:dictPath] appInfo:appInfo callback:^(NSString *childPath) {
                [self ergodic:appInfo path:childPath];
            }];
        }
    }else{
        block(dictStr);
    }
}

- (void)ergodic:(NSMutableDictionary *)appInfo path:(NSString *)childPath {
    @synchronized(self) {
        [self.subPathArray addObject:childPath];
        if ([CleanFilesManage sizeOfFile:childPath] == 0) return;
        self.totalSize += [CleanFilesManage sizeOfFile:childPath];
        self.subFilesSize += [CleanFilesManage sizeOfFile:childPath];
        appInfo[DESK_FILESIZE] = [NSString stringWithFormat:@"%lld",self.totalSize];
        if ([self.delegate respondsToSelector:@selector(cleanFilesManageScanning:appInfo:)]) {
            if (self.cleanState == CleanStateNone || self.delegate == nil) {
                [self cleanAll];
                return;
            }
            [self.delegate cleanFilesManageScanning:self appInfo:appInfo];
        }
    }
}

#pragma mark - 清理文件
- (void)cleanFiles {
    if ( self.cleanState != CleanStateCleaning ) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [self.allDictArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            if (self.cleanState == CleanStateNone || self.delegate == nil) *stop = YES;
            
            self.totalSize = 0;
            self.middleSize = 0;
            
            NSMutableDictionary *appInfo = [NSMutableDictionary dictionary];
            
            appInfo[DESK_APPNAME] = obj[DESK_APPNAME];
            appInfo[DESK_APPID] = obj[DESK_APPID];
            appInfo[DESK_APPICON] = obj[DESK_APPICON];
            
            self.totalSize = [obj[DESK_FILESIZE] longLongValue];
            self.middleSize = [obj[DESK_FILESIZE] longLongValue];
            
            [obj[DESK_FILEDICT] enumerateObjectsUsingBlock:^(NSMutableDictionary *dict, NSUInteger idx, BOOL * _Nonnull stop) {
                
                if (self.cleanState == CleanStateNone || self.delegate == nil) *stop = YES;

                //   /var/logs/CrashReporter/   如果文件过多，会出现删除特别慢，所以直接删除整个目录
                if ([dict[MAINDICT] isEqualToString:@"/var/logs/CrashReporter"]) {
                    if (self.cleanState == CleanStateNone || self.delegate == nil) *stop = YES;

                    [[FileUtil instance] execCmd:@"rm -rf /var/logs/CrashReporter"];
                    self.totalSize = self.totalSize - [dict[SUBFILESSIZE] longLongValue];
                    appInfo[DESK_FILESIZE] = @(self.totalSize);
                    if ([self.delegate respondsToSelector:@selector(cleanFilesManageCleaning:appInfo:)]) {
                        if (self.cleanState == CleanStateNone || self.delegate == nil) *stop = YES;
                        [self.delegate cleanFilesManageCleaning:self appInfo:appInfo];
                    }
                } else {
                    [dict[SUBDICT] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (self.cleanState == CleanStateNone || self.delegate == nil) *stop = YES;
                        
                        if ([CleanFilesManage hasFile:obj]) {
                            long long fileSize = [CleanFilesManage sizeOfFile:obj];
                            self.totalSize = self.totalSize - fileSize;
                            
                            [[NSFileManager defaultManager] removeItemAtPath:obj error:nil];
                            if ([CleanFilesManage hasFile:obj]) {
                                NSString *rmCmd = [NSString stringWithFormat:@"rm -rf %@",obj];
                                [[FileUtil instance] execCmd:rmCmd];
                            }
                            
                            appInfo[DESK_FILESIZE] = @(self.totalSize);
                            
                            if ([self.delegate respondsToSelector:@selector(cleanFilesManageCleaning:appInfo:)]) {
                                if (self.cleanState == CleanStateNone || self.delegate == nil) *stop = YES;
                                [self.delegate cleanFilesManageCleaning:self appInfo:appInfo];
                            }
                        }
                    }];
                }
            }];
            
            if (self.cleanState == CleanStateNone || self.delegate == nil) *stop = YES;
            
            appInfo[DESK_FILESIZE] = @(self.totalSize);
            
            if ([self.delegate respondsToSelector:@selector(cleanFilesManageCleanOneAppFinish:appInfo:)]) {
                if (self.cleanState == CleanStateNone || self.delegate == nil) *stop = YES;
                [self.delegate cleanFilesManageCleanOneAppFinish:self appInfo:appInfo];
            }
        }];
        
        [self cleanAll];
        if (self.cleanState == CleanStateNone || self.delegate == nil) return;
        if ([self.delegate respondsToSelector:@selector(cleanFilesManageCleanAllAppFinish:appInfo:)]) {
            if (self.cleanState == CleanStateNone || self.delegate == nil) return;
            [self.delegate cleanFilesManageCleanAllAppFinish:self appInfo:nil];
        }
        self.cleanState = CleanStateCleanFinish;
    });
}

- (void)cleanAll {
    self.allDictArray = nil;
    self.childPathArray = nil;
    self.subPathArray = nil;
    self.totalSize = 0;
}

- (void)stop {
    self.cleanState = CleanStateNone;
    self.delegate = nil;
}

#pragma mark - 其他
#pragma mark 空间使用情况
+ (NSString *) getDiskspace {
    CGFloat totalSpace = [[FileUtil instance] getTotalDiskspace];
    CGFloat totalFreeSpace = [[FileUtil instance] getFreeDiskspace];
    CGFloat totalUsedSpace = totalSpace - totalFreeSpace;
    if (totalSpace == 0.0 || totalUsedSpace == 0.0) return nil;
    NSString *totalSpaceStr,*totalUsedSpaceStr;
    //总容量
    if (1.0*totalSpace/SizeUnit/SizeUnit/SizeUnit > 1) {
        totalSpaceStr = [NSString stringWithFormat:@"%.2fGB",1.0*totalSpace/SizeUnit/SizeUnit/SizeUnit];
    } else {
        totalSpaceStr = [NSString stringWithFormat:@"%.2fMB",1.0*totalUsedSpace/SizeUnit/SizeUnit];
    }
    //使用容量
    if (1.0 * totalUsedSpace/SizeUnit/SizeUnit/SizeUnit > 1) {
        totalUsedSpaceStr = [NSString stringWithFormat:@"%.2fGB",1.0*totalUsedSpace/SizeUnit/SizeUnit/SizeUnit];
    } else {
        totalUsedSpaceStr = [NSString stringWithFormat:@"%.2fMB",1.0*totalUsedSpace/SizeUnit/SizeUnit];
    }
    return [NSString stringWithFormat:@"已使用 : %@/%@",totalUsedSpaceStr,totalSpaceStr];
}

#pragma mark 是否存在该文件
+ (BOOL)hasFile:(NSString *)fileName {
    return [[NSFileManager defaultManager] fileExistsAtPath:fileName];
}

#pragma mark 判断是否是目录
+ (BOOL)isDict:(NSString *)path {
    BOOL isDict;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDict]) return NO;
    return isDict;
}

#pragma mark 获取文件大小（字节）
+ (long long)sizeOfFile:(NSString *)path {
    if (![CleanFilesManage hasFile:path]) return 0;
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
}

#pragma mark 将long long 转成字符串
+ (NSString *)convertSize:(long long)totleSize {
    if (1.0 * totleSize/SizeUnit/SizeUnit/SizeUnit > 1.0) {
        return [NSString stringWithFormat:@"%.2fGB",1.0*totleSize/SizeUnit/SizeUnit/SizeUnit];
    } else if (1.0 * totleSize/SizeUnit/SizeUnit > 1.0){
        return [NSString stringWithFormat:@"%.1fMB",1.0*totleSize/SizeUnit/SizeUnit];
    } else if (1.0 * totleSize/SizeUnit > 1.0){
        return [NSString stringWithFormat:@"%.1fKB",1.0*totleSize/SizeUnit];
    }else if (1.0 * totleSize > 1.0){
        return [NSString stringWithFormat:@"%.1fB",1.0*totleSize];
    } else {
        return @"0.0B";
    }
}

#pragma mark 获取白名单的switch状态文件
+ (NSString *)getStateFile {
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [documentPath stringByAppendingPathComponent:WHITELIST_STATE_FILE];
}

#pragma mark 读取所有的开关的状态
+ (NSDictionary *)readStateFile :(NSString *)fileName {
    return [NSDictionary dictionaryWithContentsOfFile:fileName];
}

#pragma mark  清理文件
- (void)deleteCleanDict:(NSString *)bundle {
    if (self.allDictArray.count != 0) {
        [self.allDictArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj[DESK_APPID] isEqualToString:bundle]) {
                [self.allDictArray removeObjectAtIndex:idx];
                *stop = YES;
            }
        }];
    }
}

#pragma mark 获取所有的app信息
+ (NSArray *)getAllAppInfo {
    NSMutableArray *array = [[[CleanFilesEx shareInstance] getPaas:CleanFilesExPaaTypeClean] mutableCopy];
    PaaModel *sysModel = [CleanFilesManage addSystemFilesInfo];
    [array addObject:sysModel];
    return array;
}

//#pragma mark 获取所有的User app信息
//+ (NSArray *)getUserAppInfo {
//    NSMutableArray *array = [[[PaaUtil instance] getPaas] mutableCopy];
//    NSMutableArray *userArray = [NSMutableArray array];
//    for (NSDictionary *dict in array) {
//        if ([dict[DESK_APPID] isEqualToString:@"com.apple.mobilesafari"] ||
//            [dict[DESK_APPID] isEqualToString:@"com.apple.weather"] ||
//            [dict[DESK_APPID] isEqualToString:@"com.apple.mobilemail"] )
//            continue;
//        [userArray addObject:dict];
//    }
//    return userArray;
//}

#pragma mark 创建白名单文件
+ (void)createWhiteListStateFile {
    [CleanFilesManage createStateFile:[CleanFilesManage getStateFile]];
}

#pragma mark 创建开关文件
+ (void)createStateFile:(NSString *)fileName {
    if (![CleanFilesManage hasFile:fileName]) {
        NSMutableDictionary *stateDict = [NSMutableDictionary dictionary];
        
        [[CleanFilesManage getAllAppInfo] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            PaaModel *model = obj;
            stateDict[model.identifier] = @"NO";
        }];
        [stateDict writeToFile:fileName atomically:YES];
    } else {
        NSMutableDictionary *tmpDict = [[CleanFilesManage readStateFile:fileName] mutableCopy];
        NSMutableDictionary *newDict = [NSMutableDictionary dictionary];
        [[CleanFilesManage getAllAppInfo] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            PaaModel *model = obj;
            NSString *tmpBundID = model.identifier;
            __block BOOL hasBundle = NO;
            [tmpDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if ([tmpBundID isEqualToString:key]) {
                    hasBundle = YES;
                    newDict[key] = obj;
                    [tmpDict removeObjectForKey:key];
                    *stop = YES;
                }
            }];
            if (!hasBundle) {
                newDict[tmpBundID] = @"NO";
            }
        }];
        
        [newDict writeToFile:fileName atomically:YES];
    }
}

#pragma mark 修改在白名单文件中的开关状态
+ (void)changStateInFile:(NSString *)key value:(NSString *)value {
    NSString *fileName = [CleanFilesManage getStateFile];
    [CleanFilesManage changStateInFile:fileName key:key value:value];
}

+ (void)changStateInFile:(NSString *)fileName key:(NSString *)key value:(NSString *)value {
    NSMutableDictionary *dict = [[CleanFilesManage readStateFile:fileName] mutableCopy];
    dict[key] = value;
    [dict writeToFile:fileName atomically:YES];
}

+ (PaaModel *)addSystemFilesInfo {
    PaaModel *sysModel = [[PaaModel alloc] init];
    sysModel.identifier = @"systemFiles";
    sysModel.ln = @"系统垃圾";
    sysModel.icon = UIImagePNGRepresentation([UIImage imageNamed:@"cleanFiles_systemFiles"]);
    return sysModel;
}

+ (NSArray *)changeSystemToShowFirst:(NSMutableArray *)array {
    __block PaaModel *model = [[PaaModel alloc] init];
    [array enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PaaModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.identifier isEqualToString:@"systemFiles"]) {
            model = obj;
            [array removeObjectAtIndex:idx];
            *stop = YES;
        }
    }];
    
    [array insertObject:model atIndex:0];
    return array;
}


/**
 *  /var/vm 虚拟内存
 *  /var/mobile/Library/Caches 可能会出现问题
 *  /var/mobile/Library/Cookies/Cookies.binarycookies   Safari cookies
 *  /var/log/syslog 此文件为安装syslogd插件生成
 *  /User/Media/ApplicationArchives/ 出错的软件压缩包
 *  /User/Media/PublicStaging/ 安装失败的应用程序冗余文件
 */

+ (NSArray *)systemFilesDict {
    return [NSArray arrayWithObjects:
//                                    @"/tmp"
                                    nil];
}

////////////////////////////////////////////////////////////////
#pragma mark 清理本应用缓存
+ (NSString *)getCacheSize
{
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *local_cacheDir = [cachePaths[0] stringByAppendingPathComponent:@"com.jailbreak.kk"];
    NSString *sdimage_cacheDir = [cachePaths[0] stringByAppendingPathComponent:@"default/com.hackemist.SDWebImageCache.default"];
    NSString *tmdisk_cacheDir = [cachePaths[0] stringByAppendingPathComponent:@"com.tumblr.TMDiskCache.TMCacheShared"];
    
    CGFloat totalCacheCount =
    [self folderSizeAtPath:local_cacheDir] +
    [self folderSizeAtPath:sdimage_cacheDir] +
    [self folderSizeAtPath:tmdisk_cacheDir];
    NSString *cacheSize = [NSString stringWithFormat:@"%.2lfMB",totalCacheCount];
    return cacheSize;
}

+ (CGFloat)folderSizeAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    float folderSize = 0.0;
    if ([fileManager fileExistsAtPath:path]) {
        NSArray *childerFiles=[fileManager subpathsAtPath:path];
        for (NSString *fileName in childerFiles) {
            NSString *absolutePath = [path stringByAppendingPathComponent:fileName];
            folderSize += [self fileSizeAtPath:absolutePath];
        }
        return folderSize;
    }
    return 0;
}

+ (CGFloat)fileSizeAtPath:(NSString *)path {
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:path]){
        long long size = [fileManager attributesOfItemAtPath:path error:nil].fileSize;
        // 返回值是字节 B K M
        return size/1024.0/1024.0;
    }
    return 0;
}


+ (void)clearCurrentCacheCompleteBlock:(void(^)())completeBlock{
    //清除本地缓存目录
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
       , ^{
           NSString *cachPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
           NSString *local_cachPath = [cachPath stringByAppendingString:@"/com.jailbreak.kk"];
           NSString *sdimage_cachPath = [cachPath stringByAppendingString:@"/default/com.hackemist.SDWebImageCache.default"];
           NSString *tmdisk_cachPath = [cachPath stringByAppendingString:@"/com.tumblr.TMDiskCache.TMCacheShared"];
           [self removeFile:local_cachPath];
           [self removeFile:sdimage_cachPath];
           [self removeFile:tmdisk_cachPath];
           if (completeBlock) {
               dispatch_async(dispatch_get_main_queue(), ^{
                   completeBlock();
               });
//               [self performSelectorOnMainThread:@selector(completeBlock) withObject:nil waitUntilDone:YES];
           }
       }
    );
}

+ (void)removeFile:(NSString*)local_cachPath {
    NSArray *files = [[NSFileManager defaultManager] subpathsAtPath:local_cachPath];
    for (NSString *p in files) {
        NSError *error;
        NSString *path = [local_cachPath stringByAppendingPathComponent:p];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        }
    }
}

@end
