#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Individual recognition candidate.
 *
 * A recognizer usually provides several recognition alternatives. This object represents one such
 * alternative.
 *
 * See `DigitalInkRecognitionResult` for more details.
 */
NS_SWIFT_NAME(DigitalInkRecognitionCandidate)
@interface MLKDigitalInkRecognitionCandidate : NSObject

/** The textual representation of this candidate. */
@property(nonatomic, readonly) NSString *text;

/**
 * Score of the candidate. Values may be positive or negative. More likely candidates get lower
 * values. This value is populated only for models that support it.
 *
 * Scores are meant to be used to reject candidates whose score is above a threshold. A particular
 * threshold value for a given application will stay valid after a model update.
 */
@property(nonatomic, readonly, nullable) NSNumber *score;

/** Unavailable. This object is only created internally by the API. */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
