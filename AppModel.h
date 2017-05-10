//
//  AppModel.h
//  browser
//
//  Created by 董浩 on 15/9/6.
//
//

#import <Foundation/Foundation.h>

@interface AppModel : NSObject
@property(nonatomic, copy) NSString *ln;//localizedName
@property(nonatomic, copy) NSString *rd;//resourcesDirectory
@property(nonatomic, copy) NSString *type;//appType
@property(nonatomic, copy) NSString *identifier;//appIdentifier
@property(nonatomic, copy) NSString *bv;//bundleVersion
@property(nonatomic, copy) NSString *sv;//shortVersionString
@property(nonatomic, copy) NSString *bc;//boundContainer
@property(nonatomic, copy) NSString *bdc;//boundDataContainer
@property(nonatomic, copy) NSString *si;//signerIdentity
@property(nonatomic, copy) NSString *doc;//document
@property (nonatomic, strong) NSData *icon;//icon
@end
