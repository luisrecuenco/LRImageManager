//
//  ViewController.m
//  LRImageManagerDemo
//
//  Created by qtone-1 on 14-4-14.
//  Copyright (c) 2014年 Luis Recuenco. All rights reserved.
//

#import "ViewController.h"

#import "UIImageView+LRNetworking.h"

@interface ViewController ()

@end

@implementation ViewController

- (NSArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [[NSArray alloc] initWithObjects:
                       @"http://d.hiphotos.baidu.com/image/w%3D2048/sign=eac4759f74094b36db921ced97f47dd9/e1fe9925bc315c60efc1e0af8fb1cb134954771e.jpg",
                       @"http://g.hiphotos.baidu.com/image/w%3D2048/sign=92271eb0820a19d8cb03830507c2838b/d53f8794a4c27d1e8c837cc519d5ad6eddc4380d.jpg",
                       @"http://e.hiphotos.baidu.com/image/w%3D2048/sign=58ca416831fa828bd1239ae3c9274034/d31b0ef41bd5ad6e3930a18783cb39dbb7fd3c96.jpg",
                       @"http://f.hiphotos.baidu.com/image/w%3D2048/sign=1e99b7e9f503918fd7d13aca65052797/242dd42a2834349b7e858e8ccbea15ce36d3be3c.jpg",
                       @"http://h.hiphotos.baidu.com/image/w%3D2048/sign=998c8ac69252982205333ec3e3f27acb/11385343fbf2b2114cbc334fc88065380cd78e25.jpg",
                       @"http://e.hiphotos.baidu.com/image/w%3D2048/sign=0717cecbb0119313c743f8b051000dd7/e4dde71190ef76c6f3bbfb229f16fdfaaf516749.jpg",
                       @"http://d.hiphotos.baidu.com/image/w%3D2048/sign=618830d52c738bd4c421b53195b386d6/3c6d55fbb2fb4316d61e357222a4462309f7d3b1.jpg",
                       @"http://g.hiphotos.baidu.com/image/w%3D2048/sign=aa9cd31b369b033b2c88fbda21f637d3/a2cc7cd98d1001e947b7da10ba0e7bec54e79722.jpg",
                       @"http://a.hiphotos.baidu.com/image/w%3D2048/sign=baaeed62372ac65c67056173cfcab311/b8389b504fc2d562051ce1efe51190ef76c66c9f.jpg",
                       @"http://e.hiphotos.baidu.com/image/w%3D2048/sign=663e6891a60f4bfb8cd09954377779f0/86d6277f9e2f0708cc042d0eeb24b899a901f2bf.jpg",
                       @"http://f.hiphotos.baidu.com/image/w%3D2048/sign=733c5ddc3f6d55fbc5c67126591a4e4a/14ce36d3d539b6006f583eb5eb50352ac65cb719.jpg",
                       @"http://b.hiphotos.baidu.com/image/w%3D2048/sign=205668f19e82d158bb825eb1b43218d8/c2fdfc039245d68825605cbba6c27d1ed21b244b.jpg",
                       @"http://a.hiphotos.baidu.com/image/w%3D2048/sign=61344df739c79f3d8fe1e3308e99cd11/7a899e510fb30f24eaaee40bca95d143ad4b0385.jpg",
                       @"http://a.hiphotos.baidu.com/image/w%3D2048/sign=d6226f51f4246b607b0eb574dfc01b4c/96dda144ad345982da9cd4900ef431adcbef8499.jpg",
                       @"http://a.hiphotos.baidu.com/image/w%3D2048/sign=bc3e65ef8fb1cb133e693b13e96c574e/f9dcd100baa1cd11fa1d7c20bb12c8fcc3ce2d02.jpg",
                       @"http://g.hiphotos.baidu.com/image/w%3D2048/sign=46c7c3298418367aad8978dd1a4b8ad4/09fa513d269759eecbfb6ecbb0fb43166d22df03.jpg",
                       @"http://p.rdcpix.com/v01/ld7b5e443-m0s.jpg",
                       @"http://p.rdcpix.com/v01/ld01f7943-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l27cbef43-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l12f4e643-m0s.jpg",
                       @"http://g.hiphotos.baidu.com/image/w%3D2048/sign=55e93176f01fbe091c5ec4145f580c33/64380cd7912397dd8f6696045b82b2b7d0a28796.jpg",
                       @"http://p.rdcpix.com/v01/l0e0afb43-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l06fff943-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l1b74cb43-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l8c66f943-m0s.jpg",
                       @"http://c.hiphotos.baidu.com/image/w%3D2048/sign=525dac12249759ee4a5067cb86c34216/5ab5c9ea15ce36d38f9e4b2f38f33a87e950b113.jpg",
                       @"http://p.rdcpix.com/v02/le63bd843-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l06fff943-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l1b74cb43-m0s.jpg",
                       @"http://f.hiphotos.baidu.com/image/w%3D2048/sign=963e16ebb54543a9f51bfdcc2a2f8a82/0b7b02087bf40ad147fe0ffc552c11dfa9ecce93.jpg",
                       @"http://p.rdcpix.com/v01/l9d1d7943-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l9a1af543-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l5c1c7943-m0s.jpg",
                       @"http://p.rdcpix.com/v01/lb73a0244-m0s.jpg",
                       @"http://f.hiphotos.baidu.com/image/w%3D2048/sign=3051e2ff79899e51788e3d14769fd833/3812b31bb051f81983b33248d8b44aed2e73e719.jpg",
                       @"http://p.rdcpix.com/v01/lb7c4f643-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l9d1d7943-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l9a1af543-m0s.jpg",
                       @"http://c.hiphotos.baidu.com/image/w%3D2048/sign=6eb35be02d2eb938ec6d7df2e15a8435/b2de9c82d158ccbf56d5ed3b1bd8bc3eb1354141.jpg",
                       @"http://p.rdcpix.com/v01/ld3bed343-m0s.jpg",
                       @"http://p.rdcpix.com/v01/le3acd143-m0s.jpg",
                       @"http://p.rdcpix.com/v01/le41e7943-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l9d1d7943-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l9a1af543-m0s.jpg",
                       @"http://g.hiphotos.baidu.com/image/w%3D2048/sign=8a715be28fb1cb133e693b13e96c574e/f9dcd100baa1cd11cc52422dbb12c8fcc2ce2dd2.jpg",
                       @"http://p.rdcpix.com/v01/l03cf0144-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l1a62f143-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l9d1d7943-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l9a1af543-m0s.jpg",
                       @"http://d.hiphotos.baidu.com/image/w%3D2048/sign=83cef8530bf79052ef1f403e38cbd6ca/c75c10385343fbf2117b2d63b27eca8065388f1f.jpg",
                       @"http://c.hiphotos.baidu.com/image/w%3D2048/sign=cb0998e75bee3d6d22c680cb772e6c22/c8ea15ce36d3d5392c3484833887e950352ab061.jpg",
                       @"http://a.hiphotos.baidu.com/image/w%3D2048/sign=728033660b24ab18e016e63701c2e7cd/8b82b9014a90f603536b4a073b12b31bb151ed93.jpg",
                       @"http://g.hiphotos.baidu.com/image/w%3D2048/sign=62ffbf1036a85edffa8cf9237d6c0823/3ac79f3df8dcd100646f2e61708b4710b8122ffb.jpg",
                       @"http://h.hiphotos.baidu.com/image/w%3D2048/sign=73b490ada1cc7cd9fa2d33d90d39203f/35a85edf8db1cb13964fb753df54564e92584b48.jpg",
                       @"http://d.hiphotos.baidu.com/image/w%3D2048/sign=5309e6f7be3eb13544c7b0bb9226a8d3/a5c27d1ed21b0ef4c8d65241dfc451da81cb3ef7.jpg",
                       nil];
    }
    return _dataSource;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    [cell.imageView lr_setImageWithURL:[NSURL URLWithString:self.dataSource[indexPath.row]] placeholderImage:[UIImage imageNamed:@"placeholder"] storageOptions:LRCacheStorageOptionsNSDictionary];
    
    return cell;
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}

@end
