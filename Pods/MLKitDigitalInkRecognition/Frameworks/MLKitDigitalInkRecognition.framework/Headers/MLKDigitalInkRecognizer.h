#import <Foundation/Foundation.h>

@class MLKDigitalInkRecognitionContext;
@class MLKDigitalInkRecognitionResult;
@class MLKDigitalInkRecognizerOptions;
@class MLKInk;

NS_ASSUME_NONNULL_BEGIN

/**
 * A block that handles a digital ink recognition result.
 *
 * @param result A `DigitalInkRecognitionResult` containing a list of recognition candidates or
 *     `nil` if there's an error.
 * @param error The error or `nil`.
 */
typedef void (^MLKDigitalInkRecognizerCallback)(MLKDigitalInkRecognitionResult *_Nullable result,
                                                NSError *_Nullable error)
    NS_SWIFT_NAME(DigitalInkRecognizerCallback);

/**
 * Object to perform handwriting recognition on digital ink.
 *
 * Digital ink is the vector representation of what a user has written. It is composed of a sequence
 * of strokes, each being a sequence of touch points (coordinates and timestamp). See `Ink` for
 * details.
 */
NS_SWIFT_NAME(DigitalInkRecognizer)
@interface MLKDigitalInkRecognizer : NSObject

/** Unavailable. Use `digitalInkRecognizer(options:)` instead. */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Creates a `DigitalInkRecognizer` object using the specified options.
 *
 * See `DigitalInkRecognizerOptions` for details.
 */
+ (MLKDigitalInkRecognizer *)digitalInkRecognizerWithOptions:
    (MLKDigitalInkRecognizerOptions *)options NS_SWIFT_NAME(digitalInkRecognizer(options:));

/**
 * Performs a recognition of the input ink.
 *
 * Note that using `recognize(ink:context:completion:)` instead of this method may lead to better
 * accuracy in some cases.
 *
 * @param ink Input to be recognized.
 * @param completion A callback for returning recognition candidates. See
 * `DigitalInkRecognizerCallback` for details.
 */
- (void)recognizeInk:(MLKInk *)ink
          completion:(MLKDigitalInkRecognizerCallback)completion
    NS_SWIFT_NAME(recognize(ink:completion:));

/**
 * Performs a recognition of the input ink using a recognition context.
 *
 * A recognition context contains information about the size of the writing area, and the characters
 * that have already been entered in the text area. This helps disambiguate certain cases.
 *
 * Example usage: a previous recognition has yielded the string "hello", that has been inserted in a
 * text field. The user then handwrites "world". Send the present method the ink showing "world",
 * and "hello" as a string in `context`. The recognizer will most likely return the string " world"
 * with a leading space separating the two words.
 *
 * See `DigitalInkRecognitionContext` for details.
 *
 * @param ink Input to be recognized.
 * @param context See `DigitalInkRecognitionContext` for details.
 * @param completion A callback for returning recognition candidates. See
 *     `DigitalInkRecognizerCallback` for details. If nothing can be recognized, an empty list of
 *     candidates will be passed to the callback.
 */
- (void)recognizeInk:(MLKInk *)ink
             context:(MLKDigitalInkRecognitionContext *)context
          completion:(MLKDigitalInkRecognizerCallback)completion
    NS_SWIFT_NAME(recognize(ink:context:completion:));

@end

NS_ASSUME_NONNULL_END
