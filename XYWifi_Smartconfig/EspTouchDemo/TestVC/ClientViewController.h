//
//  ClientViewController.h
//  SocketDemo
//
//  Created by mac on 14-11-20.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#define HOST_IP        @"10.3.134.156"
#define SERVER_PORT    8080

#define LISTEN_PORT    30000

#import <UIKit/UIKit.h>

@interface ClientViewController : UIViewController

@property (nonatomic,copy) NSString *ipString;

@end
