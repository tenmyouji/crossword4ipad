import PencilKit
import SwiftUI
import UIKit
import Vision

struct ContentView: View {
    @State private var selectedCell = CrosswordCoordinate(row: 0, column: 0)
    @State private var direction: CrosswordDirection = .across
    @State private var recognizedLetters: [CrosswordCoordinate: String] = [:]
    @State private var checkResult: PuzzleCheckResult?
    @State private var puzzle = CrosswordPuzzle.generated(size: 5)
    @State private var nextPuzzleSize = 5
    @State private var isShowingCompletionSheet = false
    @State private var puzzleStartedAt = Date()

    private let puzzleSizes = [5, 10, 15]

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(spacing: 18) {
                HeaderView(size: puzzle.size, startedAt: puzzleStartedAt)

                HStack(alignment: .top, spacing: 24) {
                    CrosswordBoard(
                        puzzle: puzzle,
                        selectedCell: $selectedCell,
                        direction: direction,
                        recognizedLetters: $recognizedLetters,
                        onSelectCell: selectCell,
                        onRecognizedLetter: storeRecognizedLetter
                    )
                    .frame(maxWidth: 720, maxHeight: 720)
                    .aspectRatio(1, contentMode: .fit)

                    VStack(spacing: 12) {
                        CluePanel(
                            puzzle: puzzle,
                            selectedCell: selectedCell,
                            direction: $direction,
                            moveToPreviousClue: moveToPreviousClue,
                            moveToNextClue: moveToNextClue,
                            selectClue: selectClue
                        )

                        PuzzleActionsView(
                            checkResult: checkResult,
                            checkPuzzle: checkPuzzle,
                            restartPuzzle: restartPuzzle,
                            startNewPuzzle: startNewPuzzle,
                            showAnswers: showAnswers
                        )
                    }
                    .frame(width: 360)
                }
                .frame(maxWidth: 1160)
            }
            .padding(32)
        }
        .sheet(isPresented: $isShowingCompletionSheet) {
            CompletionView(
                selectedSize: $nextPuzzleSize,
                puzzleSizes: puzzleSizes,
                showAnotherPuzzle: showAnotherPuzzle
            )
        }
    }

    private func clearSelectedCell() {
        recognizedLetters.removeValue(forKey: selectedCell)
        checkResult = nil
    }

    private func clearPuzzle() {
        recognizedLetters.removeAll()
        checkResult = nil
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
        if let coordinate = puzzle.adjacentClueStart(containing: selectedCell, direction: direction, offset: -1) {
            selectedCell = coordinate
        }
    }

    private func moveToNextClue() {
        if let coordinate = puzzle.adjacentClueStart(containing: selectedCell, direction: direction, offset: 1) {
            selectedCell = coordinate
        }
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
        resetPuzzle(size: puzzle.size)
    }

    private func restartPuzzle() {
        recognizedLetters.removeAll()
        checkResult = nil
        isShowingCompletionSheet = false
        selectedCell = puzzle.playableCoordinates.first ?? selectedCell
        direction = .across
        puzzleStartedAt = Date()
    }

    private func showAnswers() {
        recognizedLetters = puzzle.solutionLetters
        checkResult = .correct
    }

    private func showAnotherPuzzle() {
        resetPuzzle(size: nextPuzzleSize)
        isShowingCompletionSheet = false
    }

    private func resetPuzzle(size: Int) {
        puzzle = CrosswordPuzzle.generated(size: size)
        selectedCell = CrosswordCoordinate(row: 0, column: 0)
        direction = .across
        recognizedLetters.removeAll()
        checkResult = nil
        puzzleStartedAt = Date()
    }
}

private struct HeaderView: View {
    let size: Int
    let startedAt: Date

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("crosswordapp")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ink)

                Text("\(size) x \(size) mini · write with Apple Pencil, tap with touch")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(Color.softInk)
            }

            Spacer()

            TimerBadge(startedAt: startedAt)
        }
        .frame(maxWidth: 1160)
    }
}

private struct TimerBadge: View {
    let startedAt: Date

    var body: some View {
        TimelineView(.periodic(from: startedAt, by: 1)) { timeline in
            Label(Self.formattedElapsedTime(from: startedAt, to: timeline.date), systemImage: "timer")
                .font(.system(size: 14, weight: .bold, design: .serif))
                .monospacedDigit()
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.hairline, lineWidth: 1)
                }
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
    let onSelectCell: (CrosswordCoordinate) -> Void
    let onRecognizedLetter: (String?, CrosswordCoordinate) -> Void

    var body: some View {
        GeometryReader { proxy in
            let boardSize = min(proxy.size.width, proxy.size.height)
            let cellSize = boardSize / CGFloat(puzzle.size)
            let selectedAnswer = puzzle.answerCells(containing: selectedCell, direction: direction)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.surface)
                    .shadow(color: Color.shadow.opacity(0.16), radius: 12, x: 0, y: 5)

                ForEach(0..<puzzle.size, id: \.self) { row in
                    ForEach(0..<puzzle.size, id: \.self) { column in
                        let coordinate = CrosswordCoordinate(row: row, column: column)

                        CrosswordCell(
                            puzzle: puzzle,
                            coordinate: coordinate,
                            isSelected: coordinate == selectedCell,
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
    let isSelected: Bool
    let isHighlighted: Bool
    let recognizedLetter: String?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(fillStyle)

            if puzzle.isPlayable(coordinate) {
                if let recognizedLetter {
                    Text(recognizedLetter)
                        .font(.system(size: 42, weight: .black, design: .serif))
                        .minimumScaleFactor(0.45)
                        .foregroundStyle(Color.ink)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 8)
                }

                if let number = puzzle.number(for: coordinate) {
                    Text("\(number)")
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .foregroundStyle(Color.softInk)
                        .padding(4)
                }
            }
        }
        .overlay(alignment: .center) {
            Rectangle()
                .stroke(isSelected ? Color.primaryAction : Color.gridLine, lineWidth: isSelected ? 2.6 : 0.8)
        }
        .animation(.spring(response: 0.24, dampingFraction: 0.84), value: isSelected)
    }

    private var fillStyle: Color {
        if !puzzle.isPlayable(coordinate) {
            return .block
        }

        if isSelected {
            return .primaryContainer
        }

        if isHighlighted {
            return .secondaryContainer
        }

        return .surface
    }

}

private struct BoardInputLayer: UIViewRepresentable {
    let puzzle: CrosswordPuzzle
    @Binding var selectedCell: CrosswordCoordinate
    let recognizedLetters: [CrosswordCoordinate: String]
    let onSelectCell: (CrosswordCoordinate) -> Void
    let onRecognizedLetter: (String?, CrosswordCoordinate) -> Void

    func makeUIView(context: Context) -> BoardInputView {
        BoardInputView(
            puzzle: puzzle,
            selectedCell: selectedCell,
            recognizedLetters: recognizedLetters,
            onSelect: onSelectCell,
            onRecognizedLetter: onRecognizedLetter
        )
    }

    func updateUIView(_ view: BoardInputView, context: Context) {
        view.puzzle = puzzle
        view.selectedCell = selectedCell
        view.recognizedLetters = recognizedLetters
        view.onSelect = onSelectCell
        view.onRecognizedLetter = onRecognizedLetter
        view.setNeedsLayout()
    }
}

private final class BoardInputView: UIView, UIGestureRecognizerDelegate, UITextFieldDelegate {
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
            syncCellStates()
        }
    }

    var onSelect: (CrosswordCoordinate) -> Void
    var onRecognizedLetter: (String?, CrosswordCoordinate) -> Void

    private var cellStates: [CrosswordCoordinate: CellInputState] = [:]
    private lazy var pencilRecognizer: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePencilPan(_:)))
        recognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.pencil.rawValue)]
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = self
        return recognizer
    }()
    private var activeInkCoordinate: CrosswordCoordinate?
    private var activeStrokePoints: [CGPoint] = []

    init(
        puzzle: CrosswordPuzzle,
        selectedCell: CrosswordCoordinate,
        recognizedLetters: [CrosswordCoordinate: String],
        onSelect: @escaping (CrosswordCoordinate) -> Void,
        onRecognizedLetter: @escaping (String?, CrosswordCoordinate) -> Void
    ) {
        self.puzzle = puzzle
        self.selectedCell = selectedCell
        self.recognizedLetters = recognizedLetters
        self.onSelect = onSelect
        self.onRecognizedLetter = onRecognizedLetter
        super.init(frame: .zero)

        backgroundColor = .clear
        isMultipleTouchEnabled = true

        reconcileCellStates()
        addGestureRecognizer(pencilRecognizer)

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
            state.textField.frame = frame
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
        focusTextField(at: coordinate)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer === pencilRecognizer {
            return touch.type == .pencil
        }

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
            cellStates[coordinate]?.pendingTask?.cancel()
            cellStates[coordinate]?.canvas.removeFromSuperview()
            cellStates[coordinate]?.textField.removeFromSuperview()
            cellStates.removeValue(forKey: coordinate)
        }

        for coordinate in playableCoordinates where cellStates[coordinate] == nil {
            let textField = ScribbleCellTextField(coordinate: coordinate)
            configure(textField)
            textField.text = recognizedLetters[coordinate] ?? ""
            let canvas = CellCanvasView(coordinate: coordinate)
            configure(canvas)
            let state = CellInputState(coordinate: coordinate, textField: textField, canvas: canvas)
            cellStates[coordinate] = state
            addSubview(canvas)
            addSubview(textField)
        }

        syncCellStates()
    }

    private func configure(_ textField: ScribbleCellTextField) {
        textField.delegate = self
        textField.autocapitalizationType = .allCharacters
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.smartDashesType = .no
        textField.smartInsertDeleteType = .no
        textField.smartQuotesType = .no
        textField.keyboardType = .asciiCapable
        textField.textColor = .clear
        textField.tintColor = .clear
        textField.backgroundColor = .clear
        textField.isOpaque = false
        textField.inputView = UIView(frame: .zero)
        textField.inputAssistantItem.leadingBarButtonGroups = []
        textField.inputAssistantItem.trailingBarButtonGroups = []
        textField.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
    }

    private func configure(_ canvas: CellCanvasView) {
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.clipsToBounds = true
        canvas.isUserInteractionEnabled = false
        canvas.overrideUserInterfaceStyle = .light
        canvas.drawingPolicy = .pencilOnly
        canvas.tool = PKInkingTool(.pen, color: Self.writingInk, width: Self.strokeWidth)
        canvas.minimumZoomScale = 1
        canvas.maximumZoomScale = 1
        canvas.zoomScale = 1
        canvas.isScrollEnabled = false
    }

    private func syncCellStates() {
        for (coordinate, state) in cellStates {
            if !state.textField.isFirstResponder {
                state.textField.text = recognizedLetters[coordinate] ?? ""
            }
            state.clearInk()
        }
    }

    @objc private func textFieldEditingChanged(_ textField: UITextField) {
        commit(textField)
    }

    private func commit(_ textField: UITextField) {
        guard let textField = textField as? ScribbleCellTextField else { return }
        let coordinate = textField.coordinate
        guard let state = cellStates[coordinate] else { return }
        onSelect(coordinate)

        guard let letter = Self.lastLetter(in: textField.text ?? "") else {
            textField.text = ""
            state.scribbleCandidate = nil
            scheduleResolution(for: coordinate)
            return
        }

        textField.text = letter
        state.scribbleCandidate = letter
        scheduleResolution(for: coordinate)
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if let textField = textField as? ScribbleCellTextField {
            onRecognizedLetter(nil, textField.coordinate)
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard let textField = textField as? ScribbleCellTextField else { return }
        textField.text = recognizedLetters[textField.coordinate] ?? ""
        onSelect(textField.coordinate)
        selectAllText(in: textField)
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let textField = textField as? ScribbleCellTextField else {
            return true
        }

        if string.isEmpty {
            textField.text = ""
            onSelect(textField.coordinate)
            cellStates[textField.coordinate]?.scribbleCandidate = nil
            cellStates[textField.coordinate]?.clearInk()
            onRecognizedLetter(nil, textField.coordinate)
            return false
        }

        guard let letter = Self.lastLetter(in: string) ?? Self.lastLetter(in: textField.text ?? "") else {
            textField.text = ""
            onSelect(textField.coordinate)
            cellStates[textField.coordinate]?.scribbleCandidate = nil
            scheduleResolution(for: textField.coordinate)
            return false
        }

        textField.text = letter
        onSelect(textField.coordinate)
        cellStates[textField.coordinate]?.scribbleCandidate = letter
        scheduleResolution(for: textField.coordinate)
        return false
    }

    private func focusTextField(at coordinate: CrosswordCoordinate) {
        guard let textField = cellStates[coordinate]?.textField else { return }
        textField.text = recognizedLetters[coordinate] ?? ""
        textField.becomeFirstResponder()
        selectAllText(in: textField)
    }

    private func selectAllText(in textField: UITextField) {
        guard let start = textField.beginningOfDocument as UITextPosition?,
              let end = textField.endOfDocument as UITextPosition? else {
            return
        }

        textField.selectedTextRange = textField.textRange(from: start, to: end)
    }

    @objc private func handlePencilPan(_ recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: self)

        switch recognizer.state {
        case .began:
            guard let coordinate = coordinate(at: location) else { return }
            finishActiveInkIfNeeded(excluding: coordinate)
            activeInkCoordinate = coordinate
            activeStrokePoints = [pointInCell(from: location, coordinate: coordinate)]
            onSelect(coordinate)
            focusTextField(at: coordinate)
            cellStates[coordinate]?.pendingTask?.cancel()
            cellStates[coordinate]?.scribbleCandidate = nil
            updateDrawing(for: coordinate)
        case .changed:
            guard let coordinate = activeInkCoordinate else { return }
            activeStrokePoints.append(pointInCell(from: location, coordinate: coordinate))
            updateDrawing(for: coordinate)
            scheduleResolution(for: coordinate)
        case .ended, .cancelled, .failed:
            guard let coordinate = activeInkCoordinate else { return }
            activeStrokePoints.append(pointInCell(from: location, coordinate: coordinate))
            updateDrawing(for: coordinate)
            if activeStrokePoints.count > 1 {
                cellStates[coordinate]?.strokes.append(activeStrokePoints)
            }
            scheduleResolution(for: coordinate)
            activeInkCoordinate = nil
            activeStrokePoints = []
        default:
            break
        }
    }

    private func finishActiveInkIfNeeded(excluding coordinate: CrosswordCoordinate) {
        guard let activeInkCoordinate, activeInkCoordinate != coordinate else { return }
        scheduleResolution(for: activeInkCoordinate, delay: 0.05)
        self.activeInkCoordinate = nil
        activeStrokePoints = []
    }

    private func coordinate(at location: CGPoint) -> CrosswordCoordinate? {
        let cellSize = min(bounds.width, bounds.height) / CGFloat(puzzle.size)
        guard cellSize > 0 else { return nil }
        let coordinate = CrosswordCoordinate(
            row: Int(location.y / cellSize),
            column: Int(location.x / cellSize)
        )

        return puzzle.isPlayable(coordinate) ? coordinate : nil
    }

    private func pointInCell(from location: CGPoint, coordinate: CrosswordCoordinate) -> CGPoint {
        let cellSize = min(bounds.width, bounds.height) / CGFloat(puzzle.size)
        let cellFrame = frame(for: coordinate, cellSize: cellSize)
        let x = min(max(location.x - cellFrame.minX, 0), cellFrame.width)
        let y = min(max(location.y - cellFrame.minY, 0), cellFrame.height)
        return CGPoint(x: x, y: y)
    }

    private func updateDrawing(for coordinate: CrosswordCoordinate) {
        guard let state = cellStates[coordinate], activeStrokePoints.count > 1 else { return }
        let drawing = Self.drawing(from: state.strokes + [activeStrokePoints])
        state.drawing = drawing
        state.canvas.drawing = drawing
    }

    private func scheduleResolution(for coordinate: CrosswordCoordinate, delay: TimeInterval = 0.95) {
        guard let state = cellStates[coordinate] else { return }
        state.pendingTask?.cancel()
        state.recognitionGeneration += 1
        let generation = state.recognitionGeneration

        let task = DispatchWorkItem { [weak self, weak state] in
            guard let self, let state else { return }
            let drawing = state.drawing
            Self.recognizeLetter(in: drawing) { [weak self, weak state] ocrLetter in
                DispatchQueue.main.async {
                    guard let self,
                          let state,
                          self.cellStates[coordinate] === state,
                          state.recognitionGeneration == generation else {
                        return
                    }
                    state.pendingTask = nil
                    self.resolve(coordinate: coordinate, ocrLetter: ocrLetter)
                }
            }
        }

        state.pendingTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
    }

    private func resolve(coordinate: CrosswordCoordinate, ocrLetter: String?) {
        guard let state = cellStates[coordinate] else { return }
        let scribbleLetter = state.scribbleCandidate
        let resolvedLetter: String?

        switch (scribbleLetter, ocrLetter) {
        case let (scribble?, ocr?) where scribble == ocr:
            resolvedLetter = scribble
        case let (scribble?, nil):
            resolvedLetter = scribble
        case let (nil, ocr?):
            resolvedLetter = ocr
        default:
            resolvedLetter = nil
        }

        state.clearRecognition()
        state.textField.text = resolvedLetter ?? ""
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

    private static func drawing(from strokes: [[CGPoint]]) -> PKDrawing {
        let ink = PKInk(.pen, color: writingInk)
        let pkStrokes = strokes.compactMap { points -> PKStroke? in
            guard points.count > 1 else { return nil }
            let strokePoints = points.enumerated().map { index, point in
                PKStrokePoint(
                    location: point,
                    timeOffset: TimeInterval(index) * 0.015,
                    size: CGSize(width: strokeWidth, height: strokeWidth),
                    opacity: 1,
                    force: 1,
                    azimuth: 0,
                    altitude: .pi / 2
                )
            }
            let path = PKStrokePath(controlPoints: strokePoints, creationDate: Date())
            return PKStroke(ink: ink, path: path)
        }

        return PKDrawing(strokes: pkStrokes)
    }

    private static func recognizeLetter(in drawing: PKDrawing, completion: @escaping (String?) -> Void) {
        guard !drawing.bounds.isEmpty,
              let cgImage = renderedRecognitionImage(from: drawing).cgImage else {
            completion(nil)
            return
        }

        let request = VNRecognizeTextRequest { request, _ in
            let candidates = (request.results as? [VNRecognizedTextObservation])?
                .flatMap { observation in
                    observation.topCandidates(3).map(\.string)
                } ?? []
            completion(candidates.compactMap(lastLetter(in:)).first)
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.minimumTextHeight = 0.01
        request.recognitionLanguages = ["en-US"]
        request.customWords = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz").map(String.init)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
            } catch {
                completion(nil)
            }
        }
    }

    private static func renderedRecognitionImage(from drawing: PKDrawing) -> UIImage {
        let sideLength: CGFloat = 256
        let padding: CGFloat = 28
        let drawingBounds = drawing.bounds.insetBy(dx: -16, dy: -16)
        let sourceImage = drawing.image(from: drawingBounds, scale: 4)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: sideLength, height: sideLength), format: format)

        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: sideLength, height: sideLength))

            let available = sideLength - padding * 2
            let scale = min(available / max(sourceImage.size.width, 1), available / max(sourceImage.size.height, 1))
            let imageSize = CGSize(width: sourceImage.size.width * scale, height: sourceImage.size.height * scale)
            let imageOrigin = CGPoint(x: (sideLength - imageSize.width) / 2, y: (sideLength - imageSize.height) / 2)
            sourceImage.draw(in: CGRect(origin: imageOrigin, size: imageSize), blendMode: .normal, alpha: 1)
        }
    }

    private static let strokeWidth: CGFloat = 8
    private static let writingInk = UIColor(red: 0.05, green: 0.06, blue: 0.06, alpha: 1)
}

private final class ScribbleCellTextField: UITextField {
    let coordinate: CrosswordCoordinate

    init(coordinate: CrosswordCoordinate) {
        self.coordinate = coordinate
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        false
    }
}

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
    let textField: ScribbleCellTextField
    let canvas: CellCanvasView
    var scribbleCandidate: String?
    var strokes: [[CGPoint]] = []
    var drawing = PKDrawing()
    var pendingTask: DispatchWorkItem?
    var recognitionGeneration = 0

    init(coordinate: CrosswordCoordinate, textField: ScribbleCellTextField, canvas: CellCanvasView) {
        self.coordinate = coordinate
        self.textField = textField
        self.canvas = canvas
    }

    func clearInk() {
        strokes = []
        drawing = PKDrawing()
        canvas.drawing = drawing
        pendingTask?.cancel()
        pendingTask = nil
        recognitionGeneration += 1
    }

    func clearRecognition() {
        scribbleCandidate = nil
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
    @Binding var direction: CrosswordDirection
    let moveToPreviousClue: () -> Void
    let moveToNextClue: () -> Void
    let selectClue: (CrosswordClue, CrosswordDirection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Direction", selection: $direction) {
                ForEach(CrosswordDirection.allCases) { direction in
                    Text(direction.title).tag(direction)
                }
            }
            .pickerStyle(.segmented)

            CurrentClueCard(
                clue: puzzle.clue(containing: selectedCell, direction: direction),
                direction: direction
            )

            HStack(spacing: 10) {
                Button(action: moveToPreviousClue) {
                    Label("Previous", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.primaryAction)

                Button(action: moveToNextClue) {
                    Label("Next", systemImage: "chevron.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.primaryAction)
            }

            Divider()
                .overlay(Color.hairline)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    ClueList(
                        title: "Across",
                        direction: .across,
                        clues: puzzle.acrossClues,
                        selectedCell: selectedCell,
                        selectClue: selectClue
                    )
                    ClueList(
                        title: "Down",
                        direction: .down,
                        clues: puzzle.downClues,
                        selectedCell: selectedCell,
                        selectClue: selectClue
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

        }
        .padding(18)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
        .shadow(color: Color.shadow.opacity(0.12), radius: 10, x: 0, y: 3)
    }
}

private struct PuzzleActionsView: View {
    let checkResult: PuzzleCheckResult?
    let checkPuzzle: () -> Void
    let restartPuzzle: () -> Void
    let startNewPuzzle: () -> Void
    let showAnswers: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Menu {
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
                Label("Puzzle Menu", systemImage: "line.3.horizontal")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.primaryAction)

            Button(action: checkPuzzle) {
                Label("Check Puzzle", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.primaryAction)

            if let checkResult {
                PuzzleCheckCard(result: checkResult)
            }
        }
    }
}

private struct CompletionView: View {
    @Binding var selectedSize: Int
    let puzzleSizes: [Int]
    let showAnotherPuzzle: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 46, weight: .bold))
                .foregroundStyle(Color.successInk)

            VStack(spacing: 8) {
                Text("Congrats")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ink)

                Text("You completed the crossword.")
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.softInk)
            }

            Picker("Puzzle size", selection: $selectedSize) {
                ForEach(puzzleSizes, id: \.self) { size in
                    Text("\(size) x \(size)").tag(size)
                }
            }
            .pickerStyle(.segmented)

            Button(action: showAnotherPuzzle) {
                Label("Show Me Another Puzzle", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.primaryAction)
        }
        .padding(28)
        .background(Color.appBackground)
        .presentationDetents([.height(330)])
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
                Text("Current clue")
                .font(.system(size: 13, weight: .bold, design: .serif))
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(Color.primaryAction)

            if let clue {
                Text("\(clue.number) \(direction.title) · \(clue.answer.count) letters")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.softInk)

                Text(clue.text)
                    .font(.system(size: 21, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Tap a white square to start writing.")
                    .font(.system(size: 19, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.softInk)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primaryContainer.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ClueList: View {
    let title: String
    let direction: CrosswordDirection
    let clues: [CrosswordClue]
    let selectedCell: CrosswordCoordinate
    let selectClue: (CrosswordClue, CrosswordDirection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundStyle(Color.ink)

            ForEach(clues, id: \.id) { clue in
                Button {
                    selectClue(clue, direction)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(clue.number).")
                            .font(.system(size: 13, weight: .heavy, design: .serif))
                            .foregroundStyle(Color.softInk)
                            .frame(width: 26, alignment: .trailing)

                        Text(clue.text)
                            .font(.system(size: 14, weight: .medium, design: .serif))
                            .foregroundStyle(clue.cells.contains(selectedCell) ? Color.ink : Color.softInk)

                        Spacer(minLength: 6)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct PaperBackground: View {
    var body: some View {
        Color.appBackground
        .ignoresSafeArea()
    }
}

private struct CrosswordPuzzle {
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

    static func generated(size: Int) -> CrosswordPuzzle {
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

private enum PuzzleCheckResult: Equatable {
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

private struct CrosswordClue: Identifiable {
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

private struct CrosswordCoordinate: Hashable {
    let row: Int
    let column: Int
}

private enum CrosswordDirection: String, CaseIterable, Identifiable {
    case across
    case down

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

private extension Color {
    static let appBackground = Color(red: 0.97, green: 0.98, blue: 0.97)
    static let surface = Color(red: 1.00, green: 1.00, blue: 1.00)
    static let surfaceVariant = Color(red: 0.91, green: 0.94, blue: 0.92)
    static let ink = Color(red: 0.10, green: 0.13, blue: 0.13)
    static let softInk = Color(red: 0.39, green: 0.43, blue: 0.42)
    static let primaryAction = Color(red: 0.00, green: 0.42, blue: 0.42)
    static let primaryContainer = Color(red: 0.74, green: 0.93, blue: 0.90)
    static let secondaryContainer = Color(red: 0.88, green: 0.92, blue: 0.89)
    static let block = Color(red: 0.15, green: 0.20, blue: 0.20)
    static let gridLine = Color(red: 0.72, green: 0.76, blue: 0.74)
    static let hairline = Color(red: 0.78, green: 0.82, blue: 0.80).opacity(0.70)
    static let shadow = Color(red: 0.06, green: 0.09, blue: 0.09)
    static let warningInk = Color(red: 0.49, green: 0.34, blue: 0.06)
    static let warningSurface = Color(red: 0.98, green: 0.90, blue: 0.68)
    static let successInk = Color(red: 0.00, green: 0.39, blue: 0.20)
    static let successSurface = Color(red: 0.77, green: 0.91, blue: 0.80)
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
