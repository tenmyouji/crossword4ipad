# crosswordapp

A cozy native SwiftUI iPad crossword app built for Apple Pencil handwriting.

## What Is Included

- Responsive crossword layout for landscape and portrait iPad use.
- Generated puzzle sizes: `5 x 5`, `10 x 10`, `15 x 15`, and `20 x 20`.
- New puzzle setup popup with size and difficulty choices.
- Apple Pencil writing directly inside each crossword square with PencilKit.
- ML Kit Digital Ink Recognition for turning handwriting into answer letters.
- Across/Down tabs, current clue display, and previous/next clue navigation.
- Gear menu for puzzle actions such as check, restart, new puzzle, and show answers.
- Completion popup for starting another configured puzzle.

## Open

Open `crosswordapp.xcworkspace` in Xcode, choose an iPad simulator or iPad device, and press Run.

If the workspace or ML Kit dependency is missing, install the pods first:

```sh
pod install
```

## Build From Command Line

```sh
xcodebuild -workspace crosswordapp.xcworkspace -scheme crosswordapp -sdk iphonesimulator -derivedDataPath /Users/leiva/crosswordpenapp/DerivedData CODE_SIGNING_ALLOWED=NO build
```

## Notes

- The app is configured as iPad-only with iOS 17.0 as the deployment target.
- CocoaPods provides `GoogleMLKit/DigitalInkRecognition`.
- Bundle identifier: `com.example.leivacrossword`.
