# Claude Project Context

## Project Overview

This is `crosswordapp`, a native SwiftUI iPad crossword prototype focused on Apple Pencil input. The main implementation currently lives in `crosswordapp/ContentView.swift`; most UI, board logic, puzzle generation, and handwriting input are in that single file.

The current app is more advanced than `README.md` suggests. Treat the README as stale until it is updated.

## Current App Behavior

- The app shows a generated crossword puzzle with supported sizes `5x5`, `10x10`, and `15x15`.
- Users write letters directly into individual crossword cells with Apple Pencil.
- Each playable cell owns its own PencilKit canvas. There should not be one board-wide handwriting canvas.
- The active clue/word is highlighted, but the individual selected square should not get a special visual highlight.
- Tapping a cell updates the active clue; tapping the same cell can toggle direction when both across/down are available.
- Tapping a clue jumps to the first empty square in that answer, falling back to the first square.
- Recognized letters are stored in `recognizedLetters`, which is the single source of truth for typed answers.
- Writing over a filled cell replaces the old letter when recognition returns a new A-Z letter.
- Scribbling/crossing out over a filled cell clears that cell only when the stroke geometry looks like an intentional delete gesture.
- The check puzzle button reports incomplete/correct/incorrect without marking cells red.
- When the puzzle is completed correctly, a completion sheet offers another generated puzzle and size selection.
- The header includes a timer based on `puzzleStartedAt`.

## Handwriting Recognition

- Current recognizer: Google ML Kit Digital Ink Recognition through CocoaPods.
- Do not reintroduce Apple Scribble, `UIIndirectScribbleInteraction`, or Apple Vision OCR for handwriting recognition unless explicitly requested.
- `BoardInputView` bridges SwiftUI to UIKit/PencilKit.
- `CellCanvasView` is a `PKCanvasView` scoped to one crossword cell.
- `CellInputState` tracks each cell canvas, drawing, pending recognition task, recognition generation, debug text, and whether the current writing attempt started on a filled cell.
- Recognition waits for a quiet delay, currently about `1.6` seconds, before sending the cell drawing to ML Kit.
- Starting to write in another cell triggers faster resolution for the previously active cell.
- If ML Kit returns a letter, commit it through `onRecognizedLetter(letter, coordinate)`.
- If ML Kit returns no letter:
  - For blank cells, keep current failure behavior.
  - For filled cells, only clear if `isDeleteGesture` identifies a cross-out/scribble delete gesture.
  - Otherwise keep the ink visible and leave the typed letter unchanged.
- ML Kit model download is managed with `ModelManager.download(_:conditions:)` and model download notifications. That API returns `NSProgress`; do not add a trailing completion closure.

## Puzzle And UI Architecture

- `ContentView` owns app state: selected cell, direction, recognized letters, check result, current puzzle, next puzzle size, completion sheet, timer start, and board input reset ID.
- `CrosswordBoard` renders the grid and overlays `BoardInputLayer`.
- `CrosswordCell` renders black/playable cells, clue numbers, typed letters, and active-word highlighting.
- `CluePanel`, `CurrentClueCard`, `ClueList`, `PuzzleActionsView`, and `CompletionView` make up the side panel and puzzle actions.
- `CrosswordPuzzle` stores letters, black cells, numbering, across/down clues, clue lookup, answer-cell lookup, checking, and auto-advance.
- `PuzzleGenerator` creates puzzle rows and clue banks locally. There is no remote puzzle API.
- The visual style is paper-like Material-inspired UI with serif fonts throughout.

## Dependencies And Build Notes

- Use `crosswordapp.xcworkspace` in Xcode for normal builds because ML Kit is installed through CocoaPods.
- `Podfile` targets iOS `17.0` and includes:
  - `GoogleMLKit/DigitalInkRecognition`, version `8.0.0`
- The `Podfile` has a `post_install` block that forces pod deployment targets to `17.0`.
- If pods change, run `pod install` from the repo root.
- Command-line builds of `crosswordapp.xcodeproj` can compile Swift but may fail at link time because pod frameworks such as `FBLPromises` are not built from the raw project.
- Preferred build command when the workspace is valid:

```sh
xcodebuild -workspace crosswordapp.xcworkspace -scheme crosswordapp -sdk iphonesimulator -derivedDataPath /Users/leiva/crosswordpenapp/DerivedData CODE_SIGNING_ALLOWED=NO build
```

## Important Constraints

- Preserve per-cell input. Do not collapse input back into one shared board-level canvas.
- Keep `recognizedLetters` as the final answer state.
- Keep temporary handwriting ink separate from typed letters.
- Selection is still needed internally for clue direction, clue tapping, next/previous clue, and auto-advance, even though the selected square has no special styling.
- Avoid clearing ink on ordinary selection changes or SwiftUI updates.
- Reset/new puzzle/show answers should clear or sync temporary canvases through `boardInputResetID` or recognized-letter changes.
- The app is iPad-focused and should avoid showing the software keyboard.
- Keep UI text concise and avoid explanatory in-app instructional copy unless requested.

## Current Git/Workspace Notes

- Recent work has touched `crosswordapp/ContentView.swift`.
- CocoaPods files may be present locally: `Podfile`, `Podfile.lock`, `Pods/`, and `crosswordapp.xcworkspace/`.
- `crosswordapp.xcodeproj/project.pbxproj` has been adjusted previously for Xcode sandbox/build-script behavior.
- Be careful not to revert local user changes.
