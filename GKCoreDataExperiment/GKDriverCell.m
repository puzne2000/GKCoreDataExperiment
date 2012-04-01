//
//  GKDriverCell.m
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 3/30/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import "GKDriverCell.h"

@implementation GKDriverCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
