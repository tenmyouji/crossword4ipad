#import <Foundation/Foundation.h>

@class MLKDigitalInkRecognitionModel;

NS_ASSUME_NONNULL_BEGIN

/** Options defining the behavior of a `DigitalInkRecognizer`. */
NS_SWIFT_NAME(DigitalInkRecognizerOptions)
@interface MLKDigitalInkRecognizerOptions : NSObject

/** Model to be used for recognition. */
@property(nonatomic, readonly) MLKDigitalInkRecognitionModel *model;

/**
 * Maximum number of recognition results.
 *
 * The recognizer will return at most this number of results. Default value is 10. Minimum value
 * is 1.
 */
@property(nonatomic) int maxResultCount;

/** Unavailable, use `initWithModel` instead. */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Creates a `DigitalInkRecognizerOptions`
 *
 * @param model Type of recognizer. This is for example how the recognition language is specified.
 *     See `DigitalInkRecognitionModel` for details.
 */
- (instancetype)initWithModel:(MLKDigitalInkRecognitionModel *)model NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
