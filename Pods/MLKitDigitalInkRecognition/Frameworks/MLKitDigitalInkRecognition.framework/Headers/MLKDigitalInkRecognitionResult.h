#import <Foundation/Foundation.h>

@class MLKDigitalInkRecognitionCandidate;

NS_ASSUME_NONNULL_BEGIN

/**
 * Object representing the output of an ink recognition.
 *
 * A recognizer usually provides several recognition alternatives, because the user intent is not
 * always clear. For example, if the user writes a vertical line and then a circle, the recognition
 * alternatives could include "10", "IO", and "lo".
 *
 * Alternatives are named "candidates". This object represents a set of candidates as a list of
 * `DigitalInkRecognitionCandidate`.
 *
 * Use `DigitalInkRecognizer` to perform the recognition itself. If nothing could be recognized,
 * the property `candidates` will be an empty array.
 */
NS_SWIFT_NAME(DigitalInkRecognitionResult)
@interface MLKDigitalInkRecognitionResult : NSObject

/**
 * List of recognition alternatives.
 *
 * Candidates are ordered from most likely to least likely. When scores are provided, they
 * are in increasing order.
 *
 * The number of candidates depends on the options used when initializing the recognizer. See
 * `DigitalInkRecognitionModel` and `DigitalInkRecognizerOptions` for details.
 */
@property(nonatomic, readonly) NSArray<MLKDigitalInkRecognitionCandidate *> *candidates;

/** This object is only meant to be instantiated by a `DigitalInkRecognizer` object. */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
