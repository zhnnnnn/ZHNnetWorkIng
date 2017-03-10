//
//  testCell.m
//  ZHNnetWorkIng
//
//  Created by 张辉男 on 17/2/24.
//  Copyright © 2017年 zhn. All rights reserved.
//

#import "testCell.h"
#import "testModel.h"
#import "UIImageView+WebCache.h"

@interface testCell()

@property (strong,nonatomic) UILabel *nameLabel;
@property (strong,nonatomic) UILabel *addressLabel;
@property (strong,nonatomic) UILabel *noticeLabel;
@property (strong,nonatomic) UIImageView *showImageView;

@end

@implementation testCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self addSubview:self.nameLabel];
        [self addSubview:self.addressLabel];
        [self addSubview:self.noticeLabel];
        [self addSubview:self.showImageView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.nameLabel.frame = CGRectMake(10, 10, 300, 40);
    self.addressLabel.frame = CGRectMake(10, 50, 300, 40);
    self.noticeLabel.frame = CGRectMake(10, 100, 300, 60);
    self.showImageView.frame = CGRectMake(320, 10, 60, 60);
}


#pragma mark - setter getter
- (UILabel *)nameLabel {
    if (_nameLabel == nil) {
        _nameLabel = [[UILabel alloc]init];
    }
    return _nameLabel;
}

- (UILabel *)addressLabel {
    if (_addressLabel == nil) {
        _addressLabel = [[UILabel alloc]init];
    }
    return _addressLabel;
}

- (UILabel *)noticeLabel {
    if (_noticeLabel == nil) {
        _noticeLabel = [[UILabel alloc]init];
        _noticeLabel.numberOfLines = 0;
    }
    return _noticeLabel;
}

- (UIImageView *)showImageView {
    if (_showImageView == nil) {
        _showImageView = [[UIImageView alloc]init];
        _showImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _showImageView;
}

- (void)setModel:(testModel *)model {
    _model = model;
    self.nameLabel.text = model.name;
    self.addressLabel.text = model.address;
    self.noticeLabel.text = model.notice_content;
    NSURL *imageUrl = [NSURL URLWithString:model.pic];
    [self.showImageView sd_setImageWithURL:imageUrl];
}

@end
