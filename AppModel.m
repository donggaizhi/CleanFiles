//
//  PaaModel.m
//  browser
//
//  Created by 董浩 on 15/9/6.
//
//

#import "AppModel.h"

@implementation AppModel

- (NSString *)description {
    return [NSString stringWithFormat:@" localizedName = %@,\r resourcesDirectory = %@,\r appType = %@,\r appIdentifier = %@,\r bundleVersion = %@,\r shortVersionString = %@,\r boundContainer = %@,\r boundDataContainer = %@,\r signerIdentity = %@,\r document = %@\r icon = %@\r",self.ln,self.rd,self.type,self.identifier,self.bv,self.sv,self.bc,self.bdc,self.si,self.doc,self.icon];
}

@end
