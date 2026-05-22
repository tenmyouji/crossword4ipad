#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** A single touch point from the user. */
NS_SWIFT_NAME(StrokePoint)
@interface MLKStrokePoint : NSObject

/** Horizontal coordinate. Increases to the right. */
@property(nonatomic, readonly) float x;

/** Vertical coordinate. Increases downward. */
@property(nonatomic, readonly) float y;

/** Time when the point was recorded, in milliseconds. */
@property(nonatomic, readonly, nullable) NSNumber *t;

/** Unavailable. Use `init(x:y:t:)` instead. */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Creates a `StrokePoint` object using the coordinates provided as argument.
 *
 * Scales on both dimensions are arbitrary but be must be identical: a displacement of 1
 * horizontally or vertically must represent the same distance, as seen by the user.
 *
 * Spatial and temporal origins can be arbitrary as long as they are consistent for a given ink.
 *
 * @param x Horizontal coordinate. Increases to the right.
 * @param y Vertical coordinate. Increases going downward.
 * @param t Time when the point was recorded, in milliseconds.
 */
- (instancetype)initWithX:(float)x y:(float)y t:(long)t;

/**
 * Creates a `StrokePoint` object using the coordinates provided as
 * argument, without specifying a timestamp. This method should only be used
 * when it is not feasible to include the timestamp information, as the
 * recognition accuracy might degrade.
 *
 * Scales on both dimensions are arbitrary but be must be identical: a
 * displacement of 1 horizontally or vertically must represent the same
 * distance, as seen by the user.
 *
 * Spatial origin can be arbitrary as long as it is consistent for a given ink.
 *
 * @param x horizontal coordinate. Increases to the right.
 * @param y vertical coordinate. Increases going downward.
 */
- (instancetype)initWithX:(float)x y:(float)y;

@end

/**
 * Represents a sequence of touch points between a pen (resp. touch) down and pen (resp. touch) up
 * event.
 */
NS_SWIFT_NAME(Stroke)
@interface MLKStroke : NSObject

/** List of touch points as `StrokePoint`. */
@property(nonatomic, readonly) NSArray<MLKStrokePoint *> *points;

/** Unavailable. Use `init(points:)` instead. */
- (instancetype)init NS_UNAVAILABLE;

/** Initializes and returns a `Stroke` object using the sequence of touch points provided. */
- (instancetype)initWithPoints:(NSArray<MLKStrokePoint *> *)points NS_DESIGNATED_INITIALIZER;
@end

/**
 * Represents the user input as a collection of `Stroke` and serves as input for the handwriting
 * recognition task.
 */
NS_SWIFT_NAME(Ink)
@interface MLKInk : NSObject

/** List of strokes composing the ink. */
@property(nonatomic, readonly) NSArray<MLKStroke *> *strokes;

/** Unavailable, use `init(points:)` or `init(strokes:)` instead. */
- (instancetype)init NS_UNAVAILABLE;

/** Initializes and returns an `Ink` object using the sequence of strokes provided. */
- (instancetype)initWithStrokes:(NSArray<MLKStroke *> *)strokes NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
