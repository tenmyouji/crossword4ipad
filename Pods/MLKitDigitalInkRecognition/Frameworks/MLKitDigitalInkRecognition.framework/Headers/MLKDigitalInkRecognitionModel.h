#import <Foundation/Foundation.h>

#import "MLKDigitalInkRecognitionModelIdentifier.h"

#import <MLKitCommon/MLKRemoteModel.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents a downloadable recognition model.
 *
 * Recognition models are downloaded on the device when the `download` method is called. The
 * downloaded model is unzipped when `DigitalInkRecognizer` loads it at inference time for the
 * first time, which makes the first recognition a bit slower than subsequent ones.
 *
 * This object contains properties that are constant throughout the lifetime of a recognition model.
 *
 * See `DigitalInkRecognitionContext` for the properties that depend on the ink being recognized.
 */
NS_SWIFT_NAME(DigitalInkRecognitionModel)
@interface MLKDigitalInkRecognitionModel : MLKRemoteModel

/** Identifier of this recognition model. */
@property(nonatomic, readonly) MLKDigitalInkRecognitionModelIdentifier *modelIdentifier;

/** Not available. Use `init(modelIdentifier:)` instead. */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Creates a new instance from the specified model identifier.
 *
 * @param modelIdentifier A valid `DigitalInkRecognitionModelIdentifier`.
 * @return A new `DigitalInkRecognitionModel` instance.
 */
- (instancetype)initWithModelIdentifier:(MLKDigitalInkRecognitionModelIdentifier *)modelIdentifier
    NS_SWIFT_NAME(init(modelIdentifier:));

@end

NS_ASSUME_NONNULL_END
