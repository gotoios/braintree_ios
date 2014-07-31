#import <Foundation/Foundation.h>

#define BTUILocalizedString(KEY) [BTUILocalizedString KEY]

@interface BTUILocalizedString : NSObject

+ (NSString *)CARD_NUMBER_PLACEHOLDER;
+ (NSString *)CVV_FIELD_PLACEHOLDER;
+ (NSString *)EXPIRY_PLACEHOLDER_FOUR_DIGIT_YEAR;
+ (NSString *)EXPIRY_PLACEHOLDER_TWO_DIGIT_YEAR;
+ (NSString *)PAYPAL_CARD_BRAND;
+ (NSString *)POSTAL_CODE_PLACEHOLDER;
+ (NSString *)TOP_LEVEL_ERROR_ALERT_VIEW_OK_BUTTON_TEXT;


#pragma mark Card Brands

+ (NSString *)CARD_TYPE_AMERICAN_EXPRESS;
+ (NSString *)CARD_TYPE_DISCOVER;
+ (NSString *)CARD_TYPE_DINERS_CLUB;
+ (NSString *)CARD_TYPE_MASTER_CARD;
+ (NSString *)CARD_TYPE_VISA;
+ (NSString *)CARD_TYPE_JCB;
+ (NSString *)CARD_TYPE_MAESTRO;
+ (NSString *)CARD_TYPE_UNION_PAY;
+ (NSString *)CARD_TYPE_SWITCH;
+ (NSString *)CARD_TYPE_SOLO;
+ (NSString *)CARD_TYPE_LASER;
;
@end
