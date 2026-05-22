#import <Foundation/Foundation.h>

@class MLKWritingArea;

NS_ASSUME_NONNULL_BEGIN

/**
 * Information about the context in which an ink has been drawn.
 *
 * Pass this object to a `DigitalInkRecognizer` alongside an ink to improve the recognition
 * quality.
 */
NS_SWIFT_NAME(DigitalInkRecognitionContext)
@interface MLKDigitalInkRecognitionContext : NSObject

/**
 * Characters immediately before the position where the recognized text should be inserted.
 *
 * This information is used by the recognizer's language model to improve recognition.
 *
 * Example: a text field contains "hello", with the cursor right after "o". The user handwrites
 * something that looks like "world". If the pre-context is set to "hello", the recognizer
 * will be able to output " world", with a leading space.
 *
 * If the text field contains "hello" with the cursor between "e" and the first "l", then the
 * pre-context must be set to "he".
 *
 * A good rule of thumb for pre-context length is: as many characters as possible, including spaces,
 * until around 20. The optimal number depends on the exact recognition model that is used. Getting
 * the best speed/accuracy tradeoff may require a bit of tuning.
 */
@property(nonatomic, nullable, readonly) NSString *preContext;

/**
 * Size of the writing area.
 *
 * This is used by some recognition models to disambiguate some cases. Example: lowercase vs.
 * uppercase ("o" vs. "O").
 *
 * See also `WritingArea`.
 */
@property(nonatomic, nullable, readonly) MLKWritingArea *writingArea;

/** Unavailable. Use `init(preContext:writingArea:)` instead. */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Creates a `DigitalInkRecognitionContext` object.
 *
 * @param preContext Characters immediately before the position where the recognized text should
 *     be inserted. See the description of the property with the same name for more details.
 * @param writingArea Properties of the region of the canvas where the ink has been drawn. See
 *     the description of the property with the same name for more details.
 */
- (instancetype)initWithPreContext:(nullable NSString *)preContext
                       writingArea:(nullable MLKWritingArea *)writingArea NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
