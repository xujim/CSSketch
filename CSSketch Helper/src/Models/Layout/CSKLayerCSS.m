//
//  CSKLayerCSS.m
//  CSSketch Helper
//
//  Created by John Coates on 10/9/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

#import "CSKLayerCSS.h"

@implementation CSKLayerCSS

#pragma mark - Entry Point

+ (void)handleCSSPropertiesWithDOMLeaf:(NSDictionary *)leaf layer:(CSK_MSLayer *)layer {

    // layout
    [self handleFrameWithDOMLeaf:leaf layer:layer];
    
    // border
    [self handleBorderWithDOMLeaf:leaf layer:layer];
    
    // shadow
    [self handleShadowWithDOMLeaf:leaf layer:layer];
    
    // background color
    [self handleBackgroundColorWithDOMLeaf:leaf layer:layer];
    
    if ([layer isKindOfClass:NSClassFromString(@"MSTextLayer")]) {
        // color
        [self handleTextColorWithDOMLeaf:leaf layer:layer];
        
        // text-tranform
        [self handleTextTransformWithDOMLeaf:leaf layer:layer];
    }
    
}

#pragma mark - Layout, Size

+ (void)handleFrameWithDOMLeaf:(NSDictionary *)leaf layer:(CSK_MSLayer *)layer {
    NSRect artboardFrame = layer.frameInArtboard;
    NSRect originalFrame = artboardFrame;
    if (DEBUG) {
        NSLog(@"artboard frame: %@", NSStringFromRect(artboardFrame));
    }
    NSDictionary *rules = leaf[@"rules"];
    NSNumber *offsetLeft = rules[@"offsetLeft"];
    NSNumber *offsetTop = rules[@"offsetTop"];
    
    artboardFrame.origin.y = offsetTop.floatValue;
    artboardFrame.origin.x = offsetLeft.floatValue;
    if (NSEqualRects(artboardFrame, originalFrame) == FALSE) {
        if (DEBUG) {
            NSLog(@"new artboard frame: %@", NSStringFromRect(artboardFrame));
        }
        [layer setFrameInArtboard:artboardFrame];
    }
    
    
    CGRect rect = layer.rect;
    CGRect originalRect = rect;
    NSString *width = rules[@"width"];
    NSString *height = rules[@"height"];
    if (width) {
        rect.size.width = width.floatValue;
    }
    
    if (height) {
        rect.size.height = height.floatValue;
    }
    
    if (NSEqualRects(rect, originalRect) == FALSE) {
        if (DEBUG) {
            NSLog(@"setting size %@ from %@", NSStringFromSize(rect.size), NSStringFromSize(originalRect.size));
        }
        layer.rect = rect;
    }
}


#pragma mark - Border

+ (void)handleBorderWithDOMLeaf:(NSDictionary *)leaf layer:(CSK_MSLayer *)layer {
    NSDictionary *rules = leaf[@"rules"];
    
    NSString *colorString = rules[@"border-bottom-color"];
    
    if (!colorString) {
        return;
    }
    
    CSK_MSColor *color = [self colorFromString:colorString];
    CSK_MSStylePartCollection *borders = layer.style.borders;
    
    if (!borders.count) {
        [borders addNewStylePart];
    }
    
    CSK_MSStyleBorder *border = layer.style.border;
    border.color = color;
    
    NSString *thickness = rules[@"border-bottom-width"];
    if (thickness) {
        border.thickness = thickness.doubleValue;
    }
    
    NSString *boxSizing = rules[@"box-sizing"];
    if ([boxSizing isEqualToString:@"border-box"]) {
        border.position = MSStyleBorderPositionInside;
    }

}

#pragma mark - Shadows


+ (void)handleShadowWithDOMLeaf:(NSDictionary *)DOMLeaf layer:(CSK_MSLayer *)layer {
    NSDictionary *rules = DOMLeaf[@"rules"];
    
    NSString *boxShadow = rules[@"box-shadow"];
    
    if (!boxShadow) {
        return;
    }
    
    // add new shadow if it's missing one
    if (!layer.style.shadows.count) {
        [layer.style.shadows addNewStylePart];
    }
    
    RxMatch *match = [boxShadow firstMatchWithDetails:RX(@"(rgba?\\([^)]+\\)) ([0-9-]{1,4})[a-z]* ([0-9-]{1,4})[a-z]* ([0-9-]{1,4})[a-z]* ([0-9-]{1,4})[a-z]*")];
    
    if (!match) {
        if (DEBUG) {
            NSLog(@"couldn't read boxShadow rule: %@", boxShadow);
        }
        return;
    }
    else {
        if (DEBUG) {
            NSLog(@"boxShadow rule: %@", boxShadow);
        }
    }
    
    RxMatchGroup *colorString = match.groups[1];
    RxMatchGroup *hShadowGroup = match.groups[2];
    RxMatchGroup *vShadowGroup = match.groups[3];
    RxMatchGroup *blurGroup = match.groups[4];
    RxMatchGroup *spreadGroup = match.groups[5];
    
    
    if (![CSKMainController inSketch]) {
        return;
    }
    
    
    CSK_MSColor *color = [self colorFromString:colorString.value];
    
    CSK_MSStyleShadow *shadow = layer.style.shadow;
    shadow.spread = spreadGroup.value.doubleValue;
    shadow.offsetX = hShadowGroup.value.doubleValue;
    shadow.offsetY = vShadowGroup.value.doubleValue;
    shadow.blurRadius = blurGroup.value.doubleValue;
    shadow.color = color;
 
    if (DEBUG) {
        NSLog(@"setting boxShadow %@ with color %@", shadow, color);
    }
}

#pragma mark - Background

+ (void)handleBackgroundColorWithDOMLeaf:(NSDictionary *)DOMLeaf layer:(CSK_MSLayer *)layer {
    NSDictionary *rules = DOMLeaf[@"rules"];
    
    NSString *backgroundColorString = rules[@"background-color"];
    
    if (!backgroundColorString) {
        return;
    }
    
    // don't apply to text
    if ([layer isKindOfClass:NSClassFromString(@"MSTextLayer")]) {
        return;
    }
    
    CSK_MSColor *backgroundColor = [self colorFromString:backgroundColorString];
    
    if (!backgroundColor) {
        return;
    }
    
    if ([layer isKindOfClass:NSClassFromString(@"MSArtboardGroup")]) {
        CSK_MSArtboardGroup *artboard = (CSK_MSArtboardGroup *)layer;
        artboard.backgroundColor = backgroundColor;
        
        return;
    }
    
    if (!layer.style.fills.count) {
        [layer.style.fills addNewStylePart];
    }
    
    CSK_MSStyleFill *fill = layer.style.fill;
    
    if (!fill) {
        return;
    }
    
    fill.color = backgroundColor;
}

#pragma mark - Text

+ (void)handleTextTransformWithDOMLeaf:(NSDictionary *)DOMLeaf layer:(CSK_MSLayer *)layer {
    NSDictionary *rules = DOMLeaf[@"rules"];
    
    NSString *textTransform = rules[@"text-transform"];
    
    if (!textTransform) {
        return;
    }
    
    CSK_MSTextLayer *textLayer = (CSK_MSTextLayer *)layer;
//    MSTextLayer *myl;
    

    NSString *currentString = textLayer.stringValue;
    NSString *newString = nil;
    
    if ([textTransform isEqualToString:@"capitalize"]) {
        newString = [currentString capitalizedString];
    }
    else if ([textTransform isEqualToString:@"uppercase"]) {
        newString = [currentString uppercaseString];
    }
    else if ([textTransform isEqualToString:@"loweracse"]) {
        newString = [currentString lowercaseString];
    }
    else {
        
        NSString *error = [NSString stringWithFormat:@"unsupported text-transform: %@", textTransform];
        [CSKMainController displayError:error];
        return;
    }
    
    textLayer.stringValue = newString;
}

+ (void)handleTextColorWithDOMLeaf:(NSDictionary *)DOMLeaf layer:(CSK_MSLayer *)layer {
    NSDictionary *rules = DOMLeaf[@"rules"];
    
    NSString *colorString = rules[@"color"];
    
    if (!colorString) {
        return;
    }
    
    
    CSK_MSColor *color = [self colorFromString:colorString];
    
    if (!color) {
        return;
    }
    
    
    CSK_MSTextLayer *textLayer = (CSK_MSTextLayer *)layer;
    // Having text update immediately took a lot of figuring out
    // I hope you appreciate it!
    
    [textLayer markLayerDirtyOfType:CSKMSLayerDirtyTypeTextColor];
    
    [textLayer prepareForUndo];
    
    NSTextStorage *storage = textLayer.storage;
    [storage beginEditing];
    storage.foregroundColor = [NSColor colorWithRed:color.red
                                              green:color.green
                                               blue:color.blue
                                              alpha:color.alpha];
    
    [storage endEditing];
    [textLayer setTextAlignment:NSTextAlignmentRight];
    [textLayer syncTextStyleAttributes];
    [textLayer setTextColor:[CSK_MSColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1]];
    [textLayer layerDidChange];
    
    [textLayer invalidateLightweightCopy:nil];
    
}


#pragma mark - Helpers

+ (CSK_MSColor *)colorFromString:(NSString *)colorString {
    RxMatch *rgbaMatch = [colorString
                          firstMatchWithDetails:RX(@"rgba\\(([0-9]{1,3}), ([0-9]{1,3}), ([0-9]{1,3}), ([0-9]*\\.?[0-9]*)\\)")];
    
    if (rgbaMatch) {
        if (DEBUG) {
//            NSLog(@"%@ matches: %@", colorString, rgbaMatch.groups);
        }
        RxMatchGroup *rGroup = rgbaMatch.groups[1];
        RxMatchGroup *gGroup = rgbaMatch.groups[2];
        RxMatchGroup *bGroup = rgbaMatch.groups[3];
        RxMatchGroup *aGroup = rgbaMatch.groups[4];
        
        CSK_MSColor *color = [CSK_MSColor colorWithRed:rGroup.value.floatValue / 255.0
                                                 green:gGroup.value.floatValue / 255.0
                                                  blue:bGroup.value.floatValue / 255.0
                                                 alpha:aGroup.value.floatValue];
        
        return color;
    }
    
    RxMatch *rgbMatch = [colorString
                         firstMatchWithDetails:RX(@"rgb\\(([0-9]{1,3}), ([0-9]{1,3}), ([0-9]{1,3})\\)")];
    
    if (rgbMatch) {
        if (DEBUG) {
            NSLog(@"%@ matches: %@", colorString, rgbMatch.groups);
        }
        RxMatchGroup *rGroup = rgbMatch.groups[1];
        RxMatchGroup *gGroup = rgbMatch.groups[2];
        RxMatchGroup *bGroup = rgbMatch.groups[3];
        
        CSK_MSColor *color = [CSK_MSColor colorWithRed:rGroup.value.floatValue / 255.0
                                                 green:gGroup.value.floatValue / 255.0
                                                  blue:bGroup.value.floatValue / 255.0
                                                 alpha:1];
        
        
        return color;
    }
    
    if (DEBUG) {
        NSLog(@"couldn't get color from %@", colorString);
    }
    
    return nil;
}

@end
