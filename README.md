# CleanFiles
清理垃圾文件

该文件仅包括扫描清理逻辑，具体显示及model未添加

1、扫描所有应用的目录
// 传入一个app信息的array（包括BundleId和Document Path）
- (void)scanAllAppDict :(NSArray *)allAppInfoArray;

2、//清理文件
- (void)cleanFiles;

注：扫描或清理需先设置操作的状态
[CleanFilesManage shareInstance].cleanState = CleanStateNone;

typedef enum  {
    CleanStateNone,                   //初始状态
    CleanStateScanning,               //正在扫描
    CleanStateFromWhiteListScanning,
    CleanStateScanFinish,             //扫描完毕
    CleanStateCleaning,               //正在清理
    CleanStateCleanFinish             //清理完毕
}CleanState;
