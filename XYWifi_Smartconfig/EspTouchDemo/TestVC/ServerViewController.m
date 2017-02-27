//
//  ServerViewController.m
//  SocketDemo
//
//  Created by mac on 14-11-20.
//  Copyright (c) 2014年 mac. All rights reserved.
//

//IP+端口

#define PORT        8000

#import "ServerViewController.h"
#import "AsyncSocket.h"

@interface ServerViewController ()<AsyncSocketDelegate, UITableViewDataSource, UITableViewDelegate>
{
    AsyncSocket *_serverSocket;
    
    NSMutableArray *_socketsArray;
    
    UITableView *_tableView;
    
    AsyncSocket *_clientSocket;
}
@end

@implementation ServerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _socketsArray = [[NSMutableArray alloc] init];
//        _socketsArray = [NSMutableArray array];
        
        _serverSocket = [[AsyncSocket alloc] initWithDelegate:self];
        
        //作为服务器的socket需要监听端口PORT
        [_serverSocket acceptOnPort:PORT error:nil];
        
        NSLog(@"服务器准备接受请求 %p",_serverSocket);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
//    [self.view addSubview:_tableView];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [_clientSocket writeData:[@"sanmao" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:100];
    
}

#pragma mark - UITableViewDelegate&Datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _socketsArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    
    if (_socketsArray.count > indexPath.row) {
        AsyncSocket *socket = [_socketsArray objectAtIndex:indexPath.row];
        cell.textLabel.text = [socket connectedHost];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

#pragma mark - AsyncSocketDelegate
//有其它客户端的socket连接
- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
    NSLog(@"接收到连接IP:%@", [newSocket connectedHost]);
//    [newSocket retain];
    [_socketsArray addObject:newSocket];
    
    [_tableView reloadData];
    
    //继续监听newSocket，不写的话后面就收不到newSocket的数据
    [newSocket readDataWithTimeout:-1 tag:100];
}
//断开连接了
- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    NSLog(@"连接断开");
    [_socketsArray removeObject:sock];
    
    [_tableView reloadData];
}

//连接socket出错时调用
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    NSLog(@"err description = %@",[err description]);
    
    [sock readDataWithTimeout:-1 tag:100];
}

//服务器接收客户端的数据
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"socksock  %@  %zi  %@  %zi",[sock connectedHost],[sock connectedPort],[sock localHost],[sock localPort]);
//    // /haha //heihei
//    NSString *strData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSString *commandStr = [NSString stringWithFormat:@"%d", COMMAND_GET_SERVER_CLIENT_LIST];
//    if ([strData isEqualToString:commandStr]) {
//        NSMutableString *str = [NSMutableString string];
//        int count = _socketsArray.count;
//        int i;
//        for (i = 0; i < count; i++) {
//            AsyncSocket *socket = [_socketsArray objectAtIndex:i];
//            [str appendString:[socket connectedHost]];
//            if (i < (count - 1)) {
//                [str appendString:@","];
//            }
//        }
//        
//        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
//        //Timeout 超时的时间,-1表示不超时
//        [sock writeData:[@"草泥马" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:100];
//    }
//    NSLog(@"接收到数据%@", strData);
    
    _clientSocket = sock;
    
    NSLog(@"接收到数据 %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    [sock readDataWithTimeout:-1 tag:100];
}

//服务器向客户端发送数据成功
- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"服务器数据发送成功");
    
    [sock readDataWithTimeout:-1 tag:100];
}

/**
 * 连接到另一台设备
 * @param host 主机的ip地址
 * @param port 主机的端口
 */
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"服务器连接到  %@:%u", host, port);
    
    [sock readDataWithTimeout:-1 tag:100];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
