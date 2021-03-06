//
//  MCCZImageView.m
//  The simplest zoomable image view... ever ;)
//
//  Created by Thierry Passeron on 18/03/12.
//  Copyright (c) 2012 Monte-Carlo Computing. All rights reserved.
//

/*

  Copyright (c), 2012 Thierry Passeron

  The MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to
  deal in the Software without restriction, including without limitation the
  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
  sell copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
  IN THE SOFTWARE.

*/

#import "MCCZImageView.h"
//#define DEBUG_MCCZImageView

@interface MCCZImageView ()
@property (retain, nonatomic) UIImageView *imageView;
@end

@implementation MCCZImageView
@synthesize contentMode, imageView;

- (id)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    
    /* ScrollView setup */
    self.pagingEnabled = NO;
    self.showsHorizontalScrollIndicator = NO;
		self.showsVerticalScrollIndicator = NO;
		self.decelerationRate = UIScrollViewDecelerationRateFast;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.autoresizesSubviews = NO;
    self.delegate = self;
    
    /* Embedded ImageView setup */
    self.imageView = [[[UIImageView alloc]initWithFrame:CGRectZero]autorelease];
//    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    imageView.contentMode = UIViewContentModeCenter;
    imageView.backgroundColor = [UIColor clearColor];
    [self addSubview:imageView];
    
    /* Default starting contentMode */
    self.contentMode = UIViewContentModeScaleAspectFit;
    
    /* setup gestures recognizer for zooming */
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapDetected:)]autorelease];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    doubleTapGestureRecognizer.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:doubleTapGestureRecognizer];
    
  }
  return self;
}

- (void)dealloc {
  self.imageView = nil;
  [super dealloc];
}

- (NSString *)description {
  return [[super description]stringByAppendingFormat:@"\nImageView: %@", self.imageView];
}


#pragma mark UIScrollView delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView { return imageView; }


#pragma mark Layout management

- (void)layoutSubviews {
  CGSize boundsSize = self.bounds.size;
  CGRect frameToCenter = imageView.frame;
  
  if (frameToCenter.size.width != 0.0f) {
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
      frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0f);
    } else {
      frameToCenter.origin.x = 0.0f;
    }
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
      frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0f);
    } else {
      frameToCenter.origin.y = 0.0f;
    }
  
    // Center if needed
    if (!CGRectEqualToRect(self.imageView.frame, frameToCenter)) {
      self.imageView.frame = frameToCenter;
#ifdef DEBUG_MCCZImageView
      NSLog(@"centered: %@", imageView);
#endif
    }
  } else {
#ifdef DEBUG_MCCZImageView
    NSLog(@"No frame to center: %@", imageView);
#endif
  }
  
  [super layoutSubviews];
}

- (void)setFrame:(CGRect)frame {
  [super setFrame:frame];
  if (imageView.image) [self reset];
}


#pragma mark content management

- (void)setImage:(UIImage *)image {
  imageView.image = image;
  if (image) [self reset];
}

- (void)reset {
  CGSize imageSize = imageView.image.size;

  // Reset imageView frame and bounds
  imageView.frame = CGRectMake(0.0f, 0.0f, imageSize.width, imageSize.height);
  imageView.bounds = self.imageView.frame;
  
  // Reset scrollView content
  self.contentSize = imageSize;
  self.contentOffset = CGPointMake(0.0f, 0.0f);
  
  // Content mode sets current zoomscale
  _resetZoom(self, contentMode, imageView);
}

NS_INLINE void _resetZoom(UIScrollView *self, UIViewContentMode contentMode, UIImageView *imageView) {
  CGSize imageSize = imageView.image.size;
  CGSize boundsSize = self.bounds.size;
  
  // Compute zoom scales
  CGFloat xScale = boundsSize.width / imageSize.width;
  CGFloat yScale = boundsSize.height / imageSize.height;
  
  CGFloat fitScale = MIN(xScale, yScale);
  CGFloat fillScale = MAX(xScale, yScale);
  CGFloat minScale = fitScale;
	
  CGFloat maxScale = 2.0f; // Allow double scale TODO: allow users to specify the max
	if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
		maxScale = maxScale / [[UIScreen mainScreen] scale];
	}
  
	// If image is smaller than the screen then ensure we show it at
	// min scale of 1
	if (xScale > 1.0f && yScale > 1.0f) {
    minScale = 1.0f;
    maxScale = 2.0f;
  }
  
  // Set min and max zoomscales
  self.minimumZoomScale = minScale;
  self.maximumZoomScale = maxScale;
  switch (contentMode) {
    case UIViewContentModeCenter:
      self.zoomScale = 1.0;
      break;
    case UIViewContentModeScaleAspectFit:
      self.zoomScale = fitScale;
      break;
    case UIViewContentModeScaleAspectFill:
      self.zoomScale = fillScale;
      break;
    default:
      self.zoomScale = fitScale;
  }
}

- (void)setZoomScaleForContentMode:(UIViewContentMode)mode animated:(BOOL)animated {
  if (animated) {
    [UIView animateWithDuration:0.2 animations:^{
      _resetZoom(self, contentMode, imageView);
    }];
  } else {
    _resetZoom(self, contentMode, imageView);
  }
}


#pragma mark Gestures handlers

- (void)doubleTapDetected:(UITapGestureRecognizer *)sender {
#ifdef DEBUG_MCCZImageView
  NSLog(@"double tap: %f (%f - %f)", self.zoomScale, self.minimumZoomScale, self.maximumZoomScale);
#endif
  if (sender.state == UIGestureRecognizerStateEnded) {
    CGFloat targetZoomScale = 1.0f;
    if (self.zoomScale < self.maximumZoomScale) {
      
      targetZoomScale = self.maximumZoomScale;
    } else {
      targetZoomScale = self.minimumZoomScale;
    }
#ifdef DEBUG_MCCZImageView
    NSLog(@"target zoom scale: %f", targetZoomScale);
#endif
    [self setZoomScale:targetZoomScale animated:YES];
  }
  
  // Gentely forward the double tap to the next responder to cancel single tap detections mainely
  if (self.nextResponder && [self.nextResponder respondsToSelector:@selector(doubleTapDetected:)]) {
    [self.nextResponder performSelector:@selector(doubleTapDetected:) withObject:(sender)];
  }
}

@end
