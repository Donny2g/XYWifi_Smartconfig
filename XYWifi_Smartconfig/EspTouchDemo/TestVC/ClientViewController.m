//
//  ClientViewController.m
//  SocketDemo
//
//  Created by mac on 14-11-20.
//  Copyright (c) 2014年 mac. All rights reserved.
//

enum
{
    kViewTag_Offset = 200,
    kViewTag_ButtonConnect,
    kViewTag_ButtonDisconnect,
    kViewTag_ButtonGetClientList,
};

#import "ClientViewController.h"
#import "AsyncSocket.h"

//static NSTimeInterval _timeout = 20.0;

@interface ClientViewController ()<AsyncSocketDelegate, UITableViewDataSource, UITableViewDelegate>
{
    AsyncSocket *_clientSocket;
    
    //点对点通讯的服务器
    AsyncSocket *_listenSocket;
    
    //点对点通讯的客户端
    AsyncSocket *_listenClientSocket;
    
    //从服务器请求到的客户端列表（ip）
    NSMutableArray *_clientsHostArray;
    
    UITableView *_tableView;
}
@end

@implementation ClientViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _clientsHostArray = [[NSMutableArray alloc] init];
        
        _clientSocket = [[AsyncSocket alloc] initWithDelegate:self];
        
        //点对点服务器
        _listenSocket = [[AsyncSocket alloc] initWithDelegate:self];
        [_listenSocket acceptOnPort:LISTEN_PORT error:nil];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSArray *titlesArray = [NSArray arrayWithObjects:@"连接服务器", @"断开连接", @"请求客户端列表", nil];
    int count = titlesArray.count;
    float x = 0;
    float y = 40;
    float width = 100;
    float height = 40;
    for (int i = 0; i < count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.frame = CGRectMake(x, y, width, height);
        button.tag = kViewTag_Offset + i + 1;
        [button setTitle:titlesArray[i] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        x += (width + 10);
        
        [self.view addSubview:button];
    }
    
    x = 0;
    y = height + y;
    height = self.view.frame.size.height - y;
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(x, y, width, height) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
}

- (void)buttonPressed:(UIButton *)button
{
    switch (button.tag) {
        case kViewTag_ButtonConnect:
            [self connectToServer];
            break;
        case kViewTag_ButtonDisconnect:
            [self disconnectToServer];
            break;
        case kViewTag_ButtonGetClientList:
            [self requestClientHostList];
            break;
            
        default:
            break;
    }
}

#pragma mark - UITableViewDelegate&Datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _clientsHostArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    
    if (_clientsHostArray.count > indexPath.row) {
        cell.textLabel.text = _clientsHostArray[indexPath.row];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *listenIp = [_clientsHostArray objectAtIndex:indexPath.row];
    if (_listenClientSocket && [_listenClientSocket isConnected]) {
        [_listenClientSocket disconnect];
    }
    
    _listenClientSocket = [[AsyncSocket alloc] initWithDelegate:self];
    [_listenClientSocket connectToHost:listenIp onPort:LISTEN_PORT withTimeout:-1 error:nil];
}

#pragma mark - 连接服务器
- (void)connectToServer
{
    if (![_clientSocket isConnected]) {
//        [_clientSocket connectToHost:HOST_IP onPort:SERVER_PORT withTimeout:-1 error:nil];
//        BOOL flag = [_clientSocket connectToHost:self.ipString onPort:SERVER_PORT withTimeout:-1 error:nil];
        BOOL flag = [_clientSocket connectToHost:@"192.168.1.138" onPort:8080 withTimeout:-1 error:nil];
        NSLog(@"self.ipString %@   %zi",self.ipString,flag);

    }
}

#pragma mark - 断开跟服务器的连接
- (void)disconnectToServer
{
    if ([_clientSocket isConnected]) {
        [_clientSocket disconnect];
    }
}

#pragma mark - 向服务器请求客户端主机列表
- (void)requestClientHostList
{
    if ([_clientSocket isConnected]) {
        NSString *strCommand = @"have";
        NSData *data = [strCommand dataUsingEncoding:NSUTF8StringEncoding];
        [_clientSocket writeData:data withTimeout:-1 tag:100];
    }
}

#pragma mark - AsyncSocketDelegate
- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
    NSLog(@"点对点服务器接收到新的连接:%@", [newSocket connectedHost]);
    
    [newSocket readDataWithTimeout:-1 tag:100];
    
    if (_listenClientSocket && [_listenClientSocket isConnected]) {
        [_listenClientSocket disconnect];
    }
    _listenClientSocket = newSocket;
}
//建立起连接
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"连接到host:%@  port:%zi", host,port);
    [sock readDataWithTimeout:-1 tag:200];
}

//数据发送成功
- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"发送数据成功");
    
    [sock readDataWithTimeout:-1 tag:200];
}

//收到数据
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [_clientsHostArray removeAllObjects];
    
    NSString *strData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *components = [strData componentsSeparatedByString:@","];
    [_clientsHostArray addObjectsFromArray:components];
    NSLog(@"收到数据:%@", strData);
    [_tableView reloadData];
    
    [sock readDataWithTimeout:-1 tag:200];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock {
    
    NSLog(@"断开连接");
    
}

- (void)onSocket:(AsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    
    NSLog(@"partialLength = %zi",partialLength);
    [sock readDataWithTimeout:-1 tag:200];
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
