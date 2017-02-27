//
//  UDPRadioViewController.m
//  EspTouchDemo
//
//  Created by Adsmart on 17/2/21.
//  Copyright © 2017年 白 桦. All rights reserved.
//

#import "UDPRadioViewController.h"
#import "AsyncUdpSocket.h"
#import "ESP_NetUtil.h"
#import "ESPUDPBroadcastUtil.h"
#import "ESPBssidUtil.h"

@interface UDPRadioViewController ()<AsyncUdpSocketDelegate>
{
    
    AsyncUdpSocket *_clientSocket;
    
}
@end

@implementation UDPRadioViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        //创建socket(UDP)
        _clientSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];
        
        //允许广播形式
        [_clientSocket enableBroadcast:YES error:nil];
        
//        NSError *error = nil;
//        NSString *localhost = [ESP_NetUtil getLocalIPv4];
//        //绑定本地IP与端口
//        [_clientSocket bindToAddress:localhost port:5656 error:&error];
//         // CFSocketSetAddress listen failure: 102  重复绑定或者监听
//        NSLog(@"localhost = %@ , error = %@",localhost,error);
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self longConnectToSocket];
    
}

- (void)longConnectToSocket {
    
    NSString *requestString = [ESPUDPBroadcastUtil getRequestDataStr:nil];
    NSLog(@"requestString = %@",requestString);
    NSData *data = [requestString dataUsingEncoding:NSUTF8StringEncoding];
    
    [_clientSocket sendData:data
                   toHost:@"255.255.255.255"
                     port:1025
              withTimeout:-1
                      tag:0];

}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
    [sock receiveWithTimeout:-1 tag:tag];
}

- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port {
    
    NSLog(@"didReceiveData = %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    NSArray *array = [ESPUDPBroadcastUtil parsingDevicesWithResponseString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    
    for (ESPIOTAddress *iota in array) {
        
        NSLog(@"name = %@",[ESPBssidUtil genDeviceNameByBssid:iota.espBssid]);
        
    }
    
    NSLog(@"哈哈哈 %@",array);
    
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
