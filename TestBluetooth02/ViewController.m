//
//  ViewController.m
//  TestBluetooth02
//
//  Created by 菊地 拓也 on 2013/06/09.
//  Copyright (c) 2013年 Eagle-inc. All rights reserved.
//

#import "ViewController.h"

#define SESSION_ID @"GKSessionTest"

@interface ViewController ()

@property (nonatomic, strong) UILabel *stateLabel;
@property (nonatomic, strong) UITextField *resultField;

@property (nonatomic, strong) GKSession *session;
@property (nonatomic, strong) NSString *reception;
@property (nonatomic, assign) BOOL fServer;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self setParts];
    [self setConnect:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setParts {
    
    // 基本キャンバスを準備
    UIView *canvasView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 568)];
    canvasView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    [self.view addSubview:canvasView];

    // 状態表示用ラベルを準備する
    _stateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 16)];
    _stateLabel.backgroundColor = [UIColor clearColor];
    _stateLabel.textColor = [UIColor blackColor];
    [canvasView addSubview:self.stateLabel];
    
    // 送信データフィールドを準備する
    _resultField = [[UITextField alloc] initWithFrame:CGRectMake(100, 150, 120, 30)];
    _resultField.borderStyle = UITextBorderStyleRoundedRect;
    _resultField.font = [UIFont fontWithName:@"Helvetica" size:14];
    _resultField.placeholder = @"送信データ";
    _resultField.keyboardType = UIKeyboardTypeDefault;
    _resultField.returnKeyType = UIReturnKeyDefault;
    _resultField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _resultField.delegate = self;
    [canvasView addSubview:self.resultField];
    
    // 送信ボタンを準備する
    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    sendButton.frame = CGRectMake(120, 200, 80, 30);
    [sendButton setTitle:@"送信" forState:UIControlStateNormal];
    [sendButton addTarget:self action:@selector(sendMessage:) forControlEvents:UIControlEventTouchUpInside];
    [canvasView addSubview:sendButton];

    // 受信ボタンを準備する
    UIButton *receptionButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    receptionButton.frame = CGRectMake(120, 250, 80, 30);
    [receptionButton setTitle:@"受信" forState:UIControlStateNormal];
    [receptionButton addTarget:self action:@selector(receptionMessage:) forControlEvents:UIControlEventTouchUpInside];
    [canvasView addSubview:receptionButton];
}

// YESならServerモード　NOならClientモード
- (void)setConnect:(BOOL)sessionMode {
    
    if (sessionMode) {
        _session = [[GKSession alloc] initWithSessionID:SESSION_ID displayName:nil sessionMode:GKSessionModeServer];
    } else {
        _session = [[GKSession alloc] initWithSessionID:SESSION_ID displayName:nil sessionMode:GKSessionModeClient];
    }
    
    // Delegateを指定する
    _session.delegate = self;
    // 受信データを受け取るオブジェクトを指定します
    [_session setDataReceiveHandler:self withContext:nil];
    // 通信を待ち受ける状態にする
    _session.available = YES;
    
    _fServer = sessionMode;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    // キーボードを隠す
    [self.view endEditing:YES];
    
    return YES;
}

- (void)sendMessage:(id)sender {

    [self setConnect:YES];
}

- (void)receptionMessage:(id)sender {
    
    // 出力する
    _resultField.text = self.reception;

}

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
    
    switch (state) {
        case GKPeerStateAvailable:
        {
            // 他のPeerが利用可能になったとき
            _stateLabel.text = [NSString stringWithFormat:@"connecting to %@", [session displayNameForPeer:peerID]];
            [session connectToPeer:peerID withTimeout:10.0f]; // peerIDに対して接続を要求する
            break;
        }
        case GKPeerStateUnavailable:
        {
            // 他のPeerが利用できなくなったとき
            _stateLabel.text = [NSString stringWithFormat:@"miss"];
            break;
        }
        case GKPeerStateConnecting:
        {
            // 他のPeerに接続申請中のとき
            _stateLabel.text = [NSString stringWithFormat:@"wait"];
            break;
        }
        case GKPeerStateConnected:
        {
            if (self.fServer) {
                // Serverモードの場合
                // 他のPeerに正常に接続したとき
                _stateLabel.text = [NSString stringWithFormat:@"connected to %@", [session displayNameForPeer:peerID]];

                // 送信処理
                // 送るデータを作成
                NSData* data = [self.resultField.text dataUsingEncoding:NSUTF8StringEncoding];
                NSError *err = nil;
                // peerIDに送信する
                [_session sendData:data toPeers:[NSArray arrayWithObject:peerID] withDataMode:GKSendDataReliable error:&err];
            } else {
                // Clientモードの場合
                // 他のPeerに正常に接続したとき
                _stateLabel.text = [NSString stringWithFormat:@"requested to %@", [session displayNameForPeer:peerID]];
            }
            
            break;
        }
        case GKPeerStateDisconnected:
        {
            // 他のPeerが切断されたとき
            _stateLabel.text = [NSString stringWithFormat:@"disconnected"];
            [_session disconnectFromAllPeers];
            [self setConnect:NO];
            break;
        }
    }
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID {
    
    // peerIDからの接続要求を受ける
    [session acceptConnectionFromPeer:peerID error:nil];
}

- (void) receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context {
    
    // 受け取ったデータをUTF8でデコード
    _reception = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
