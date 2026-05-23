import PencilKit
import SwiftUI
import UIKit

#if canImport(MLKitDigitalInkRecognition)
import MLKitCommon
import MLKitDigitalInkRecognition
#endif

struct ContentView: View {
    @State private var selectedCell = CrosswordCoordinate(row: 0, column: 0)
    @State private var direction: CrosswordDirection = .across
    @State private var recognizedLetters: [CrosswordCoordinate: String] = [:]
    @State private var checkResult: PuzzleCheckResult?
    @State private var puzzle = CrosswordPuzzle.generated(size: 5)
    @State private var puzzleDifficulty: PuzzleDifficulty = .easy
    @State private var nextPuzzleSize = 5
    @State private var nextPuzzleDifficulty: PuzzleDifficulty = .easy
    @State private var isShowingCompletionSheet = false
    @State private var isShowingPuzzleConfiguration = false
    @State private var puzzleStartedAt = Date()
    @State private var boardInputResetID = 0

    private let puzzleSizes = [5, 10, 15, 20]

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            let sidebarWidth = min(380, max(340, proxy.size.width * 0.34))
            let landscapeBoardSize = min(570, max(320, proxy.size.width - sidebarWidth - 96), max(320, proxy.size.height - 96))
            let portraitBoardSize = min(max(300, proxy.size.width - 96), max(300, proxy.size.height * 0.52), 560)

            ZStack {
                PaperBackground()

                VStack {
                    if isLandscape {
                        HStack(alignment: .center, spacing: 24) {
                            PuzzleSidebar(
                                puzzle: puzzle,
                                selectedCell: selectedCell,
                                recognizedLetters: recognizedLetters,
                                isLandscape: isLandscape,
                                direction: $direction,
                                checkResult: checkResult,
                                startedAt: puzzleStartedAt,
                                switchDirection: toggleDirectionIfPossible,
                                selectClue: selectClue,
                                checkPuzzle: checkPuzzle,
                                restartPuzzle: restartPuzzle,
                                startNewPuzzle: startNewPuzzle,
                                showAnswers: showAnswers
                            )
                            .frame(width: sidebarWidth)

                            boardWithCompletionOverlay
                                .frame(width: landscapeBoardSize, height: landscapeBoardSize)
                        }
                        .frame(maxWidth: 1040, maxHeight: .infinity, alignment: .center)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 24) {
                                PuzzleSidebar(
                                    puzzle: puzzle,
                                    selectedCell: selectedCell,
                                    recognizedLetters: recognizedLetters,
                                    isLandscape: isLandscape,
                                    direction: $direction,
                                    checkResult: checkResult,
                                    startedAt: puzzleStartedAt,
                                    switchDirection: toggleDirectionIfPossible,
                                    selectClue: selectClue,
                                    checkPuzzle: checkPuzzle,
                                    restartPuzzle: restartPuzzle,
                                    startNewPuzzle: startNewPuzzle,
                                    showAnswers: showAnswers
                                )
                                .frame(maxWidth: min(proxy.size.width - 48, 696))

                                boardWithCompletionOverlay
                                    .frame(width: portraitBoardSize, height: portraitBoardSize)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, isLandscape ? 48 : 24)
                .padding(.vertical, isLandscape ? 48 : 32)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .sheet(isPresented: $isShowingPuzzleConfiguration) {
            PuzzleConfigurationView(
                selectedSize: $nextPuzzleSize,
                selectedDifficulty: $nextPuzzleDifficulty,
                puzzleSizes: puzzleSizes,
                startPuzzle: applyPuzzleConfiguration
            )
        }
    }

    private var boardWithCompletionOverlay: some View {
        ZStack(alignment: .bottom) {
            boardView

            if isShowingCompletionSheet {
                CompletionBanner(
                    startNewPuzzle: startNewPuzzle,
                    dismiss: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            isShowingCompletionSheet = false
                        }
                    }
                )
                .padding(14)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: isShowingCompletionSheet)
    }

    private var boardView: some View {
        CrosswordBoard(
            puzzle: puzzle,
            selectedCell: $selectedCell,
            direction: direction,
            recognizedLetters: $recognizedLetters,
            resetID: boardInputResetID,
            onSelectCell: selectCell,
            onRecognizedLetter: storeRecognizedLetter
        )
    }

    private func clearSelectedCell() {
        recognizedLetters.removeValue(forKey: selectedCell)
        checkResult = nil
    }

    private func clearPuzzle() {
        recognizedLetters.removeAll()
        checkResult = nil
        boardInputResetID += 1
    }

    private func storeRecognizedLetter(_ letter: String?, at coordinate: CrosswordCoordinate) {
        guard let letter else {
            recognizedLetters.removeValue(forKey: coordinate)
            checkResult = nil
            return
        }

        let currentCell = coordinate
        recognizedLetters[currentCell] = letter
        checkResult = nil

        if puzzle.clue(containing: currentCell, direction: direction) == nil,
           let alternateDirection = alternateDirection(containing: currentCell) {
            direction = alternateDirection
        }

        selectedCell = currentCell
        advanceSelection(after: currentCell)
        showCompletionIfNeeded()
    }

    private func checkPuzzle() {
        let result = puzzle.check(answers: recognizedLetters)
        checkResult = result

        if result == .correct {
            isShowingCompletionSheet = true
        }
    }

    private func moveToPreviousClue() {
        moveClue(offset: -1)
    }

    private func moveToNextClue() {
        moveClue(offset: 1)
    }

    private func moveClue(offset: Int) {
        let currentClues = clues(for: direction)
        let alternateDirection: CrosswordDirection = direction == .across ? .down : .across
        let alternateClues = clues(for: alternateDirection)
        guard !currentClues.isEmpty else {
            moveToClue(alternateClues.first, direction: alternateDirection)
            return
        }

        let currentIndex = currentClues.firstIndex { $0.cells.contains(selectedCell) } ?? 0
        let nextIndex = currentIndex + offset

        if currentClues.indices.contains(nextIndex) {
            moveToClue(currentClues[nextIndex], direction: direction)
            return
        }

        if offset > 0 {
            moveToClue(alternateClues.first ?? currentClues.first, direction: alternateClues.isEmpty ? direction : alternateDirection)
        } else {
            moveToClue(alternateClues.last ?? currentClues.last, direction: alternateClues.isEmpty ? direction : alternateDirection)
        }
    }

    private func moveToClue(_ clue: CrosswordClue?, direction selectedDirection: CrosswordDirection) {
        guard let clue, let firstCell = clue.cells.first else { return }
        direction = selectedDirection
        selectedCell = firstCell
    }

    private func clues(for direction: CrosswordDirection) -> [CrosswordClue] {
        direction == .across ? puzzle.acrossClues : puzzle.downClues
    }

    private func selectClue(_ clue: CrosswordClue, direction selectedDirection: CrosswordDirection) {
        direction = selectedDirection
        selectedCell = clue.cells.first { coordinate in
            recognizedLetters[coordinate]?.isEmpty ?? true
        } ?? clue.cells.first ?? selectedCell
    }

    private func selectCell(_ coordinate: CrosswordCoordinate) {
        guard puzzle.isPlayable(coordinate) else { return }

        if coordinate == selectedCell {
            toggleDirectionIfPossible()
            return
        }

        selectedCell = coordinate

        if puzzle.clue(containing: coordinate, direction: direction) == nil,
           let alternateDirection = alternateDirection(containing: coordinate) {
            direction = alternateDirection
        }
    }

    private func toggleDirectionIfPossible() {
        let alternateDirection: CrosswordDirection = direction == .across ? .down : .across

        if puzzle.clue(containing: selectedCell, direction: alternateDirection) != nil {
            direction = alternateDirection
        }
    }

    private func alternateDirection(containing coordinate: CrosswordCoordinate) -> CrosswordDirection? {
        let alternateDirection: CrosswordDirection = direction == .across ? .down : .across
        return puzzle.clue(containing: coordinate, direction: alternateDirection) == nil ? nil : alternateDirection
    }

    private func advanceSelection(after coordinate: CrosswordCoordinate) {
        selectedCell = puzzle.nextCoordinate(after: coordinate, direction: direction) ?? selectedCell
    }

    private func showCompletionIfNeeded() {
        guard puzzle.check(answers: recognizedLetters) == .correct else { return }
        checkResult = .correct
        isShowingCompletionSheet = true
    }

    private func startNewPuzzle() {
        nextPuzzleSize = puzzle.size
        nextPuzzleDifficulty = puzzleDifficulty
        isShowingCompletionSheet = false
        isShowingPuzzleConfiguration = true
    }

    private func restartPuzzle() {
        recognizedLetters.removeAll()
        checkResult = nil
        isShowingCompletionSheet = false
        selectedCell = puzzle.playableCoordinates.first ?? selectedCell
        direction = .across
        puzzleStartedAt = Date()
        boardInputResetID += 1
    }

    private func showAnswers() {
        recognizedLetters = puzzle.solutionLetters
        checkResult = .correct
        boardInputResetID += 1
    }

    private func showAnotherPuzzle() {
        resetPuzzle(size: nextPuzzleSize, difficulty: nextPuzzleDifficulty)
        isShowingCompletionSheet = false
    }

    private func applyPuzzleConfiguration() {
        resetPuzzle(size: nextPuzzleSize, difficulty: nextPuzzleDifficulty)
        isShowingPuzzleConfiguration = false
    }

    private func resetPuzzle(size: Int, difficulty: PuzzleDifficulty) {
        puzzle = CrosswordPuzzle.generated(
            size: size,
            seed: difficulty.seedOffset + Int(Date().timeIntervalSince1970),
            difficulty: difficulty
        )
        puzzleDifficulty = difficulty
        selectedCell = CrosswordCoordinate(row: 0, column: 0)
        direction = .across
        recognizedLetters.removeAll()
        checkResult = nil
        puzzleStartedAt = Date()
        boardInputResetID += 1
    }
}

private struct PuzzleSidebar: View {
    let puzzle: CrosswordPuzzle
    let selectedCell: CrosswordCoordinate
    let recognizedLetters: [CrosswordCoordinate: String]
    let isLandscape: Bool
    @Binding var direction: CrosswordDirection
    let checkResult: PuzzleCheckResult?
    let startedAt: Date
    let switchDirection: () -> Void
    let selectClue: (CrosswordClue, CrosswordDirection) -> Void
    let checkPuzzle: () -> Void
    let restartPuzzle: () -> Void
    let startNewPuzzle: () -> Void
    let showAnswers: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            CluePanel(
                puzzle: puzzle,
                selectedCell: selectedCell,
                recognizedLetters: recognizedLetters,
                isLandscape: isLandscape,
                direction: $direction,
                checkResult: checkResult,
                startedAt: startedAt,
                switchDirection: switchDirection,
                selectClue: selectClue,
                checkPuzzle: checkPuzzle,
                restartPuzzle: restartPuzzle,
                startNewPuzzle: startNewPuzzle,
                showAnswers: showAnswers
            )
        }
    }
}

private struct TimerBadge: View {
    let startedAt: Date

    var body: some View {
        TimelineView(.periodic(from: startedAt, by: 1)) { timeline in
            HStack(spacing: 7) {
                Text(Self.formattedElapsedTime(from: startedAt, to: timeline.date))
                    .monospacedDigit()
                    .foregroundStyle(Color.ink)

                Image(systemName: "pause.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.warmIcon)
            }
            .font(.system(size: 15, weight: .medium, design: .serif))
            .padding(.horizontal, 14)
            .frame(height: 41)
            .background(Color.controlSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private static func formattedElapsedTime(from startDate: Date, to currentDate: Date) -> String {
        let seconds = max(0, Int(currentDate.timeIntervalSince(startDate)))
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }
}

private struct CrosswordBoard: View {
    let puzzle: CrosswordPuzzle
    @Binding var selectedCell: CrosswordCoordinate
    let direction: CrosswordDirection
    @Binding var recognizedLetters: [CrosswordCoordinate: String]
    let resetID: Int
    let onSelectCell: (CrosswordCoordinate) -> Void
    let onRecognizedLetter: (String?, CrosswordCoordinate) -> Void

    var body: some View {
        GeometryReader { proxy in
            let boardSize = min(proxy.size.width, proxy.size.height)
            let cellSize = boardSize / CGFloat(puzzle.size)
            let selectedAnswer = puzzle.answerCells(containing: selectedCell, direction: direction)

            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color.surface)
                    .overlay {
                        Rectangle()
                            .stroke(Color.boardEdge, lineWidth: 2)
                    }

                ForEach(0..<puzzle.size, id: \.self) { row in
                    ForEach(0..<puzzle.size, id: \.self) { column in
                        let coordinate = CrosswordCoordinate(row: row, column: column)

                        CrosswordCell(
                            puzzle: puzzle,
                            coordinate: coordinate,
                            isHighlighted: selectedAnswer.contains(coordinate),
                            recognizedLetter: recognizedLetters[coordinate]
                        )
                        .frame(width: cellSize, height: cellSize)
                        .position(
                            x: CGFloat(column) * cellSize + cellSize / 2,
                            y: CGFloat(row) * cellSize + cellSize / 2
                        )
                    }
                }

                BoardInputLayer(
                    puzzle: puzzle,
                    selectedCell: $selectedCell,
                    recognizedLetters: recognizedLetters,
                    resetID: resetID,
                    onSelectCell: onSelectCell,
                    onRecognizedLetter: onRecognizedLetter
                )
                .frame(width: boardSize, height: boardSize)
            }
            .frame(width: boardSize, height: boardSize)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }

}

private struct CrosswordCell: View {
    let puzzle: CrosswordPuzzle
    let coordinate: CrosswordCoordinate
    let isHighlighted: Bool
    let recognizedLetter: String?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(fillStyle)

            if puzzle.isPlayable(coordinate) {
                if let recognizedLetter {
                    Text(recognizedLetter)
                        .font(.system(size: 42, weight: .medium, design: .serif))
                        .minimumScaleFactor(0.45)
                        .foregroundStyle(Color.ink)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 8)
                }

                if let number = puzzle.number(for: coordinate) {
                    Text("\(number)")
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .foregroundStyle(Color.clueNumber)
                        .padding(4)
                }
            }
        }
        .overlay(alignment: .center) {
            Rectangle()
                .stroke(Color.gridLine, lineWidth: 0.9)
        }
    }

    private var fillStyle: Color {
        if !puzzle.isPlayable(coordinate) {
            return .block
        }

        if isHighlighted {
            return .selectedAnswerSurface
        }

        return .surface
    }

}

private struct BoardInputLayer: UIViewRepresentable {
    let puzzle: CrosswordPuzzle
    @Binding var selectedCell: CrosswordCoordinate
    let recognizedLetters: [CrosswordCoordinate: String]
    let resetID: Int
    let onSelectCell: (CrosswordCoordinate) -> Void
    let onRecognizedLetter: (String?, CrosswordCoordinate) -> Void

    func makeUIView(context: Context) -> BoardInputView {
        BoardInputView(
            puzzle: puzzle,
            selectedCell: selectedCell,
            recognizedLetters: recognizedLetters,
            resetID: resetID,
            onSelect: onSelectCell,
            onRecognizedLetter: onRecognizedLetter
        )
    }

    func updateUIView(_ view: BoardInputView, context: Context) {
        if view.hasDifferentLayout(from: puzzle) {
            view.puzzle = puzzle
        }
        view.selectedCell = selectedCell
        view.recognizedLetters = recognizedLetters
        view.resetID = resetID
        view.onSelect = onSelectCell
        view.onRecognizedLetter = onRecognizedLetter
        view.setNeedsLayout()
    }
}

private final class BoardInputView: UIView, UIGestureRecognizerDelegate, PKCanvasViewDelegate {
    var puzzle: CrosswordPuzzle {
        didSet {
            reconcileCellStates()
            setNeedsLayout()
        }
    }

    var selectedCell: CrosswordCoordinate {
        didSet {
            setNeedsLayout()
        }
    }

    var recognizedLetters: [CrosswordCoordinate: String] {
        didSet {
            guard recognizedLetters != oldValue else { return }
            syncCellStates(changedFrom: oldValue)
        }
    }

    var resetID: Int {
        didSet {
            guard resetID != oldValue else { return }
            clearAllInk()
        }
    }

    var onSelect: (CrosswordCoordinate) -> Void
    var onRecognizedLetter: (String?, CrosswordCoordinate) -> Void

    private var cellStates: [CrosswordCoordinate: CellInputState] = [:]
    private var activeInkCoordinate: CrosswordCoordinate?

    init(
        puzzle: CrosswordPuzzle,
        selectedCell: CrosswordCoordinate,
        recognizedLetters: [CrosswordCoordinate: String],
        resetID: Int,
        onSelect: @escaping (CrosswordCoordinate) -> Void,
        onRecognizedLetter: @escaping (String?, CrosswordCoordinate) -> Void
    ) {
        self.puzzle = puzzle
        self.selectedCell = selectedCell
        self.recognizedLetters = recognizedLetters
        self.resetID = resetID
        self.onSelect = onSelect
        self.onRecognizedLetter = onRecognizedLetter
        super.init(frame: .zero)

        backgroundColor = .clear
        isMultipleTouchEnabled = true

        reconcileCellStates()

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapRecognizer.cancelsTouchesInView = false
        tapRecognizer.delegate = self
        addGestureRecognizer(tapRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let cellSize = min(bounds.width, bounds.height) / CGFloat(puzzle.size)
        for (coordinate, state) in cellStates {
            let frame = frame(for: coordinate, cellSize: cellSize)
            state.canvas.frame = frame
        }
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else { return }

        let location = recognizer.location(in: self)
        let cellSize = min(bounds.width, bounds.height) / CGFloat(puzzle.size)
        let coordinate = CrosswordCoordinate(
            row: Int(location.y / cellSize),
            column: Int(location.x / cellSize)
        )

        guard puzzle.isPlayable(coordinate) else { return }
        onSelect(coordinate)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.type != .pencil
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    private func frame(for coordinate: CrosswordCoordinate, cellSize: CGFloat) -> CGRect {
        CGRect(
            x: CGFloat(coordinate.column) * cellSize + 3,
            y: CGFloat(coordinate.row) * cellSize + 3,
            width: max(0, cellSize - 6),
            height: max(0, cellSize - 6)
        )
    }

    private func reconcileCellStates() {
        let playableCoordinates = Set(puzzle.playableCoordinates)
        let staleCoordinates = cellStates.keys.filter { !playableCoordinates.contains($0) }

        for coordinate in staleCoordinates {
            cellStates[coordinate]?.clearInk()
            cellStates[coordinate]?.canvas.removeFromSuperview()
            cellStates.removeValue(forKey: coordinate)
        }

        for coordinate in playableCoordinates where cellStates[coordinate] == nil {
            let canvas = CellCanvasView(coordinate: coordinate)
            configure(canvas)
            let state = CellInputState(coordinate: coordinate, canvas: canvas)
            cellStates[coordinate] = state
            addSubview(canvas)
        }
    }

    func hasDifferentLayout(from puzzle: CrosswordPuzzle) -> Bool {
        self.puzzle.layoutSignature != puzzle.layoutSignature
    }

    func clearAllInk() {
        for (_, state) in cellStates {
            state.clearInk()
        }
    }

    private func configure(_ canvas: CellCanvasView) {
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.clipsToBounds = true
        canvas.isUserInteractionEnabled = true
        canvas.delegate = self
        canvas.overrideUserInterfaceStyle = .light
        canvas.drawingPolicy = .pencilOnly
        canvas.tool = PKInkingTool(.pen, color: Self.writingInk, width: Self.strokeWidth)
        canvas.minimumZoomScale = 1
        canvas.maximumZoomScale = 1
        canvas.zoomScale = 1
        canvas.isScrollEnabled = false
    }

    private func syncCellStates(changedFrom previousRecognizedLetters: [CrosswordCoordinate: String]? = nil) {
        guard let previousRecognizedLetters else {
            clearAllInk()
            return
        }

        let changedCoordinates = Set(previousRecognizedLetters.keys).union(recognizedLetters.keys)
        for coordinate in changedCoordinates where previousRecognizedLetters[coordinate] != recognizedLetters[coordinate] {
            guard let state = cellStates[coordinate] else { continue }
            state.clearInk()
        }
    }

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        guard let canvas = canvasView as? CellCanvasView,
              let state = cellStates[canvas.coordinate],
              !state.isClearingInk,
              !canvas.drawing.bounds.isEmpty else {
            return
        }

        let didStartNewDrawing = state.drawing.bounds.isEmpty && !canvas.drawing.bounds.isEmpty
        if didStartNewDrawing {
            state.startedWithRecognizedLetter = recognizedLetters[canvas.coordinate]?.isEmpty == false
        }

        finishActiveInkIfNeeded(excluding: canvas.coordinate)
        activeInkCoordinate = canvas.coordinate
        state.drawing = canvas.drawing
        selectForWriting(at: canvas.coordinate)
        scheduleResolution(for: canvas.coordinate)
    }

    private func selectForWriting(at coordinate: CrosswordCoordinate) {
        guard coordinate != selectedCell else { return }
        onSelect(coordinate)
    }

    private func finishActiveInkIfNeeded(excluding coordinate: CrosswordCoordinate) {
        guard let activeInkCoordinate, activeInkCoordinate != coordinate else { return }
        scheduleResolution(for: activeInkCoordinate, delay: 0.05)
        self.activeInkCoordinate = nil
    }

    private func scheduleResolution(for coordinate: CrosswordCoordinate, delay: TimeInterval = 1.6) {
        guard let state = cellStates[coordinate] else { return }
        state.pendingTask?.cancel()
        state.recognitionGeneration += 1
        let generation = state.recognitionGeneration
        let hasInk = !state.drawing.bounds.isEmpty

        guard hasInk else {
            state.pendingTask = nil
            return
        }

        let task = DispatchWorkItem { [weak self, weak state] in
            guard let self, let state else { return }
            let drawing = state.drawing
            Self.recognizeLetter(in: drawing) { [weak self, weak state] result in
                DispatchQueue.main.async {
                    guard let self,
                          let state,
                          self.cellStates[coordinate] === state,
                          state.recognitionGeneration == generation else {
                        return
                    }
                    state.pendingTask = nil
                    state.lastRecognitionDebug = result.debugDescription
                    self.resolve(coordinate: coordinate, result: result)
                }
            }
        }

        state.pendingTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
    }

    private func resolve(coordinate: CrosswordCoordinate, result: HandwritingRecognitionResult) {
        guard let state = cellStates[coordinate] else { return }

        guard let resolvedLetter = result.letter else {
            if state.startedWithRecognizedLetter,
               Self.isDeleteGesture(in: state.drawing, canvasSize: state.canvas.bounds.size) {
                Self.debugLog("Recognition treated ink as delete at \(coordinate.row),\(coordinate.column): \(result.debugDescription)")
                state.clearRecognition()
                if activeInkCoordinate == coordinate {
                    activeInkCoordinate = nil
                }
                onRecognizedLetter(nil, coordinate)
                return
            }

            Self.debugLog("Recognition kept ink at \(coordinate.row),\(coordinate.column): \(result.debugDescription)")
            return
        }

        state.clearRecognition()
        if activeInkCoordinate == coordinate {
            activeInkCoordinate = nil
        }
        onRecognizedLetter(resolvedLetter, coordinate)
    }

    private static func lastLetter(in text: String) -> String? {
        let normalized = text
            .uppercased()
            .replacingOccurrences(of: "0", with: "O")
            .replacingOccurrences(of: "1", with: "I")
            .replacingOccurrences(of: "|", with: "I")
            .replacingOccurrences(of: "5", with: "S")
            .replacingOccurrences(of: "8", with: "B")

        return normalized.last { character in
            character >= "A" && character <= "Z"
        }.map(String.init)
    }

    fileprivate static func bestSingleLetter(from candidates: [String]) -> String? {
        candidates.compactMap(singleLetter(in:)).first ?? candidates.compactMap(lastLetter(in:)).first
    }

    private static func singleLetter(in text: String) -> String? {
        let letters = text
            .uppercased()
            .filter { character in
                character >= "A" && character <= "Z"
            }
        return letters.count == 1 ? String(letters[letters.startIndex]) : nil
    }

    private static func recognizeLetter(in drawing: PKDrawing, completion: @escaping (HandwritingRecognitionResult) -> Void) {
        recognizeLetterWithDigitalInkIfAvailable(in: drawing, completion: completion)
    }

    private static func isDeleteGesture(in drawing: PKDrawing, canvasSize: CGSize) -> Bool {
        let strokes = drawing.strokes
        guard !strokes.isEmpty else { return false }

        let width = max(canvasSize.width, 1)
        let height = max(canvasSize.height, 1)
        let cellSpan = max(min(width, height), 1)
        let bounds = drawing.bounds
        let horizontalCoverage = bounds.width / width
        let verticalCoverage = bounds.height / height
        let broadCoverage = horizontalCoverage >= 0.45 || verticalCoverage >= 0.45
        let balancedCoverage = horizontalCoverage >= 0.32 && verticalCoverage >= 0.22
        let stats = deleteGestureStats(for: strokes, width: width, height: height)
        let normalizedLength = stats.totalLength / cellSpan

        let longStrike = stats.hasStrikeLikeStroke && broadCoverage && normalizedLength >= 0.55
        let crossedOut = strokes.count >= 2 && stats.hasStrikeLikeStroke && broadCoverage && normalizedLength >= 0.75
        let heavyScribble = strokes.count >= 3 && balancedCoverage && normalizedLength >= 1.15

        return longStrike || crossedOut || heavyScribble
    }

    private static func deleteGestureStats(
        for strokes: [PKStroke],
        width: CGFloat,
        height: CGFloat
    ) -> (totalLength: CGFloat, hasStrikeLikeStroke: Bool) {
        var totalLength: CGFloat = 0
        var hasStrikeLikeStroke = false

        for stroke in strokes {
            let points = stroke.path.map(\.location)
            guard points.count >= 2,
                  let first = points.first,
                  let last = points.last else {
                continue
            }

            for index in points.indices.dropFirst() {
                let previous = points[points.index(before: index)]
                totalLength += hypot(points[index].x - previous.x, points[index].y - previous.y)
            }

            let horizontalSpan = abs(last.x - first.x) / width
            let verticalSpan = abs(last.y - first.y) / height
            let isHorizontalStrike = horizontalSpan >= 0.48 && verticalSpan <= 0.32
            let isDiagonalStrike = horizontalSpan >= 0.36 && verticalSpan >= 0.24
            hasStrikeLikeStroke = hasStrikeLikeStroke || isHorizontalStrike || isDiagonalStrike
        }

        return (totalLength, hasStrikeLikeStroke)
    }

    private static func recognizeLetterWithDigitalInkIfAvailable(
        in drawing: PKDrawing,
        completion: @escaping (HandwritingRecognitionResult) -> Void
    ) {
        #if canImport(MLKitDigitalInkRecognition)
        digitalInkRecognizer.recognize(drawing: drawing, completion: completion)
        #else
        completion(HandwritingRecognitionResult(letter: nil, debugDescription: "ML Kit Digital Ink unavailable"))
        #endif
    }

    private static let strokeWidth: CGFloat = 8
    private static let writingInk = UIColor(red: 0.05, green: 0.06, blue: 0.06, alpha: 1)
    #if canImport(MLKitDigitalInkRecognition)
    private static let digitalInkRecognizer = DigitalInkLetterRecognizer()
    #endif

    fileprivate static func debugLog(_ message: String) {
        #if DEBUG
        print("[Crossword Handwriting] \(message)")
        #endif
    }

}

private struct HandwritingRecognitionResult {
    let letter: String?
    let debugDescription: String
}

#if canImport(MLKitDigitalInkRecognition)
private final class DigitalInkLetterRecognizer {
    private let model: DigitalInkRecognitionModel?
    private let recognizer: DigitalInkRecognizer?
    private let modelManager = ModelManager.modelManager()
    private let modelDownloadConditions = ModelDownloadConditions(
        allowsCellularAccess: true,
        allowsBackgroundDownloading: true
    )
    private var isDownloadingModel = false
    private var pendingCompletions: [(Error?) -> Void] = []
    private var notificationObservers: [NSObjectProtocol] = []

    init() {
        guard let identifier = DigitalInkRecognitionModelIdentifier(forLanguageTag: "en-US") else {
            model = nil
            recognizer = nil
            BoardInputView.debugLog("ML Kit Digital Ink model identifier unavailable for en-US")
            return
        }

        let model = DigitalInkRecognitionModel(modelIdentifier: identifier)
        self.model = model
        recognizer = DigitalInkRecognizer.digitalInkRecognizer(
            options: DigitalInkRecognizerOptions(model: model)
        )
        observeModelDownloadNotifications()
        downloadModelIfNeeded()
    }

    deinit {
        notificationObservers.forEach(NotificationCenter.default.removeObserver)
    }

    func recognize(drawing: PKDrawing, completion: @escaping (HandwritingRecognitionResult) -> Void) {
        guard let model, let recognizer else {
            completion(HandwritingRecognitionResult(letter: nil, debugDescription: "ML Kit Digital Ink not initialized"))
            return
        }

        let ink = Self.ink(from: drawing)
        guard !ink.strokes.isEmpty else {
            completion(HandwritingRecognitionResult(letter: nil, debugDescription: "ML Kit Digital Ink received no strokes"))
            return
        }

        if modelManager.isModelDownloaded(model) {
            recognize(ink: ink, recognizer: recognizer, completion: completion)
            return
        }

        downloadModelIfNeeded()
        let debugDescription = "ML Kit Digital Ink model is downloading"
        BoardInputView.debugLog(debugDescription)
        completion(HandwritingRecognitionResult(letter: nil, debugDescription: debugDescription))
    }

    private func recognize(
        ink: Ink,
        recognizer: DigitalInkRecognizer,
        completion: @escaping (HandwritingRecognitionResult) -> Void
    ) {
        recognizer.recognize(ink: ink) { result, error in
            if let error {
                let debugDescription = "ML Kit Digital Ink error=\(error.localizedDescription)"
                BoardInputView.debugLog(debugDescription)
                completion(HandwritingRecognitionResult(letter: nil, debugDescription: debugDescription))
                return
            }

            let candidates = result?.candidates.map(\.text) ?? []
            let letter = BoardInputView.bestSingleLetter(from: candidates)
            let debugDescription = "ML Kit Digital Ink candidates=\(candidates), letter=\(letter ?? "nil")"
            BoardInputView.debugLog(debugDescription)
            completion(HandwritingRecognitionResult(letter: letter, debugDescription: debugDescription))
        }
    }

    private func downloadModelIfNeeded(completion: ((Error?) -> Void)? = nil) {
        guard let model, !modelManager.isModelDownloaded(model) else {
            completion?(nil)
            return
        }

        if let completion {
            pendingCompletions.append(completion)
        }

        if isDownloadingModel {
            return
        }

        isDownloadingModel = true
        _ = modelManager.download(model, conditions: modelDownloadConditions)
        BoardInputView.debugLog("ML Kit Digital Ink en-US model download started")
    }

    private func observeModelDownloadNotifications() {
        let center = NotificationCenter.default
        notificationObservers.append(
            center.addObserver(
                forName: .mlkitModelDownloadDidSucceed,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.handleModelDownload(notification: notification, error: nil)
            }
        )
        notificationObservers.append(
            center.addObserver(
                forName: .mlkitModelDownloadDidFail,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                let error = notification.userInfo?[ModelDownloadUserInfoKey.error] as? Error
                self?.handleModelDownload(notification: notification, error: error)
            }
        )
    }

    private func handleModelDownload(notification: Notification, error: Error?) {
        guard let model,
              let downloadedModel = notification.userInfo?[ModelDownloadUserInfoKey.remoteModel] as? RemoteModel,
              downloadedModel.name == model.name else {
            return
        }

        isDownloadingModel = false
        let completions = pendingCompletions
        pendingCompletions.removeAll()

        if let error {
            BoardInputView.debugLog("ML Kit Digital Ink model download failed: \(error.localizedDescription)")
        } else {
            BoardInputView.debugLog("ML Kit Digital Ink en-US model downloaded")
        }

        completions.forEach { $0(error) }
    }

    private static func ink(from drawing: PKDrawing) -> Ink {
        var currentTime = 0
        let strokes = drawing.strokes.compactMap { stroke -> Stroke? in
            var lastPointTime = currentTime
            let points = stroke.path.map { strokePoint -> StrokePoint in
                let time = currentTime + Int(strokePoint.timeOffset * 1000)
                lastPointTime = time
                return StrokePoint(
                    x: Float(strokePoint.location.x),
                    y: Float(strokePoint.location.y),
                    t: time
                )
            }
            currentTime = lastPointTime + 50
            return points.isEmpty ? nil : Stroke(points: points)
        }

        return Ink(strokes: strokes)
    }
}
#endif

private final class CellCanvasView: PKCanvasView {
    let coordinate: CrosswordCoordinate

    init(coordinate: CrosswordCoordinate) {
        self.coordinate = coordinate
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class CellInputState {
    let coordinate: CrosswordCoordinate
    let canvas: CellCanvasView
    var drawing = PKDrawing()
    var pendingTask: DispatchWorkItem?
    var recognitionGeneration = 0
    var isClearingInk = false
    var lastRecognitionDebug = ""
    var startedWithRecognizedLetter = false

    init(coordinate: CrosswordCoordinate, canvas: CellCanvasView) {
        self.coordinate = coordinate
        self.canvas = canvas
    }

    func clearInk() {
        drawing = PKDrawing()
        startedWithRecognizedLetter = false
        isClearingInk = true
        canvas.drawing = drawing
        isClearingInk = false
        pendingTask?.cancel()
        pendingTask = nil
        recognitionGeneration += 1
    }

    func clearRecognition() {
        clearInk()
    }
}

private extension UIFont {
    static func serifSystemFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let baseFont = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = baseFont.fontDescriptor.withDesign(.serif) else {
            return baseFont
        }

        return UIFont(descriptor: descriptor, size: size)
    }
}

private struct CluePanel: View {
    let puzzle: CrosswordPuzzle
    let selectedCell: CrosswordCoordinate
    let recognizedLetters: [CrosswordCoordinate: String]
    let isLandscape: Bool
    @Binding var direction: CrosswordDirection
    let checkResult: PuzzleCheckResult?
    let startedAt: Date
    let switchDirection: () -> Void
    let selectClue: (CrosswordClue, CrosswordDirection) -> Void
    let checkPuzzle: () -> Void
    let restartPuzzle: () -> Void
    let startNewPuzzle: () -> Void
    let showAnswers: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: isLandscape ? 24 : 12) {
            topControls

            if isLandscape {
                currentClueControls

                stackedClueColumns
            } else {
                sideBySideClueColumns
                    .frame(maxWidth: .infinity)
                    .frame(height: 268)

                currentClueControls
            }

        }
        .padding(12)
        .background(Color.cluePanelSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.selectedClueSurface, lineWidth: 1)
        }
    }

    private var topControls: some View {
        HStack(spacing: 10) {
            TimerBadge(startedAt: startedAt)

            Spacer()

            puzzleMenu
        }
    }

    private var puzzleMenu: some View {
        Menu {
            Button(action: checkPuzzle) {
                Label("Check Puzzle", systemImage: "checkmark.circle")
            }

            Button(action: restartPuzzle) {
                Label("Restart Puzzle", systemImage: "arrow.counterclockwise")
            }

            Button(action: startNewPuzzle) {
                Label("New Puzzle", systemImage: "plus.square.on.square")
            }

            Button(action: showAnswers) {
                Label("Show Me the Answers", systemImage: "eye")
            }
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.warmIcon)
                .frame(width: 40, height: 40)
                .background(Color.controlSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Puzzle menu")
    }

    private var currentClueControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            CurrentClueCard(
                clue: puzzle.clue(containing: selectedCell, direction: direction),
                direction: direction,
                switchDirection: switchDirection
            )

            if let checkResult {
                PuzzleCheckCard(result: checkResult)
            }
        }
    }

    private var sideBySideClueColumns: some View {
        HStack(alignment: .top, spacing: 18) {
            ScrollableClueColumn(
                title: "Across",
                direction: .across,
                clues: puzzle.acrossClues,
                activeDirection: direction,
                selectedCell: selectedCell,
                recognizedLetters: recognizedLetters,
                selectClue: selectClue
            )

            ScrollableClueColumn(
                title: "Down",
                direction: .down,
                clues: puzzle.downClues,
                activeDirection: direction,
                selectedCell: selectedCell,
                recognizedLetters: recognizedLetters,
                selectClue: selectClue
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stackedClueColumns: some View {
        VStack(alignment: .leading, spacing: 24) {
            ScrollableClueColumn(
                title: "Across",
                direction: .across,
                clues: puzzle.acrossClues,
                activeDirection: direction,
                selectedCell: selectedCell,
                recognizedLetters: recognizedLetters,
                selectClue: selectClue
            )

            ScrollableClueColumn(
                title: "Down",
                direction: .down,
                clues: puzzle.downClues,
                activeDirection: direction,
                selectedCell: selectedCell,
                recognizedLetters: recognizedLetters,
                selectClue: selectClue
            )
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct DirectionTabs: View {
    @Binding var selection: CrosswordDirection

    var body: some View {
        HStack(spacing: 4) {
            ForEach(CrosswordDirection.allCases) { direction in
                let isSelected = selection == direction

                Button {
                    selection = direction
                } label: {
                    Text(direction.title)
                        .font(.system(size: 15, weight: isSelected ? .bold : .semibold, design: .serif))
                        .foregroundStyle(isSelected ? Color.surface : Color.directionText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            isSelected ? Color.directionActive : Color.clear,
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.directionTrack, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primaryAction.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct PopupTabOption<Value: Hashable>: Identifiable {
    let value: Value
    let title: String

    var id: Value { value }
}

private struct PopupTabBar<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [PopupTabOption<Value>]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options) { option in
                let isSelected = selection == option.value

                Button {
                    selection = option.value
                } label: {
                    Text(option.title)
                        .font(.system(size: 15, weight: isSelected ? .bold : .semibold, design: .serif))
                        .foregroundStyle(isSelected ? Color.appBackground : Color.warmIcon)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            isSelected ? Color.warmIcon : Color.controlSurface,
                            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.selectedClueSurface.opacity(0.36), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.selectedClueSurface, lineWidth: 1)
        }
    }
}

private struct PuzzleConfigurationView: View {
    @Binding var selectedSize: Int
    @Binding var selectedDifficulty: PuzzleDifficulty
    let puzzleSizes: [Int]
    let startPuzzle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("New puzzle")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ink)

                Text("Choose your setup.")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(Color.warmIcon)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Size")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ink)

                PopupTabBar(
                    selection: $selectedSize,
                    options: puzzleSizes.map { size in
                        PopupTabOption(value: size, title: "\(size) x \(size)")
                    }
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Difficulty")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ink)

                PopupTabBar(
                    selection: $selectedDifficulty,
                    options: PuzzleDifficulty.allCases.map { difficulty in
                        PopupTabOption(value: difficulty, title: difficulty.title)
                    }
                )
            }

            Button(action: startPuzzle) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("Generate puzzle")
                }
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(Color.appBackground)
                .padding(.vertical, 13)
                    .frame(maxWidth: .infinity)
                .background(Color.warmIcon, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(Color.cluePanelSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.selectedClueSurface, lineWidth: 1)
        }
        .padding(22)
        .presentationDetents([.height(410)])
        .presentationBackground(Color.appBackground)
    }
}

private struct CompletionBanner: View {
    let startNewPuzzle: () -> Void
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.appBackground)
                .frame(width: 30, height: 30)
                .background(Color.warmIcon, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Puzzle complete")
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ink)

                Text("Nice work.")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundStyle(Color.warmIcon)
            }

            Spacer(minLength: 8)

            Button(action: startNewPuzzle) {
                Text("New")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundStyle(Color.appBackground)
                    .padding(.horizontal, 13)
                    .frame(height: 32)
                    .background(Color.warmIcon, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.warmIcon)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.appBackground.opacity(0.96), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.selectedClueSurface, lineWidth: 1)
        }
        .shadow(color: Color.shadow.opacity(0.14), radius: 12, x: 0, y: 6)
    }
}

private struct PuzzleCheckCard: View {
    let result: PuzzleCheckResult

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(result.title)
                    .font(.system(size: 15, weight: .black, design: .serif))

                Text(result.message)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .fixedSize(horizontal: false, vertical: true)
            }
        } icon: {
            Image(systemName: result.systemImage)
                .font(.system(size: 20, weight: .bold))
        }
        .foregroundStyle(result.foregroundColor)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(result.backgroundColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(result.foregroundColor.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct CurrentClueCard: View {
    let clue: CrosswordClue?
    let direction: CrosswordDirection
    let switchDirection: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let clue {
                Text("\(clue.number) \(direction.title)")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)

                Text(clue.text)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.55)
                    .allowsTightening(true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                Text("Select a clue")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundStyle(Color.softInk)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 80, alignment: .topLeading)
        .background(Color.controlSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture(perform: switchDirection)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Switches clue direction")
    }
}

private struct ScrollableClueColumn: View {
    let title: String
    let direction: CrosswordDirection
    let clues: [CrosswordClue]
    let activeDirection: CrosswordDirection
    let selectedCell: CrosswordCoordinate
    let recognizedLetters: [CrosswordCoordinate: String]
    let selectClue: (CrosswordClue, CrosswordDirection) -> Void

    private var currentClueID: String? {
        clues.first { clue in
            clue.cells.contains(selectedCell)
        }?.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ClueSectionHeader(title: title)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    ClueList(
                        direction: direction,
                        clues: clues,
                        activeDirection: activeDirection,
                        selectedCell: selectedCell,
                        recognizedLetters: recognizedLetters,
                        selectClue: selectClue
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onAppear {
                    scrollToCurrentClue(with: proxy, animated: false)
                }
                .onChange(of: currentClueID) { _, _ in
                    scrollToCurrentClue(with: proxy, animated: true)
                }
                .onChange(of: activeDirection) { _, _ in
                    scrollToCurrentClue(with: proxy, animated: true)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func scrollToCurrentClue(with proxy: ScrollViewProxy, animated: Bool) {
        guard let currentClueID else { return }

        let scroll = {
            proxy.scrollTo(currentClueID, anchor: .center)
        }

        if animated {
            withAnimation(.easeInOut(duration: 0.22), scroll)
        } else {
            scroll()
        }
    }
}

private struct ClueSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .bold, design: .serif))
            .foregroundStyle(Color.ink)
            .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
    }
}

private struct ClueList: View {
    let direction: CrosswordDirection
    let clues: [CrosswordClue]
    let activeDirection: CrosswordDirection
    let selectedCell: CrosswordCoordinate
    let recognizedLetters: [CrosswordCoordinate: String]
    let selectClue: (CrosswordClue, CrosswordDirection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(clues, id: \.id) { clue in
                let isCompleted = clue.cells.allSatisfy { coordinate in
                    recognizedLetters[coordinate]?.isEmpty == false
                }
                let containsSelectedCell = clue.cells.contains(selectedCell) && !isCompleted
                let isSelected = containsSelectedCell && direction == activeDirection
                let isCrossingSelection = containsSelectedCell && direction != activeDirection

                Button {
                    selectClue(clue, direction)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(clue.number).")
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundStyle(Color.ink.opacity(isCompleted ? 0.42 : 1))
                            .frame(width: 26, alignment: .trailing)

                        Text(clue.text)
                            .font(.system(size: 15, weight: .medium, design: .serif))
                            .foregroundStyle(Color.ink.opacity(isCompleted ? 0.42 : 1))

                        Spacer(minLength: 6)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(isSelected ? Color.selectedClueSurface.opacity(0.68) : Color.clear, in: RoundedRectangle(cornerRadius: 0, style: .continuous))
                    .overlay(alignment: .leading) {
                        if isCrossingSelection {
                            Rectangle()
                                .fill(Color.selectedClueSurface.opacity(0.85))
                                .frame(width: 5)
                                .padding(.vertical, 5)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .id(clue.id)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct PaperBackground: View {
    var body: some View {
        Color.appBackground
        .overlay {
            Color.paperGrain.opacity(0.16)
                .blendMode(.multiply)
        }
        .ignoresSafeArea()
    }
}

struct CrosswordPuzzle {
    let size: Int
    let blackCells: Set<CrosswordCoordinate>
    let acrossClues: [CrosswordClue]
    let downClues: [CrosswordClue]

    private let letters: [CrosswordCoordinate: String]
    private let numbers: [CrosswordCoordinate: Int]

    var solutionLetters: [CrosswordCoordinate: String] {
        letters
    }

    var playableCoordinates: [CrosswordCoordinate] {
        letters.keys.sorted {
            if $0.row == $1.row {
                return $0.column < $1.column
            }

            return $0.row < $1.row
        }
    }

    var layoutSignature: String {
        let cells = playableCoordinates
            .map { "\($0.row),\($0.column)" }
            .joined(separator: "|")
        return "\(size):\(cells)"
    }

    static func generated(size: Int, seed: Int? = nil, difficulty: PuzzleDifficulty = .easy) -> CrosswordPuzzle {
        if let puzzle = CrosswordGenerator.generate(size: size, seed: seed, difficulty: difficulty) {
            return puzzle
        }

        let rows = PuzzleGenerator.rows(size: size)
        let clueBank = PuzzleGenerator.clues(for: rows)
        return CrosswordPuzzle(solutionRows: rows, clueBank: clueBank)
    }

    static let sample = CrosswordPuzzle(
        solutionRows: [
            "HEART",
            "EMBER",
            "ABUSE",
            "RESIN",
            "TREND"
        ],
        clueBank: [
            "HEART": "It beats in your chest",
            "EMBER": "Glowing piece left after a fire",
            "ABUSE": "Treat cruelly or misuse",
            "RESIN": "Sticky tree secretion",
            "TREND": "General direction things are moving"
        ]
    )

    init(solutionRows: [String], clueBank: [String: String]) {
        size = solutionRows.count

        var gridLetters: [CrosswordCoordinate: String] = [:]
        var blocks: Set<CrosswordCoordinate> = []

        for (rowIndex, row) in solutionRows.enumerated() {
            for (columnIndex, character) in row.enumerated() {
                let coordinate = CrosswordCoordinate(row: rowIndex, column: columnIndex)
                if character == "#" {
                    blocks.insert(coordinate)
                } else {
                    gridLetters[coordinate] = String(character).uppercased()
                }
            }
        }

        letters = gridLetters
        blackCells = blocks

        var assignedNumbers: [CrosswordCoordinate: Int] = [:]
        var nextNumber = 1

        for row in 0..<size {
            for column in 0..<size {
                let coordinate = CrosswordCoordinate(row: row, column: column)
                guard gridLetters[coordinate] != nil else { continue }

                if Self.isAcrossStart(coordinate, letters: gridLetters) || Self.isDownStart(coordinate, letters: gridLetters) {
                    assignedNumbers[coordinate] = nextNumber
                    nextNumber += 1
                }
            }
        }

        numbers = assignedNumbers
        acrossClues = Self.entries(
            direction: .across,
            size: size,
            letters: gridLetters,
            numbers: assignedNumbers,
            clueBank: clueBank
        )
        downClues = Self.entries(
            direction: .down,
            size: size,
            letters: gridLetters,
            numbers: assignedNumbers,
            clueBank: clueBank
        )
    }

    func isPlayable(_ coordinate: CrosswordCoordinate) -> Bool {
        coordinate.row >= 0 && coordinate.row < size && coordinate.column >= 0 && coordinate.column < size && letters[coordinate] != nil
    }

    func number(for coordinate: CrosswordCoordinate) -> Int? {
        numbers[coordinate]
    }

    func letter(at coordinate: CrosswordCoordinate) -> String? {
        letters[coordinate]
    }

    func check(answers: [CrosswordCoordinate: String]) -> PuzzleCheckResult {
        let missingCount = letters.keys.filter { coordinate in
            answers[coordinate]?.isEmpty ?? true
        }.count

        if missingCount > 0 {
            return .incomplete(missingCount: missingCount)
        }

        let incorrectCount = letters.filter { entry in
            answers[entry.key]?.uppercased() != entry.value
        }.count

        if incorrectCount == 0 {
            return .correct
        }

        return .incorrect(incorrectCount: incorrectCount)
    }

    func clue(containing coordinate: CrosswordCoordinate, direction: CrosswordDirection) -> CrosswordClue? {
        clues(for: direction).first { $0.cells.contains(coordinate) }
    }

    func answerCells(containing coordinate: CrosswordCoordinate, direction: CrosswordDirection) -> Set<CrosswordCoordinate> {
        Set(clue(containing: coordinate, direction: direction)?.cells ?? [])
    }

    func nextCoordinate(after coordinate: CrosswordCoordinate, direction: CrosswordDirection) -> CrosswordCoordinate? {
        let orderedClues = clues(for: direction)

        guard let clueIndex = orderedClues.firstIndex(where: { $0.cells.contains(coordinate) }),
              let currentIndex = orderedClues[clueIndex].cells.firstIndex(of: coordinate) else {
            return nil
        }

        let nextCellIndex = orderedClues[clueIndex].cells.index(after: currentIndex)
        if nextCellIndex < orderedClues[clueIndex].cells.endIndex {
            return orderedClues[clueIndex].cells[nextCellIndex]
        }

        let nextClueIndex = orderedClues.index(after: clueIndex)
        if nextClueIndex < orderedClues.endIndex {
            return orderedClues[nextClueIndex].cells.first
        }

        return orderedClues.first?.cells.first
    }

    func adjacentClueStart(containing coordinate: CrosswordCoordinate, direction: CrosswordDirection, offset: Int) -> CrosswordCoordinate? {
        let orderedClues = clues(for: direction)
        guard !orderedClues.isEmpty else { return nil }

        let currentIndex = orderedClues.firstIndex { $0.cells.contains(coordinate) } ?? 0
        let wrappedIndex = (currentIndex + offset + orderedClues.count) % orderedClues.count
        return orderedClues[wrappedIndex].cells.first
    }

    private func clues(for direction: CrosswordDirection) -> [CrosswordClue] {
        direction == .across ? acrossClues : downClues
    }

    private static func entries(
        direction: CrosswordDirection,
        size: Int,
        letters: [CrosswordCoordinate: String],
        numbers: [CrosswordCoordinate: Int],
        clueBank: [String: String]
    ) -> [CrosswordClue] {
        var clues: [CrosswordClue] = []

        for row in 0..<size {
            for column in 0..<size {
                let coordinate = CrosswordCoordinate(row: row, column: column)
                let isStart = direction == .across
                    ? isAcrossStart(coordinate, letters: letters)
                    : isDownStart(coordinate, letters: letters)

                guard isStart, let number = numbers[coordinate] else { continue }

                var cells: [CrosswordCoordinate] = []
                var cursor = coordinate

                while letters[cursor] != nil {
                    cells.append(cursor)
                    cursor = direction == .across
                        ? CrosswordCoordinate(row: cursor.row, column: cursor.column + 1)
                        : CrosswordCoordinate(row: cursor.row + 1, column: cursor.column)
                }

                guard cells.count > 1 else { continue }

                let answer = cells.compactMap { letters[$0] }.joined()
                let text = clueBank[answer] ?? "Definition for \(answer)"
                clues.append(CrosswordClue(number: number, answer: answer, text: text, cells: cells))
            }
        }

        return clues
    }

    private static func isAcrossStart(_ coordinate: CrosswordCoordinate, letters: [CrosswordCoordinate: String]) -> Bool {
        let left = CrosswordCoordinate(row: coordinate.row, column: coordinate.column - 1)
        let right = CrosswordCoordinate(row: coordinate.row, column: coordinate.column + 1)
        return letters[coordinate] != nil && letters[left] == nil && letters[right] != nil
    }

    private static func isDownStart(_ coordinate: CrosswordCoordinate, letters: [CrosswordCoordinate: String]) -> Bool {
        let above = CrosswordCoordinate(row: coordinate.row - 1, column: coordinate.column)
        let below = CrosswordCoordinate(row: coordinate.row + 1, column: coordinate.column)
        return letters[coordinate] != nil && letters[above] == nil && letters[below] != nil
    }
}

enum PuzzleCheckResult: Equatable {
    case incomplete(missingCount: Int)
    case correct
    case incorrect(incorrectCount: Int)

    var title: String {
        switch self {
        case .incomplete:
            "Not filled yet"
        case .correct:
            "Puzzle complete"
        case .incorrect:
            "Not quite"
        }
    }

    var message: String {
        switch self {
        case .incomplete(let missingCount):
            "\(missingCount) \(missingCount == 1 ? "square is" : "squares are") still blank."
        case .correct:
            "Everything matches the solution."
        case .incorrect(let incorrectCount):
            "\(incorrectCount) \(incorrectCount == 1 ? "square looks" : "squares look") wrong."
        }
    }

    var systemImage: String {
        switch self {
        case .incomplete:
            "square.dashed"
        case .correct:
            "checkmark.seal.fill"
        case .incorrect:
            "exclamationmark.triangle.fill"
        }
    }

    var foregroundColor: Color {
        switch self {
        case .incomplete:
            .softInk
        case .correct:
            .successInk
        case .incorrect:
            .warningInk
        }
    }

    var backgroundColor: Color {
        switch self {
        case .incomplete:
            .surfaceVariant
        case .correct:
            .successSurface
        case .incorrect:
            .warningSurface
        }
    }
}

struct CrosswordClue: Identifiable {
    let number: Int
    let answer: String
    let text: String
    let cells: [CrosswordCoordinate]

    var id: String {
        "\(number)-\(answer)-\(cells.first?.row ?? 0)-\(cells.first?.column ?? 0)"
    }
}

    private enum PuzzleGenerator {
    private static let wordSquare = ["HEART", "EMBER", "ABUSE", "RESIN", "TREND"]

    private static let clueBank: [String: String] = [
        "HEART": "It beats in your chest",
        "EMBER": "Glowing piece left after a fire",
        "ABUSE": "Treat cruelly or misuse",
        "RESIN": "Sticky tree secretion",
        "TREND": "General direction things are moving",
        "PLANT": "A living thing with roots",
        "RIVER": "Natural flowing water",
        "ORBIT": "Path around a planet",
        "CLOUD": "White shape in the sky",
        "STONE": "Small piece of rock",
        "BRAVE": "Showing courage",
        "LIGHT": "Opposite of dark",
        "MUSIC": "Organized sound",
        "OCEAN": "A vast body of salt water",
        "FIELD": "Open land",
        "SPARK": "Tiny flash of fire",
        "TRAIL": "Path through nature",
        "HONEY": "Sweet bee-made food",
        "VIVID": "Bright and intense",
        "GRAIN": "Tiny seed or texture",
        "CROSSWORDS": "Puzzles made of crossing answers",
        "WONDERLAND": "A magical imagined place",
        "BRIGHTNESS": "The quality of giving off light",
        "OCEANFRONT": "Land facing the sea",
        "STARGAZING": "Watching the night sky",
        "MEADOWLARK": "A songbird of open fields",
        "THUNDERING": "Making a deep rumbling sound",
        "HARVESTERS": "People or machines that gather crops",
        "RIVERSTONE": "Smooth rock shaped by flowing water",
        "LIGHTHOUSE": "Beacon tower near water"
    ]

    static func rows(size: Int) -> [String] {
        let blockCount = max(1, size / wordSquare.count)
        let normalizedSize = blockCount * wordSquare.count

        return (0..<normalizedSize).map { row in
            let activeBlock = row / wordSquare.count
            let wordSquareRow = wordSquare[row % wordSquare.count]

            return (0..<blockCount).map { block in
                block == activeBlock ? wordSquareRow : String(repeating: "#", count: wordSquare.count)
            }
            .joined()
        }
    }

    static func clues(for rows: [String]) -> [String: String] {
        var clues = clueBank
        let size = rows.count

        for row in rows {
            guard !row.contains("#") else { continue }
            clues[row] = clues[row] ?? "\(row.count)-letter crossword answer"
        }

        for column in 0..<size {
            var answer = ""

            for row in rows {
                let index = row.index(row.startIndex, offsetBy: column)
                let character = row[index]

                if character == "#" {
                    if answer.count > 1 {
                        clues[answer] = clues[answer] ?? "\(answer.count)-letter crossword answer"
                    }
                    answer = ""
                } else {
                    answer.append(character)
                }
            }

            if answer.count > 1 {
                clues[answer] = clues[answer] ?? "\(answer.count)-letter crossword answer"
            }
        }

        return clues
    }
}

struct CrosswordCoordinate: Hashable {
    let row: Int
    let column: Int
}

enum CrosswordDirection: String, CaseIterable, Identifiable {
    case across
    case down

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

enum PuzzleDifficulty: String, CaseIterable, Codable, Identifiable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var seedOffset: Int {
        switch self {
        case .easy:
            100
        case .medium:
            200
        case .hard:
            300
        }
    }
}

private extension Color {
    static let appBackground = Color(red: 1.00, green: 0.992, blue: 0.965)
    static let paperWarmth = Color(red: 0.98, green: 0.94, blue: 0.86)
    static let paperGrain = Color(red: 0.94, green: 0.90, blue: 0.80)
    static let surface = Color.white
    static let cluePanelSurface = Color.black.opacity(0.01)
    static let actionSurface = Color(red: 0.98, green: 0.985, blue: 0.965)
    static let surfaceVariant = Color(red: 0.91, green: 0.925, blue: 0.89)
    static let ink = Color(red: 0.11, green: 0.12, blue: 0.12)
    static let softInk = Color(red: 0.42, green: 0.42, blue: 0.38)
    static let warmIcon = Color(red: 0.44, green: 0.39, blue: 0.32)
    static let controlSurface = Color(red: 0.94, green: 0.90, blue: 0.80).opacity(0.5)
    static let primaryAction = Color(red: 0.12, green: 0.43, blue: 0.43)
    static let primaryContainer = Color(red: 0.80, green: 0.90, blue: 0.86)
    static let currentClueSurface = Color(red: 0.86, green: 0.92, blue: 0.98)
    static let timerSurface = Color(red: 0.94, green: 0.90, blue: 0.80).opacity(0.5)
    static let directionTrack = Color(red: 0.68, green: 0.86, blue: 0.86)
    static let directionText = Color(red: 0.11, green: 0.42, blue: 0.42)
    static let directionInactive = Color(red: 0.35, green: 0.62, blue: 0.61)
    static let directionActive = Color(red: 0.12, green: 0.49, blue: 0.50)
    static let secondaryContainer = Color(red: 0.88, green: 0.91, blue: 0.86)
    static let selectedAnswerSurface = Color(red: 0.80, green: 0.90, blue: 0.86)
    static let selectedClueSurface = Color(red: 0.94, green: 0.90, blue: 0.80)
    static let boardWarmth = Color(red: 0.98, green: 0.93, blue: 0.84)
    static let boardEdge = Color.black
    static let block = Color.warmIcon
    static let gridLine = Color(red: 0.68, green: 0.62, blue: 0.52)
    static let clueNumber = Color(red: 0.44, green: 0.39, blue: 0.32)
    static let hairline = Color(red: 0.70, green: 0.70, blue: 0.62).opacity(0.72)
    static let shadow = Color(red: 0.11, green: 0.10, blue: 0.08)
    static let warningInk = Color(red: 0.52, green: 0.34, blue: 0.05)
    static let warningSurface = Color(red: 0.98, green: 0.90, blue: 0.68)
    static let successInk = Color(red: 0.08, green: 0.39, blue: 0.22)
    static let successSurface = Color(red: 0.78, green: 0.91, blue: 0.80)
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
