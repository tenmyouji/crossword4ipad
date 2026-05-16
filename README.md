# crosswordapp

A minimal native SwiftUI iPad crossword prototype for Apple Pencil.

## Open

Open `crosswordapp.xcodeproj` in Xcode, choose an iPad simulator or iPad device, and press Run.

## What is included

- A 10x10 crossword board inspired by newspaper-style mini crosswords.
- Apple Pencil input using PencilKit.
- Tap a white square, then write directly in that square with Apple Pencil.
- Across/Down clue switching and current-clue highlighting.
- Erase controls for one square or the whole puzzle.

## Notes

- The app is configured as iPad-only via `TARGETED_DEVICE_FAMILY = 2`.
- The current version is paper-like: it stores handwritten marks, not recognized typed letters yet.
- Bundle identifier: `com.example.crosswordapp`.
