//
//  GKDriveCell.m
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 5/13/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import "GKDriveCell.h"
#import "GKManagedDriver.h"
#import "GKManagedDrive+CreateDrive.h"

@interface GKDriveCell ()

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation GKDriveCell


@synthesize dateFormatter=_dateFormatter;
-(NSDateFormatter *) dateFormatter{
    if (!_dateFormatter) {
        _dateFormatter=[[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterNoStyle];

    }
    return _dateFormatter;
}


@synthesize drive=_drive;
-(void) setDrive:(GKManagedDrive *)drive{
    _drive=drive;
    self.detailTextLabel.text=[self.dateFormatter stringFromDate: drive.date];
    //self.textLabel.text=drive.driver.name;
    self.textLabel.text=drive.textReportNoDate;
    NSLog(@"setDrive called");
}


/*-(void) setHeight{
    CGRect currentFrame = self.textLabel.frame;
    CGSize max = CGSizeMake(self.textLabel.frame.size.width, 500);
    CGSize expected = [self.textLabel.text sizeWithFont:self.textLabel.font constrainedToSize:max lineBreakMode:self.textLabel.lineBreakMode]; 
    currentFrame.size.height = expected.height;
    self.textLabel.frame = currentFrame;
    self.bounds= CGRectMake(self.bounds.origin.x,
                            self.bounds.origin.y , 
                            self.bounds.size.width, 
                            currentFrame.size.height+100) ;
}
*/


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        self.detailTextLabel.text=@"fuckYou";
        self.textLabel.text=@"wowowowo";
        NSLog(@"cell initialized");
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
