//
//  PKPaymentField.m
//  PKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#define RGB(r,g,b) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0f]

//#define DarkGreyColor RGB(0,0,0)
#define DarkGreyColor RGB(125.0f,125.0f,125.0f)

#define RedColor RGB(253,0,17)

//#define DefaultBoldFont [UIFont boldSystemFontOfSize:17]
#define DefaultBoldFont [UIFont fontWithName:@"ProximaNova-Semibold" size:13]

#define kPKViewPlaceholderViewAnimationDuration 0.25

#define kPKViewCardNumberFieldStartX 0
#define kPKViewCardExpiryFieldStartX 50 + 200 //84 + 200
#define kPKViewCardCVCFieldStartX 112 + 200 //177 + 200
#define kPKViewCardPostalFieldStartX 160 + 200

#define kPKViewCardExpiryFieldEndX 50 //84
#define kPKViewCardCVCFieldEndX 112 //177
#define kPKViewCardPostalFieldEndX 160

static NSString *const kPKLocalizedStringsTableName = @"PaymentKit";
static NSString *const kPKOldLocalizedStringsTableName = @"STPaymentLocalizable";

#import "PKView.h"
#import "PKTextField.h"
#import "BTUICardType.h"

@interface PKView () <PKTextFieldDelegate> {
@private
    BOOL _isInitialState;
    BOOL _isValidState;
}

@property (nonatomic, readonly, assign) UIResponder *firstResponderField;
@property (nonatomic, readonly, assign) PKTextField *firstInvalidField;
@property (nonatomic, readonly, assign) PKTextField *nextFirstResponder;

- (void)setup;
- (void)setupPlaceholderView;
- (void)setupCardNumberField;
- (void)setupCardExpiryField;
- (void)setupCardCVCField;

- (void)pkTextFieldDidBackSpaceWhileTextIsEmpty:(PKTextField *)textField;

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardNumberFieldShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardExpiryShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardCVCShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;

@property (nonatomic) PKCardNumber *cardNumber;
@property (nonatomic) PKCardExpiry *cardExpiry;
@property (nonatomic) PKCardCVC *cardCVC;
@property (nonatomic) PKAddressZip *addressZip;
@end

#pragma mark -

@implementation PKView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
        self.font = DefaultBoldFont;
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
    _isInitialState = YES;
    _isValidState = NO;
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, 290, 36);
    self.backgroundColor = [UIColor clearColor];
    
    [self setupPlaceholderView];
    [self setupCardNumberField];
    [self setupCardExpiryField];
    [self setupCardCVCField];
    [self setupCardPostalCode];
    
    CGFloat placeHolderMaxX = CGRectGetMaxX(self.placeholderView.frame);
    CGRect innerViewFrame = CGRectMake(placeHolderMaxX + 5, 0,
                                       self.frame.size.width - placeHolderMaxX - 5, 36);
    
    self.innerView = [[UIView alloc] initWithFrame:innerViewFrame];
    self.innerView.center = CGPointMake(self.innerView.center.x, self.bounds.size.height/2);
    self.innerView.clipsToBounds = YES;
    [self.innerView addSubview:self.cardNumberField];
    
    for(UIView *v in @[self.cardNumberField, self.cardExpiryField, self.cardCVCField, self.cardPostalField]) {
        // Center text fields vertically
        v.center = CGPointMake(v.center.x, self.innerView.bounds.size.height/2);
    }
    
    [self addSubview:self.innerView];
    [self addSubview:self.placeholderView];
    
    [self stateCardNumber];
}

- (void)setFont:(UIFont *)font
{
    _font = font;
    self.cardNumberField.font = font;
    self.cardExpiryField.font = font;
    self.cardCVCField.font = font;
    self.cardPostalField.font = font;
    
}

// Mimic a fullwidth textfield for initial state
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if(_isInitialState && [self pointInside:point withEvent:event])
        return self.cardNumberField;
    
    return [super hitTest:point withEvent:event];
}
- (void)setupPlaceholderView
{
    self.placeholderView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 0, 32, 20)];
    self.placeholderView.center = CGPointMake(self.placeholderView.center.x, self.bounds.size.height/2 + 1);
    self.placeholderView.backgroundColor = [UIColor clearColor];
    self.placeholderView.image = [UIImage imageNamed:@"placeholder"];
}

- (void)setupCardNumberField
{
    self.cardNumberField = [[PKTextField alloc] initWithFrame:CGRectMake(kPKViewCardNumberFieldStartX, 0, 170, 20)];
    self.cardNumberField.delegate = self;
    [self.cardNumberField addTarget:self action:@selector(cardNumberFieldChanged) forControlEvents:UIControlEventEditingChanged];
    self.cardNumberField.placeholder = [self.class localizedStringWithKey:@"placeholder.card_number" defaultValue:@"1234 5678 9012 3456"];
    self.cardNumberField.keyboardType = UIKeyboardTypeNumberPad;
    self.cardNumberField.textColor = DarkGreyColor;
    self.cardNumberField.font = self.font;
    
    [self.cardNumberField.layer setMasksToBounds:YES];
}

- (void)setupCardExpiryField
{
    self.cardExpiryField = [[PKTextField alloc] initWithFrame:CGRectMake(kPKViewCardExpiryFieldStartX, 0, 45, 20)];
    self.cardExpiryField.delegate = self;
    self.cardExpiryField.placeholder = [self.class localizedStringWithKey:@"placeholder.card_expiry" defaultValue:@"MM/YY"];
    self.cardExpiryField.keyboardType = UIKeyboardTypeNumberPad;
    self.cardExpiryField.textColor = DarkGreyColor;
    self.cardExpiryField.font = self.font;
    [self.cardExpiryField sizeToFit];
    
    [self.cardExpiryField.layer setMasksToBounds:YES];
}

- (void)setupCardCVCField
{
    self.cardCVCField = [[PKTextField alloc] initWithFrame:CGRectMake(kPKViewCardCVCFieldStartX, 0, 30, 20)];
    self.cardCVCField.delegate = self;
    self.cardCVCField.placeholder = [self.class localizedStringWithKey:@"placeholder.card_cvc" defaultValue:@"CVC"];
    self.cardCVCField.keyboardType = UIKeyboardTypeNumberPad;
    self.cardCVCField.textColor = DarkGreyColor;
    self.cardCVCField.font = self.font;
    [self.cardCVCField sizeToFit];
    
    
    [self.cardCVCField.layer setMasksToBounds:YES];
}

- (void)setupCardPostalCode
{
    _cardPostalField = [[PKTextField alloc] initWithFrame:CGRectMake(kPKViewCardPostalFieldStartX, 0, 75, 20)];
    self.cardPostalField.delegate = self;
    self.cardPostalField.placeholder = [self.class localizedStringWithKey:@"placeholder.card_postal" defaultValue:@"Postal Code"];
    self.cardPostalField.textColor = DarkGreyColor;
    self.cardPostalField.font = self.font;
    self.cardPostalField.returnKeyType = UIReturnKeyNext;
    [self.cardPostalField sizeToFit];
    
    
    [self.cardPostalField.layer setMasksToBounds:YES];
}

// Checks both the old and new localization table (we switched in 3/14 to PaymentKit.strings).
// Leave this in for a long while to preserve compatibility.
+ (NSString *)localizedStringWithKey:(NSString *)key defaultValue:(NSString *)defaultValue
{
    NSString *value = NSLocalizedStringFromTable(key, kPKLocalizedStringsTableName, nil);
    if (value && ![value isEqualToString:key]) { // key == no value
        return value;
    } else {
        value = NSLocalizedStringFromTable(key, kPKOldLocalizedStringsTableName, nil);
        if (value && ![value isEqualToString:key]) {
            return value;
        }
    }
    
    return defaultValue;
}

#pragma mark - Accessors

- (PKCardNumber *)cardNumber
{
    return [PKCardNumber cardNumberWithString:self.cardNumberField.text];
}

- (PKCardExpiry *)cardExpiry
{
    return [PKCardExpiry cardExpiryWithString:self.cardExpiryField.text];
}

- (PKCardCVC *)cardCVC
{
    return [PKCardCVC cardCVCWithString:self.cardCVCField.text];
}

#pragma mark - State

- (void)stateCardNumber
{
    if (!_isInitialState) {
        // Animate left
        _isInitialState = YES;
        
        [UIView animateWithDuration:0.400
                              delay:0
                            options:(UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction)
                         animations:^{
                             self.cardExpiryField.frame = CGRectMake(kPKViewCardExpiryFieldStartX,
                                                                     self.cardExpiryField.frame.origin.y,
                                                                     self.cardExpiryField.frame.size.width,
                                                                     self.cardExpiryField.frame.size.height);
                             self.cardCVCField.frame = CGRectMake(kPKViewCardCVCFieldStartX,
                                                                  self.cardCVCField.frame.origin.y,
                                                                  self.cardCVCField.frame.size.width,
                                                                  self.cardCVCField.frame.size.height);
                             self.cardPostalField.frame = CGRectMake(kPKViewCardPostalFieldStartX,
                                                                     self.cardPostalField.frame.origin.y,
                                                                     self.cardPostalField.frame.size.width,
                                                                     self.cardPostalField.frame.size.height);
                             self.cardNumberField.frame = CGRectMake(kPKViewCardNumberFieldStartX,
                                                                     self.cardNumberField.frame.origin.y,
                                                                     self.cardNumberField.frame.size.width,
                                                                     self.cardNumberField.frame.size.height);
                         }
                         completion:^(BOOL completed) {
                             [self.cardExpiryField removeFromSuperview];
                             [self.cardCVCField removeFromSuperview];
                             [self.cardPostalField removeFromSuperview];
                         }];
    }
    
    [self.cardNumberField becomeFirstResponder];
}

- (void)stateMeta
{
    _isInitialState = NO;
    
    CGSize cardNumberSize;
    CGSize lastGroupSize;
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
    if ([self.cardNumber.formattedString respondsToSelector:@selector(sizeWithAttributes:)]) {
        NSDictionary *attributes = @{NSFontAttributeName: self.font};
        
        cardNumberSize = [self.cardNumber.formattedString sizeWithAttributes:attributes];
        lastGroupSize = [self.cardNumber.lastGroup sizeWithAttributes:attributes];
    } else {
        cardNumberSize = [self.cardNumber.formattedString sizeWithFont:self.font];
        lastGroupSize = [self.cardNumber.lastGroup sizeWithFont:self.font];
    }
#else
    NSDictionary *attributes = @{NSFontAttributeName: self.font};
    
    cardNumberSize = [self.cardNumber.formattedString sizeWithAttributes:attributes];
    lastGroupSize = [self.cardNumber.lastGroup sizeWithAttributes:attributes];
#endif
    
    CGFloat frameX = self.cardNumberField.frame.origin.x - (cardNumberSize.width - lastGroupSize.width + 8);
    CGFloat padding = self.innerView.frame.size.width;
    padding -= lastGroupSize.width;
    padding -= self.cardExpiryField.frame.size.width;
    padding -= self.cardCVCField.frame.size.width;
    padding -= self.cardPostalField.frame.size.width;
    padding /= 4.0f;
    
    [UIView animateWithDuration:0.400 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.cardExpiryField.frame = CGRectMake(lastGroupSize.width + padding,
                                                self.cardExpiryField.frame.origin.y,
                                                self.cardExpiryField.frame.size.width,
                                                self.cardExpiryField.frame.size.height);
        self.cardCVCField.frame = CGRectMake(CGRectGetMaxX(self.cardExpiryField.frame) + padding,
                                             self.cardCVCField.frame.origin.y,
                                             self.cardCVCField.frame.size.width,
                                             self.cardCVCField.frame.size.height);
        self.cardPostalField.frame = CGRectMake(CGRectGetMaxX(self.cardCVCField.frame) + padding,
                                                self.cardPostalField.frame.origin.y,
                                                self.cardPostalField.frame.size.width,
                                                self.cardPostalField.frame.size.height);
        self.cardNumberField.frame = CGRectMake(frameX,
                                                self.cardNumberField.frame.origin.y,
                                                self.cardNumberField.frame.size.width,
                                                self.cardNumberField.frame.size.height);
    }                completion:nil];
    
    [self addSubview:self.placeholderView];
    [self.innerView addSubview:self.cardExpiryField];
    [self.innerView addSubview:self.cardCVCField];
    [self.innerView addSubview:self.cardPostalField];
    [self.cardExpiryField becomeFirstResponder];
}

- (void)stateCardCVC
{
    [self.cardCVCField becomeFirstResponder];
}

- (BOOL)isValid
{
    return [self.cardNumber isValid] && [self.cardExpiry isValid] && [self postalCodeValid] &&
    [self.cardCVC isValidWithType:self.cardNumber.cardType];
}

- (BOOL)postalCodeValid
{
    NSArray* cleanedZip = [self.cardPostalField.text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [cleanedZip componentsJoinedByString:@""].length >= 3;
}

- (PKCard *)card
{
    PKCard *card = [[PKCard alloc] init];
    card.number = [self.cardNumber string];
    card.cvc = [self.cardCVC string];
    card.expMonth = [self.cardExpiry month];
    card.expYear = [self.cardExpiry year];
    card.addressZip = self.cardPostalField.text;
    
    return card;
}

- (void)setPlaceholderViewImage:(UIImage *)image
{
    if (![self.placeholderView.image isEqual:image]) {
        __block __unsafe_unretained UIView *previousPlaceholderView = self.placeholderView;
        [UIView animateWithDuration:kPKViewPlaceholderViewAnimationDuration delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.placeholderView.layer.opacity = 0.0;
                             self.placeholderView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1.2);
                         } completion:^(BOOL finished) {
                             [previousPlaceholderView removeFromSuperview];
                         }];
        self.placeholderView = nil;
        
        [self setupPlaceholderView];
        self.placeholderView.image = image;
        self.placeholderView.layer.opacity = 0.0;
        self.placeholderView.layer.transform = CATransform3DMakeScale(0.8, 0.8, 0.8);
        [self insertSubview:self.placeholderView belowSubview:previousPlaceholderView];
        [UIView animateWithDuration:kPKViewPlaceholderViewAnimationDuration delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.placeholderView.layer.opacity = 1.0;
                             self.placeholderView.layer.transform = CATransform3DIdentity;
                         } completion:^(BOOL finished) {
                         }];
    }
}

- (void)setPlaceholderToCVC
{
    PKCardNumber *cardNumber = [PKCardNumber cardNumberWithString:self.cardNumberField.text];
    PKCardType cardType = [cardNumber cardType];
    
    if (cardType == PKCardTypeAmex) {
        [self setPlaceholderViewImage:[UIImage imageNamed:@"cvc-amex"]];
    } else {
        [self setPlaceholderViewImage:[UIImage imageNamed:@"cvc"]];
    }
}

- (void)setPlaceholderToCardType
{
    PKCardNumber *cardNumber = [PKCardNumber cardNumberWithString:self.cardNumberField.text];
    PKCardType cardType = [cardNumber cardType];
    NSString *cardTypeName = @"placeholder";
    
    switch (cardType) {
        case PKCardTypeAmex:
            cardTypeName = @"amex";
            break;
        case PKCardTypeDinersClub:
            cardTypeName = @"diners";
            break;
        case PKCardTypeDiscover:
            cardTypeName = @"discover";
            break;
        case PKCardTypeJCB:
            cardTypeName = @"jcb";
            break;
        case PKCardTypeMasterCard:
            cardTypeName = @"mastercard";
            break;
        case PKCardTypeVisa:
            cardTypeName = @"visa";
            break;
        default:
            break;
    }
    
    [self setPlaceholderViewImage:[UIImage imageNamed:cardTypeName]];
}

#pragma mark - Delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    textField.textAlignment = NSTextAlignmentLeft;
    
    if ([textField isEqual:self.cardCVCField]) {
        [self setPlaceholderToCVC];
    } else {
        [self setPlaceholderToCardType];
    }
    
    if ([textField isEqual:self.cardNumberField] && !_isInitialState) {
        [self stateCardNumber];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if(textField != self.cardNumberField && textField.text.length > 1) {
        textField.textAlignment = NSTextAlignmentCenter;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if([self.delegate respondsToSelector:@selector(paymentViewShouldReturn)])
        return [self.delegate paymentViewShouldReturn];
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    if ([textField isEqual:self.cardNumberField]) {
        return [self cardNumberFieldShouldChangeCharactersInRange:range replacementString:replacementString];
    }
    
    if ([textField isEqual:self.cardExpiryField]) {
        return [self cardExpiryShouldChangeCharactersInRange:range replacementString:replacementString];
    }
    
    if ([textField isEqual:self.cardCVCField]) {
        return [self cardCVCShouldChangeCharactersInRange:range replacementString:replacementString];
    }
    
    if ([textField isEqual:self.cardPostalField]) {
        return [self cardPostalShouldChangeCharactersInRange:range replacementString:replacementString];
    }
    
    return YES;
}

- (void)pkTextFieldDidBackSpaceWhileTextIsEmpty:(PKTextField *)textField
{
    //    if (textField == self.cardPostalField) {
    //        [self.cardCVCField becomeFirstResponder];
    //    }
    //    if (textField == self.cardCVCField)
    //        [self.cardExpiryField becomeFirstResponder];
    //    else if (textField == self.cardExpiryField)
    //        [self stateCardNumber];
}

- (BOOL)cardNumberFieldShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [self.cardNumberField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PKTextField textByRemovingUselessSpacesFromString:resultString];
    PKCardNumber *cardNumber = [PKCardNumber cardNumberWithString:resultString];
    
    if (![cardNumber isPartiallyValid] && ![cardNumber isValidLength])
        return NO;
    
    return YES;
}

- (void)cardNumberFieldChanged
{
    NSString *number = [PKTextField textByRemovingUselessSpacesFromString:self.cardNumberField.text];
    BTUICardType *cardType = [BTUICardType cardTypeForNumber:number];
    
    if (cardType != nil) {
        UITextRange *r = self.cardNumberField.selectedTextRange;
        NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithAttributedString:[cardType formatNumber:number kerning:8]];
        self.cardNumberField.attributedText = text;
        self.cardNumberField.selectedTextRange = r;
    }
    
    [self setPlaceholderToCardType];
    
    PKCardNumber *cardNumber = [PKCardNumber cardNumberWithString:number];
    if ([cardNumber isValid]) {
        [self textFieldIsValid:self.cardNumberField];
        [self stateMeta];
        
    } else if ([cardNumber isValidLength] && ![cardNumber isValidLuhn]) {
        [self textFieldIsInvalid:self.cardNumberField withErrors:YES];
        
    } else if (![cardNumber isValidLength]) {
        [self textFieldIsInvalid:self.cardNumberField withErrors:NO];
    }
}

- (BOOL)cardExpiryShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [self.cardExpiryField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PKTextField textByRemovingUselessSpacesFromString:resultString];
    PKCardExpiry *cardExpiry = [PKCardExpiry cardExpiryWithString:resultString];
    
    if (![cardExpiry isPartiallyValid]) return NO;
    
    // Only support shorthand year
    if ([cardExpiry formattedString].length > 5) return NO;
    
    if (replacementString.length > 0) {
        self.cardExpiryField.text = [cardExpiry formattedStringWithTrail];
    } else {
        self.cardExpiryField.text = [cardExpiry formattedString];
    }
    
    if ([cardExpiry isValid]) {
        [self textFieldIsValid:self.cardExpiryField];
        [self stateCardCVC];
        
    } else if ([cardExpiry isValidLength] && ![cardExpiry isValidDate]) {
        [self textFieldIsInvalid:self.cardExpiryField withErrors:YES];
    } else if (![cardExpiry isValidLength]) {
        [self textFieldIsInvalid:self.cardExpiryField withErrors:NO];
    }
    
    return NO;
}

- (BOOL)cardCVCShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [self.cardCVCField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PKTextField textByRemovingUselessSpacesFromString:resultString];
    PKCardCVC *cardCVC = [PKCardCVC cardCVCWithString:resultString];
    PKCardType cardType = [[PKCardNumber cardNumberWithString:self.cardNumberField.text] cardType];
    
    // Restrict length
    if (![cardCVC isPartiallyValidWithType:cardType]) return NO;
    
    // Strip non-digits
    self.cardCVCField.text = [cardCVC string];
    
    if ([cardCVC isValidWithType:cardType]) {
        [self textFieldIsValid:self.cardCVCField];
        [self.cardPostalField becomeFirstResponder];
    } else {
        [self textFieldIsInvalid:self.cardCVCField withErrors:NO];
    }
    
    return NO;
}

- (BOOL)cardPostalShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [self.cardPostalField.text stringByReplacingCharactersInRange:range withString:replacementString];
    
    // Strip non-alphanumerics
    NSCharacterSet *set = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    NSArray *validComponents = [resultString componentsSeparatedByCharactersInSet:set];
    resultString = [validComponents componentsJoinedByString:@""];
    
    // Longest possible postal code is 9 according to the internet
    if(resultString.length < 10) {
        self.cardPostalField.text = resultString;
        [self textFieldIsValid:self.cardPostalField];
    } else {
        [self textFieldIsInvalid:self.cardPostalField withErrors:NO];
    }
    
    return NO;
}

#pragma mark - Validations

- (void)checkValid
{
    if ([self isValid]) {
        _isValidState = YES;
        
        if ([self.delegate respondsToSelector:@selector(paymentView:withCard:isValid:)]) {
            [self.delegate paymentView:self withCard:self.card isValid:YES];
        }
        
    } else if (![self isValid] && _isValidState) {
        _isValidState = NO;
        
        if ([self.delegate respondsToSelector:@selector(paymentView:withCard:isValid:)]) {
            [self.delegate paymentView:self withCard:self.card isValid:NO];
        }
    }
}

- (void)textFieldIsValid:(UITextField *)textField
{
    textField.textColor = DarkGreyColor;
    [self checkValid];
}

- (void)textFieldIsInvalid:(UITextField *)textField withErrors:(BOOL)errors
{
    if (errors) {
        textField.textColor = RedColor;
    } else {
        textField.textColor = DarkGreyColor;
    }
    
    [self checkValid];
}

#pragma mark -
#pragma mark UIResponder
- (UIResponder *)firstResponderField;
{
    NSArray *responders = @[self.cardNumberField, self.cardExpiryField, self.cardCVCField, self.cardPostalField];
    for (UIResponder *responder in responders) {
        if (responder.isFirstResponder) {
            return responder;
        }
    }
    
    return nil;
}

- (PKTextField *)firstInvalidField;
{
    if (![[PKCardNumber cardNumberWithString:self.cardNumberField.text] isValid])
        return self.cardNumberField;
    else if (![[PKCardExpiry cardExpiryWithString:self.cardExpiryField.text] isValid])
        return self.cardExpiryField;
    else if (![[PKCardCVC cardCVCWithString:self.cardCVCField.text] isValid])
        return self.cardCVCField;
    
    return nil;
}

- (PKTextField *)nextFirstResponder;
{
    if (self.firstInvalidField)
        return self.firstInvalidField;
    
    return self.cardPostalField;
}

- (BOOL)isFirstResponder;
{
    return self.firstResponderField.isFirstResponder;
}

- (BOOL)canBecomeFirstResponder;
{
    return self.nextFirstResponder.canBecomeFirstResponder;
}

- (BOOL)becomeFirstResponder;
{
    return [self.nextFirstResponder becomeFirstResponder];
}

- (BOOL)canResignFirstResponder;
{
    return self.firstResponderField.canResignFirstResponder;
}

- (BOOL)resignFirstResponder;
{
    return [self.firstResponderField resignFirstResponder];
}

@end
