#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Properties of the writing area.
 *
 * The writing area is the area on the screen where the user can draw an ink.
 */
NS_SWIFT_NAME(WritingArea)
@interface MLKWritingArea : NSObject

/** Writing area width, in the same units as used in `StrokePoint`.*/
@property(nonatomic, readonly) float width;

/** Writing area height, in the same units as used in `StrokePoint`.*/
@property(nonatomic, readonly) float height;

/** Unavailable. Use `init(width:height:)` instead. */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Initializes and returns a `WritingArea` with specified dimensions.
 *
 * The same unit is expected for both dimensions, and must match the unit used in `Ink` and related
 * objects.
 *
 * @param width Width of the writing area.
 * @param height Height of the writing area.
 */
- (instancetype)initWithWidth:(float)width height:(float)height NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
