//
//  CleanFilesEx.m
//  browser
//
//  Created by 董浩 on 15/9/6.
//
//

#import "CleanFilesEx.h"
#import "AppModel.h"
#include <string>
#include <dlfcn.h>

using namespace std;

#define SBSERVPATH "/System/Library/PrivateFrameworks/SpringBoardServices.framework/SpringBoardServices"

//根据 appID 获取对应图标
typedef NSData * (*SBSCopyIconImagePNGDataForDisplayIdentifier)(NSString *);
SBSCopyIconImagePNGDataForDisplayIdentifier _SBSCopyIconImagePNGDataForDisplayIdentifier;

static id _instance;

@interface CleanFilesEx() {
    void * _springBooardModule;
}

@end

@implementation CleanFilesEx

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

- (instancetype)init {
    if (self = [super init]) {
        _springBooardModule = dlopen(SBSERVPATH, RTLD_LAZY);
        if (_springBooardModule) {
            _SBSCopyIconImagePNGDataForDisplayIdentifier = (SBSCopyIconImagePNGDataForDisplayIdentifier)dlsym(_springBooardModule, "SBSCopyIconImagePNGDataForDisplayIdentifier");
        }
    }
    return self;
}

//获取本地应用列表
- (NSArray*) getPaas:(CleanFilesExPaaType)type {
    Class aw = NSClassFromString(@"LSApplicationWorkspace");
    NSObject *dw = objc_msgSend(aw, NSSelectorFromString(@"defaultWorkspace"));
    NSArray* aps = objc_msgSend(dw, NSSelectorFromString(@"allInstalledApplications"));
    NSMutableArray* apps = [[NSMutableArray alloc] init];
    for (NSObject* ap in aps) {
        NSString* at = objc_msgSend(ap, NSSelectorFromString(@"applicationType"));
        NSString* ai = objc_msgSend(ap, NSSelectorFromString(@"applicationIdentifier"));
        
        if (type == CleanFilesExPaaTypeClean) {
            if ([at isEqualToString:@"System"] && (![ai isEqualToString:@"com.apple.weather"] && ![ai isEqualToString:@"com.apple.mobilemail"] && ![ai isEqualToString:@"com.apple.mobilesafari"])) continue;
        } else if (type == CleanFilesExPaaTypeNormal) {
            if ([at isEqualToString:@"System"]) continue;
        }
        
        NSString* ln = objc_msgSend(ap, NSSelectorFromString(@"localizedName"));
        NSURL* rdu = objc_msgSend(ap, NSSelectorFromString(@"resourcesDirectoryURL"));
        NSString* rd = rdu.path;
        
        NSString* bv = objc_msgSend(ap, NSSelectorFromString(@"bundleVersion"));
        NSString* sv = objc_msgSend(ap, NSSelectorFromString(@"shortVersionString"));
        NSURL* bcu = nil;
        if ([ap respondsToSelector:NSSelectorFromString(@"boundContainerURL")]) {
            bcu = objc_msgSend(ap, NSSelectorFromString(@"boundContainerURL"));
        } else {
            bcu = rdu.URLByDeletingLastPathComponent;
        }
        NSString* bc = bcu.path;
        NSURL* bdcu = nil;
        if ([ap respondsToSelector:NSSelectorFromString(@"boundDataContainerURL")]) {
            bdcu = objc_msgSend(ap, NSSelectorFromString(@"boundDataContainerURL"));
        } else {
            bdcu = rdu.URLByDeletingLastPathComponent;
        }
        NSString* bdc = bdcu.path;
        
        NSString* signerIdentity = objc_msgSend(ap, NSSelectorFromString(@"signerIdentity"));
        
        int device = [[UIDevice currentDevice].systemVersion intValue];
        NSString *doc = (device >= 8)? [bdc stringByAppendingPathComponent:@"Documents"] : [bc stringByAppendingPathComponent:@"Documents"];
        
        NSData *icon = [self bundleIconForAppID:ai];
        
        AppModel *app = [[AppModel alloc] init];
        app.ln = ln;
        app.rd = rd;
        app.type = at;
        app.identifier = ai;
        app.bv = bv;
        app.sv = sv;
        app.bc = bc;
        app.bdc = bdc;
        app.si = signerIdentity;
        app.doc = doc;
        app.icon = icon;
        [apps addObject:app];
    }
    return apps;
}

/** 获取icon*/
- (NSData *)bundleIconForAppID:(NSString*)identifier {
    NSData * data = _SBSCopyIconImagePNGDataForDisplayIdentifier(identifier);
    return data;
}

@end
