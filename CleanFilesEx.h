//
//  CleanFilesEx.h
//  browser
//
//  Created by 董浩 on 15/9/6.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    CleanFilesExPaaTypeNormal,
    CleanFilesExPaaTypeClean
}CleanFilesExPaaType;

@interface CleanFilesEx : NSObject

+ (instancetype)shareInstance;

- (NSArray*)getPaas:(CleanFilesExPaaType)paaType;

@end
