import Foundation

struct CrosswordEntry: Decodable, Hashable {
    let answer: String
    let clue: String
    let score: Int

    var normalizedAnswer: String {
        answer.uppercased().filter { $0 >= "A" && $0 <= "Z" }
    }
}

struct CrosswordTemplate {
    let size: Int
    let rows: [String]
    let name: String

    var blockCells: Set<CrosswordCoordinate> {
        var cells: Set<CrosswordCoordinate> = []

        for (rowIndex, row) in rows.enumerated() {
            for (columnIndex, character) in row.enumerated() where character == "#" {
                cells.insert(CrosswordCoordinate(row: rowIndex, column: columnIndex))
            }
        }

        return cells
    }

    static func templates(for size: Int) -> [CrosswordTemplate] {
        switch size {
        case 5:
            [
                CrosswordTemplate(
                    size: 5,
                    rows: Array(repeating: "_____", count: 5),
                    name: "open-5"
                )
            ]
        case 10:
            [
                CrosswordTemplate(
                    size: 10,
                    rows: Array(repeating: "_____#####", count: 5)
                        + Array(repeating: "#####_____", count: 5),
                    name: "paired-5"
                )
            ]
        case 15:
            [
                CrosswordTemplate(
                    size: 15,
                    rows: Array(repeating: "_____##########", count: 5)
                        + Array(repeating: "#####_____#####", count: 5)
                        + Array(repeating: "##########_____", count: 5),
                    name: "triple-5"
                )
            ]
        case 20:
            [
                CrosswordTemplate(
                    size: 20,
                    rows: Array(repeating: "_____###############", count: 5)
                        + Array(repeating: "#####_____##########", count: 5)
                        + Array(repeating: "##########_____#####", count: 5)
                        + Array(repeating: "###############_____", count: 5),
                    name: "quad-5"
                )
            ]
        default:
            []
        }
    }
}

struct CrosswordSeedPuzzle: Decodable {
    let size: Int
    let difficulty: PuzzleDifficulty
    let sourceName: String
    let solutionRows: [String]
    let clueBank: [String: String]

    enum CodingKeys: String, CodingKey {
        case size
        case difficulty
        case sourceName
        case solutionRows
        case clueBank = "clues"
    }

    var normalizedClueBank: [String: String] {
        Dictionary(uniqueKeysWithValues: clueBank.map { answer, clue in
            (answer.uppercased(), clue)
        })
    }

    func makePuzzle() -> CrosswordPuzzle? {
        guard validationErrors().isEmpty else { return nil }
        return CrosswordPuzzle(solutionRows: solutionRows, clueBank: normalizedClueBank)
    }

    func validationErrors() -> [String] {
        var errors: [String] = []

        guard solutionRows.count == size else {
            return ["\(sourceName) has \(solutionRows.count) rows for size \(size)"]
        }

        for row in solutionRows {
            if row.count != size {
                errors.append("\(sourceName) has a row with \(row.count) columns")
            }

            if row.contains(where: { character in
                character != "#" && !(character >= "A" && character <= "Z")
            }) {
                errors.append("\(sourceName) contains a non A-Z/# character")
            }
        }

        let entries = Self.entries(in: solutionRows)
        let clueAnswers = Set(normalizedClueBank.keys)
        for entry in entries where entry.answer.count > 1 {
            if normalizedClueBank[entry.answer]?.isEmpty ?? true {
                errors.append("\(sourceName) is missing a clue for \(entry.answer)")
            }
        }

        let entryAnswers = Set(entries.map(\.answer))
        let unusedClues = clueAnswers.subtracting(entryAnswers)
        if !unusedClues.isEmpty {
            errors.append("\(sourceName) has unused clues: \(unusedClues.sorted().joined(separator: ", "))")
        }

        let acrossAnswers = Set(entries.filter { $0.direction == .across }.map(\.answer))
        let downAnswers = Set(entries.filter { $0.direction == .down }.map(\.answer))
        let duplicatedDirectionAnswers = acrossAnswers.intersection(downAnswers)
        if !duplicatedDirectionAnswers.isEmpty {
            errors.append("\(sourceName) repeats across/down answers: \(duplicatedDirectionAnswers.sorted().joined(separator: ", "))")
        }

        let sameStartEntries = Dictionary(grouping: entries, by: \.start)
        for startEntries in sameStartEntries.values where startEntries.count > 1 {
            let answers = Set(startEntries.map(\.answer))
            if answers.count < startEntries.count {
                errors.append("\(sourceName) has a same-number across/down duplicate answer")
            }
        }

        return errors
    }

    private static func entries(in rows: [String]) -> [SeedEntry] {
        guard let size = rows.first?.count else { return [] }
        var entries: [SeedEntry] = []

        for row in 0..<rows.count {
            for column in 0..<size {
                let coordinate = CrosswordCoordinate(row: row, column: column)
                guard letter(at: coordinate, rows: rows) != nil else { continue }

                let startsAcross = letter(at: CrosswordCoordinate(row: row, column: column - 1), rows: rows) == nil
                    && letter(at: CrosswordCoordinate(row: row, column: column + 1), rows: rows) != nil
                if startsAcross {
                    entries.append(entry(start: coordinate, direction: .across, rows: rows))
                }

                let startsDown = letter(at: CrosswordCoordinate(row: row - 1, column: column), rows: rows) == nil
                    && letter(at: CrosswordCoordinate(row: row + 1, column: column), rows: rows) != nil
                if startsDown {
                    entries.append(entry(start: coordinate, direction: .down, rows: rows))
                }
            }
        }

        return entries.filter { $0.answer.count > 1 }
    }

    private static func entry(start: CrosswordCoordinate, direction: CrosswordDirection, rows: [String]) -> SeedEntry {
        var cursor = start
        var answer = ""

        while let letter = letter(at: cursor, rows: rows) {
            answer.append(letter)
            cursor = direction == .across
                ? CrosswordCoordinate(row: cursor.row, column: cursor.column + 1)
                : CrosswordCoordinate(row: cursor.row + 1, column: cursor.column)
        }

        return SeedEntry(start: start, direction: direction, answer: answer)
    }

    private static func letter(at coordinate: CrosswordCoordinate, rows: [String]) -> Character? {
        guard coordinate.row >= 0,
              coordinate.row < rows.count,
              coordinate.column >= 0,
              coordinate.column < rows[coordinate.row].count else {
            return nil
        }

        let row = rows[coordinate.row]
        let index = row.index(row.startIndex, offsetBy: coordinate.column)
        let character = row[index]
        return character == "#" ? nil : character
    }
}

private struct SeedEntry {
    let start: CrosswordCoordinate
    let direction: CrosswordDirection
    let answer: String
}

enum CrosswordSeedLibrary {
    static func puzzle(size: Int, difficulty: PuzzleDifficulty, seed: Int?) -> CrosswordPuzzle? {
        let matchingSize = validSeeds.filter { $0.size == size }
        guard !matchingSize.isEmpty else { return nil }

        let difficultyOrder = [difficulty, .medium, .easy] + PuzzleDifficulty.allCases
        for selectedDifficulty in unique(difficultyOrder) {
            let matches = matchingSize.filter { $0.difficulty == selectedDifficulty }
            guard !matches.isEmpty else { continue }
            return select(from: matches, seed: seed)?.makePuzzle()
        }

        return select(from: matchingSize, seed: seed)?.makePuzzle()
    }

    private static let validSeeds: [CrosswordSeedPuzzle] = loadSeeds().filter { seed in
        seed.validationErrors().isEmpty
    }

    private static func loadSeeds() -> [CrosswordSeedPuzzle] {
        guard let url = Bundle.main.url(forResource: "crossword_seed_puzzles", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let seeds = try? JSONDecoder().decode([CrosswordSeedPuzzle].self, from: data),
              !seeds.isEmpty else {
            return fallbackSeeds
        }

        return seeds
    }

    private static func select(from seeds: [CrosswordSeedPuzzle], seed: Int?) -> CrosswordSeedPuzzle? {
        guard !seeds.isEmpty else { return nil }
        let seedValue = abs(seed ?? Int(Date().timeIntervalSince1970))
        return seeds[seedValue % seeds.count]
    }

    private static func unique(_ difficulties: [PuzzleDifficulty]) -> [PuzzleDifficulty] {
        var seen: Set<PuzzleDifficulty> = []
        return difficulties.filter { seen.insert($0).inserted }
    }

    private static let fallbackSeeds: [CrosswordSeedPuzzle] = [
        CrosswordSeedPuzzle(
            size: 5,
            difficulty: .easy,
            sourceName: "fallback-easy-5",
            solutionRows: ["ABOUT", "H#C#I", "EVENT", "A#A#L", "DANCE"],
            clueBank: [
                "ABOUT": "Concerning",
                "EVENT": "Something that happens",
                "DANCE": "Move rhythmically to music",
                "OCEAN": "A vast body of salt water",
                "AHEAD": "In front",
                "TITLE": "Name of a work"
            ]
        )
    ]
}

struct CrosswordDictionary {
    let entries: [CrosswordEntry]
    private let entriesByLength: [Int: [CrosswordEntry]]
    private let cluesByAnswer: [String: String]

    init(entries: [CrosswordEntry]) {
        let normalizedEntries = entries
            .map { entry in
                CrosswordEntry(answer: entry.normalizedAnswer, clue: entry.clue, score: entry.score)
            }
            .filter { !$0.normalizedAnswer.isEmpty }

        self.entries = normalizedEntries
        entriesByLength = Dictionary(grouping: normalizedEntries, by: { $0.normalizedAnswer.count })
            .mapValues { entries in
                entries.sorted {
                    if $0.score == $1.score {
                        return $0.normalizedAnswer < $1.normalizedAnswer
                    }

                    return $0.score > $1.score
                }
            }

        cluesByAnswer = Dictionary(uniqueKeysWithValues: normalizedEntries.map { ($0.normalizedAnswer, $0.clue) })
    }

    func entries(length: Int) -> [CrosswordEntry] {
        entriesByLength[length] ?? []
    }

    func entry(for answer: String) -> CrosswordEntry? {
        entries.first { $0.normalizedAnswer == answer }
    }

    func clueBank(for answers: Set<String>) -> [String: String] {
        Dictionary(uniqueKeysWithValues: answers.map { answer in
            (answer, cluesByAnswer[answer] ?? "\(answer.count)-letter crossword answer")
        })
    }

    static let bundled = CrosswordDictionary(entries: Self.loadBundledEntries())

    private static func loadBundledEntries() -> [CrosswordEntry] {
        guard let url = Bundle.main.url(forResource: "crossword_entries", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([CrosswordEntry].self, from: data),
              !entries.isEmpty else {
            return fallbackEntries
        }

        return entries
    }

    private static let fallbackEntries: [CrosswordEntry] = [
        CrosswordEntry(answer: "HEART", clue: "It beats in your chest", score: 95),
        CrosswordEntry(answer: "EMBER", clue: "Glowing piece left after a fire", score: 82),
        CrosswordEntry(answer: "ABUSE", clue: "Treat cruelly or misuse", score: 70),
        CrosswordEntry(answer: "RESIN", clue: "Sticky tree secretion", score: 75),
        CrosswordEntry(answer: "TREND", clue: "General direction things are moving", score: 88),
        CrosswordEntry(answer: "SATOR", clue: "First word of an ancient Latin word square", score: 45),
        CrosswordEntry(answer: "AREPO", clue: "Second word of an ancient Latin word square", score: 35),
        CrosswordEntry(answer: "TENET", clue: "A principle or belief", score: 86),
        CrosswordEntry(answer: "OPERA", clue: "A dramatic work set to music", score: 82),
        CrosswordEntry(answer: "ROTAS", clue: "Turns or schedules, in British usage", score: 50),
        CrosswordEntry(answer: "AALII", clue: "A tropical shrub or small tree", score: 20),
        CrosswordEntry(answer: "ABORD", clue: "To approach or accost, archaically", score: 18),
        CrosswordEntry(answer: "LOYAL", clue: "Faithful and devoted", score: 90),
        CrosswordEntry(answer: "IRATE", clue: "Very angry", score: 84),
        CrosswordEntry(answer: "IDLER", clue: "One avoiding work", score: 72),
        CrosswordEntry(answer: "BLAST", clue: "A sudden burst or explosion", score: 95),
        CrosswordEntry(answer: "LUNCH", clue: "A midday meal", score: 95),
        CrosswordEntry(answer: "ANGER", clue: "A strong feeling of displeasure", score: 95),
        CrosswordEntry(answer: "SCENE", clue: "A place where action happens", score: 95),
        CrosswordEntry(answer: "THREE", clue: "One more than two", score: 95),
        CrosswordEntry(answer: "THREW", clue: "Sent something through the air", score: 92)
    ]
}

struct WordIndex {
    private let entriesByAnswer: [String: CrosswordEntry]
    private let entriesByLength: [Int: [String]]
    private let positionLetterIndex: [Int: [Int: [Character: Set<String>]]]

    init(entries: [CrosswordEntry]) {
        var answerMap: [String: CrosswordEntry] = [:]
        var lengthMap: [Int: [String]] = [:]
        var index: [Int: [Int: [Character: Set<String>]]] = [:]

        for entry in entries {
            let answer = entry.normalizedAnswer
            guard !answer.isEmpty else { continue }

            answerMap[answer] = entry
            lengthMap[answer.count, default: []].append(answer)

            for (position, letter) in answer.enumerated() {
                index[answer.count, default: [:]][position, default: [:]][letter, default: []].insert(answer)
            }
        }

        entriesByAnswer = answerMap
        entriesByLength = lengthMap.mapValues { answers in
            answers.sorted { left, right in
                let leftScore = answerMap[left]?.score ?? 0
                let rightScore = answerMap[right]?.score ?? 0
                if leftScore == rightScore {
                    return left < right
                }

                return leftScore > rightScore
            }
        }
        positionLetterIndex = index
    }

    func entries(length: Int, constraints: [Int: Character], usedAnswers: Set<String>) -> [CrosswordEntry] {
        guard let allAnswers = entriesByLength[length] else { return [] }

        let matchingAnswers: Set<String>
        if constraints.isEmpty {
            matchingAnswers = Set(allAnswers)
        } else {
            var matches: Set<String>?
            for (position, letter) in constraints {
                guard let answers = positionLetterIndex[length]?[position]?[letter] else {
                    return []
                }

                matches = matches.map { $0.intersection(answers) } ?? answers
            }

            matchingAnswers = matches ?? []
        }

        return allAnswers.compactMap { answer in
            guard matchingAnswers.contains(answer),
                  !usedAnswers.contains(answer),
                  let entry = entriesByAnswer[answer] else {
                return nil
            }

            return entry
        }
    }

    func clueBank(for answers: Set<String>) -> [String: String] {
        Dictionary(uniqueKeysWithValues: answers.compactMap { answer in
            guard let clue = entriesByAnswer[answer]?.clue, !clue.isEmpty else { return nil }
            return (answer, clue)
        })
    }
}

struct CrosswordPlacement {
    let entry: CrosswordEntry
    let start: CrosswordCoordinate
    let direction: CrosswordDirection

    var answer: String {
        entry.normalizedAnswer
    }

    var cells: [CrosswordCoordinate] {
        Self.cells(start: start, direction: direction, length: answer.count)
    }

    static func cells(start: CrosswordCoordinate, direction: CrosswordDirection, length: Int) -> [CrosswordCoordinate] {
        (0..<length).map { offset in
            direction == .across
                ? CrosswordCoordinate(row: start.row, column: start.column + offset)
                : CrosswordCoordinate(row: start.row + offset, column: start.column)
        }
    }
}

struct PlacementCandidate {
    let start: CrosswordCoordinate
    let direction: CrosswordDirection
    let length: Int
    let constraints: [Int: Character]
    let score: Int
}

private struct GeneratedCrosswordBoard {
    private(set) var letters: [CrosswordCoordinate: Character] = [:]
    private(set) var placements: [CrosswordPlacement] = []
    private(set) var usedAnswers: Set<String> = []

    var isEmpty: Bool {
        letters.isEmpty
    }

    var answerCount: Int {
        usedAnswers.count
    }

    mutating func place(_ placement: CrosswordPlacement) {
        let answer = Array(placement.answer)
        for (index, coordinate) in placement.cells.enumerated() {
            letters[coordinate] = answer[index]
        }

        placements.append(placement)
        usedAnswers.insert(placement.answer)
    }

    func canPlace(_ entry: CrosswordEntry, start: CrosswordCoordinate, direction: CrosswordDirection, targetSize: Int) -> Bool {
        let answer = Array(entry.normalizedAnswer)
        guard !answer.isEmpty,
              answer.count <= targetSize,
              !usedAnswers.contains(entry.normalizedAnswer) else {
            return false
        }

        let cells = CrosswordPlacement.cells(start: start, direction: direction, length: answer.count)
        guard fitsWithinSearchBounds(cells, targetSize: targetSize) else { return false }

        var crossingCount = 0
        for (index, coordinate) in cells.enumerated() {
            if let existing = letters[coordinate] {
                guard existing == answer[index] else { return false }
                crossingCount += 1
                continue
            }

            let adjacent = perpendicularNeighbors(of: coordinate, direction: direction)
            if adjacent.contains(where: { letters[$0] != nil }) {
                return false
            }
        }

        guard isEmpty || crossingCount > 0 else { return false }

        let before = coordinate(before: start, direction: direction)
        let after = coordinate(after: cells[cells.count - 1], direction: direction)
        guard letters[before] == nil, letters[after] == nil else { return false }

        return true
    }

    func candidates(from placement: CrosswordPlacement, profile: CrosswordGenerationProfile) -> [PlacementCandidate] {
        let answer = Array(placement.answer)
        let crossingDirection = placement.direction == .across ? CrosswordDirection.down : .across
        var candidates: [PlacementCandidate] = []

        for (letterIndex, coordinate) in placement.cells.enumerated() {
            for length in profile.candidateLengths where length >= 2 && length <= profile.size {
                for crossingIndex in 0..<length {
                    let start = crossingDirection == .across
                        ? CrosswordCoordinate(row: coordinate.row, column: coordinate.column - crossingIndex)
                        : CrosswordCoordinate(row: coordinate.row - crossingIndex, column: coordinate.column)
                    guard crossingIndex < length else { continue }

                    let cells = CrosswordPlacement.cells(start: start, direction: crossingDirection, length: length)
                    guard fitsWithinSearchBounds(cells, targetSize: profile.size) else { continue }

                    let constraints = constraints(for: cells)
                    guard constraints[crossingIndex] == answer[letterIndex] else { continue }

                    let score = constraints.count * 200 + length * 20
                    candidates.append(
                        PlacementCandidate(
                            start: start,
                            direction: crossingDirection,
                            length: length,
                            constraints: constraints,
                            score: score
                        )
                    )
                }
            }
        }

        return candidates
    }

    func normalizedRows(size: Int) -> [String]? {
        guard let bounds = bounds else { return nil }
        let height = bounds.maxRow - bounds.minRow + 1
        let width = bounds.maxColumn - bounds.minColumn + 1
        guard height <= size, width <= size else { return nil }

        let rowOffset = -bounds.minRow + (size - height) / 2
        let columnOffset = -bounds.minColumn + (size - width) / 2
        var rows = Array(repeating: Array(repeating: Character("#"), count: size), count: size)

        for (coordinate, letter) in letters {
            let row = coordinate.row + rowOffset
            let column = coordinate.column + columnOffset
            guard row >= 0, row < size, column >= 0, column < size else { return nil }
            rows[row][column] = letter
        }

        return rows.map { String($0) }
    }

    func isConnected() -> Bool {
        guard let first = letters.keys.first else { return false }
        let targets = Set(letters.keys)
        var visited: Set<CrosswordCoordinate> = [first]
        var queue = [first]

        while !queue.isEmpty {
            let current = queue.removeFirst()
            for neighbor in orthogonalNeighbors(of: current) where targets.contains(neighbor) && !visited.contains(neighbor) {
                visited.insert(neighbor)
                queue.append(neighbor)
            }
        }

        return visited.count == targets.count
    }

    private var bounds: (minRow: Int, maxRow: Int, minColumn: Int, maxColumn: Int)? {
        guard let first = letters.keys.first else { return nil }
        return letters.keys.reduce((first.row, first.row, first.column, first.column)) { bounds, coordinate in
            (
                min(bounds.0, coordinate.row),
                max(bounds.1, coordinate.row),
                min(bounds.2, coordinate.column),
                max(bounds.3, coordinate.column)
            )
        }
    }

    private func constraints(for cells: [CrosswordCoordinate]) -> [Int: Character] {
        var constraints: [Int: Character] = [:]
        for (index, coordinate) in cells.enumerated() {
            if let letter = letters[coordinate] {
                constraints[index] = letter
            }
        }

        return constraints
    }

    private func fitsWithinSearchBounds(_ cells: [CrosswordCoordinate], targetSize: Int) -> Bool {
        guard !cells.isEmpty else { return false }

        var projected = letters
        for coordinate in cells {
            projected[coordinate] = projected[coordinate] ?? "A"
        }

        guard let first = projected.keys.first else { return false }
        let bounds = projected.keys.reduce((first.row, first.row, first.column, first.column)) { bounds, coordinate in
            (
                min(bounds.0, coordinate.row),
                max(bounds.1, coordinate.row),
                min(bounds.2, coordinate.column),
                max(bounds.3, coordinate.column)
            )
        }

        return bounds.1 - bounds.0 + 1 <= targetSize && bounds.3 - bounds.2 + 1 <= targetSize
    }

    private func perpendicularNeighbors(of coordinate: CrosswordCoordinate, direction: CrosswordDirection) -> [CrosswordCoordinate] {
        if direction == .across {
            return [
                CrosswordCoordinate(row: coordinate.row - 1, column: coordinate.column),
                CrosswordCoordinate(row: coordinate.row + 1, column: coordinate.column)
            ]
        }

        return [
            CrosswordCoordinate(row: coordinate.row, column: coordinate.column - 1),
            CrosswordCoordinate(row: coordinate.row, column: coordinate.column + 1)
        ]
    }

    private func coordinate(before coordinate: CrosswordCoordinate, direction: CrosswordDirection) -> CrosswordCoordinate {
        direction == .across
            ? CrosswordCoordinate(row: coordinate.row, column: coordinate.column - 1)
            : CrosswordCoordinate(row: coordinate.row - 1, column: coordinate.column)
    }

    private func coordinate(after coordinate: CrosswordCoordinate, direction: CrosswordDirection) -> CrosswordCoordinate {
        direction == .across
            ? CrosswordCoordinate(row: coordinate.row, column: coordinate.column + 1)
            : CrosswordCoordinate(row: coordinate.row + 1, column: coordinate.column)
    }

    private func orthogonalNeighbors(of coordinate: CrosswordCoordinate) -> [CrosswordCoordinate] {
        [
            CrosswordCoordinate(row: coordinate.row - 1, column: coordinate.column),
            CrosswordCoordinate(row: coordinate.row + 1, column: coordinate.column),
            CrosswordCoordinate(row: coordinate.row, column: coordinate.column - 1),
            CrosswordCoordinate(row: coordinate.row, column: coordinate.column + 1)
        ]
    }
}

private struct CrosswordGenerationProfile {
    let size: Int
    let targetAnswers: Int
    let minimumAnswers: Int
    let seedLengths: [Int]
    let candidateLengths: [Int]
    let candidateTryLimit: Int

    init(size: Int, difficulty: PuzzleDifficulty) {
        self.size = size

        switch size {
        case 0...5:
            targetAnswers = difficulty == .hard ? 8 : 6
            minimumAnswers = 5
            seedLengths = Array(stride(from: min(size, 8), through: 4, by: -1))
            candidateLengths = Array(stride(from: min(size, 7), through: 2, by: -1))
            candidateTryLimit = 18
        case 6...10:
            targetAnswers = difficulty == .hard ? 18 : 14
            minimumAnswers = 10
            seedLengths = Array(stride(from: min(size, 10), through: 5, by: -1))
            candidateLengths = Array(stride(from: min(size, 10), through: difficulty == .easy ? 3 : 2, by: -1))
            candidateTryLimit = 22
        default:
            targetAnswers = difficulty == .hard ? 34 : 26
            minimumAnswers = 16
            seedLengths = Array(stride(from: min(size, 12), through: 6, by: -1))
            candidateLengths = Array(stride(from: min(size, 12), through: difficulty == .easy ? 4 : 3, by: -1))
            candidateTryLimit = 28
        }
    }
}

private struct FastCrosswordGenerator {
    let dictionary: CrosswordDictionary
    let difficulty: PuzzleDifficulty
    let profile: CrosswordGenerationProfile
    let deadline: Date
    var random: SeededRandomNumberGenerator

    mutating func generate() -> CrosswordPuzzle? {
        let entries = dictionary.entries
            .filter { difficulty.allows($0) }
            .filter { $0.normalizedAnswer.count >= 2 && $0.normalizedAnswer.count <= profile.size }

        guard !entries.isEmpty else { return nil }

        let index = WordIndex(entries: entries)
        let anchors = anchorEntries(from: entries)
        guard !anchors.isEmpty else { return nil }

        var bestPuzzle: CrosswordPuzzle?
        var bestScore = 0

        for anchor in anchors where Date() < deadline {
            var board = GeneratedCrosswordBoard()
            let start = CrosswordCoordinate(row: 0, column: 0)
            let seedPlacement = CrosswordPlacement(entry: anchor, start: start, direction: .across)
            guard board.canPlace(anchor, start: start, direction: .across, targetSize: profile.size) else { continue }

            board.place(seedPlacement)
            var queue = board.candidates(from: seedPlacement, profile: profile).shuffled(using: &random)

            while Date() < deadline, !queue.isEmpty, board.answerCount < profile.targetAnswers {
                let candidate = queue.removeFirst()
                let entries = rankedEntries(
                    index.entries(
                        length: candidate.length,
                        constraints: candidate.constraints,
                        usedAnswers: board.usedAnswers
                    ),
                    candidate: candidate
                )

                for entry in entries.prefix(profile.candidateTryLimit) {
                    guard board.canPlace(entry, start: candidate.start, direction: candidate.direction, targetSize: profile.size) else {
                        continue
                    }

                    let placement = CrosswordPlacement(entry: entry, start: candidate.start, direction: candidate.direction)
                    board.place(placement)
                    queue.append(contentsOf: board.candidates(from: placement, profile: profile).shuffled(using: &random))
                    break
                }
            }

            guard let puzzle = puzzle(from: board, index: index) else { continue }
            let score = puzzle.acrossClues.count + puzzle.downClues.count
            if score > bestScore {
                bestPuzzle = puzzle
                bestScore = score
            }

            if board.answerCount >= profile.targetAnswers {
                return puzzle
            }
        }

        return bestPuzzle
    }

    private mutating func anchorEntries(from entries: [CrosswordEntry]) -> [CrosswordEntry] {
        entries
            .filter { profile.seedLengths.contains($0.normalizedAnswer.count) }
            .sorted {
                if $0.normalizedAnswer.count == $1.normalizedAnswer.count {
                    let leftRank = difficulty.rank(for: $0)
                    let rightRank = difficulty.rank(for: $1)
                    if leftRank == rightRank {
                        return $0.normalizedAnswer < $1.normalizedAnswer
                    }

                    return leftRank < rightRank
                }

                return $0.normalizedAnswer.count > $1.normalizedAnswer.count
            }
            .prefix(16)
            .shuffled(using: &random)
    }

    private mutating func rankedEntries(_ entries: [CrosswordEntry], candidate: PlacementCandidate) -> [CrosswordEntry] {
        let ranked = entries.map { entry -> (entry: CrosswordEntry, rank: Int) in
            let difficultyRank = difficulty.rank(for: entry) * 1_000
            let lengthBonus = entry.normalizedAnswer.count * 100
            let jitter = Int(random.next() % 500)
            let rank = difficultyRank - lengthBonus - candidate.score + jitter
            return (entry, rank)
        }

        return ranked
            .sorted { left, right in
                if left.rank == right.rank {
                    return left.entry.normalizedAnswer < right.entry.normalizedAnswer
                }

                return left.rank < right.rank
            }
            .map(\.entry)
    }

    private func puzzle(from board: GeneratedCrosswordBoard, index: WordIndex) -> CrosswordPuzzle? {
        guard board.answerCount >= profile.minimumAnswers,
              board.isConnected(),
              let rows = board.normalizedRows(size: profile.size) else {
            return nil
        }

        let clueBank = index.clueBank(for: board.usedAnswers)
        let puzzle = CrosswordPuzzle(solutionRows: rows, clueBank: clueBank)
        guard validate(puzzle: puzzle, boardAnswers: board.usedAnswers, clueBank: clueBank) else {
            return nil
        }

        return puzzle
    }

    private func validate(puzzle: CrosswordPuzzle, boardAnswers: Set<String>, clueBank: [String: String]) -> Bool {
        let allClues = puzzle.acrossClues + puzzle.downClues
        guard allClues.count >= profile.minimumAnswers,
              allClues.allSatisfy({ $0.answer.count > 1 }),
              allClues.allSatisfy({ clueBank[$0.answer]?.isEmpty == false }),
              allClues.allSatisfy({ boardAnswers.contains($0.answer) }) else {
            return false
        }

        let answers = allClues.map(\.answer)
        guard Set(answers).count == answers.count else { return false }

        let groupedByNumber = Dictionary(grouping: allClues, by: \.number)
        for clues in groupedByNumber.values where clues.count > 1 {
            guard Set(clues.map(\.answer)).count == clues.count else {
                return false
            }
        }

        return isConnected(puzzle: puzzle)
    }

    private func isConnected(puzzle: CrosswordPuzzle) -> Bool {
        let playable = Set(puzzle.playableCoordinates)
        guard let first = playable.first else { return false }
        var visited: Set<CrosswordCoordinate> = [first]
        var queue = [first]

        while !queue.isEmpty {
            let current = queue.removeFirst()
            let neighbors = [
                CrosswordCoordinate(row: current.row - 1, column: current.column),
                CrosswordCoordinate(row: current.row + 1, column: current.column),
                CrosswordCoordinate(row: current.row, column: current.column - 1),
                CrosswordCoordinate(row: current.row, column: current.column + 1)
            ]

            for neighbor in neighbors where playable.contains(neighbor) && !visited.contains(neighbor) {
                visited.insert(neighbor)
                queue.append(neighbor)
            }
        }

        return visited.count == playable.count
    }
}

enum CrosswordGenerator {
    static func generate(
        size: Int,
        seed: Int? = nil,
        difficulty: PuzzleDifficulty = .easy,
        timeLimit: TimeInterval = 0.6
    ) -> CrosswordPuzzle? {
        let dictionary = CrosswordDictionary.bundled
        let profile = CrosswordGenerationProfile(size: size, difficulty: difficulty)
        var fastGenerator = FastCrosswordGenerator(
            dictionary: dictionary,
            difficulty: difficulty,
            profile: profile,
            deadline: Date().addingTimeInterval(timeLimit),
            random: SeededRandomNumberGenerator(seed: UInt64(seed ?? Int.random(in: 1...Int.max)))
        )

        if let generatedPuzzle = fastGenerator.generate() {
            return generatedPuzzle
        }

        if let seedPuzzle = CrosswordSeedLibrary.puzzle(size: size, difficulty: difficulty, seed: seed) {
            return seedPuzzle
        }

        let templates = CrosswordTemplate.templates(for: size)
        guard !templates.isEmpty else { return nil }

        var random = SeededRandomNumberGenerator(seed: UInt64(seed ?? Int.random(in: 1...Int.max)))
        let deadline = Date().addingTimeInterval(timeLimit)

        for template in templates.shuffled(using: &random) where Date() < deadline {
            let solver = CrosswordFillSolver(
                template: template,
                dictionary: dictionary,
                difficulty: difficulty,
                random: random,
                deadline: deadline
            )
            if let result = solver.solve() {
                return result
            }
        }

        return nil
    }
}

private struct CrosswordFillSolver {
    private let template: CrosswordTemplate
    private let dictionary: CrosswordDictionary
    private let difficulty: PuzzleDifficulty
    private var random: SeededRandomNumberGenerator
    private let deadline: Date
    private let slots: [FillSlot]

    init(
        template: CrosswordTemplate,
        dictionary: CrosswordDictionary,
        difficulty: PuzzleDifficulty,
        random: SeededRandomNumberGenerator,
        deadline: Date
    ) {
        self.template = template
        self.dictionary = dictionary
        self.difficulty = difficulty
        self.random = random
        self.deadline = deadline
        slots = Self.parseSlots(template: template)
    }

    func solve() -> CrosswordPuzzle? {
        guard !slots.isEmpty else { return nil }

        var solver = self
        var letters: [CrosswordCoordinate: Character] = [:]
        var filledSlotIDs: Set<Int> = []
        var usedAnswers: Set<String> = []

        guard solver.fill(
            letters: &letters,
            filledSlotIDs: &filledSlotIDs,
            usedAnswers: &usedAnswers
        ) else {
            return nil
        }

        let rows = solver.solutionRows(from: letters)
        return CrosswordPuzzle(solutionRows: rows, clueBank: dictionary.clueBank(for: usedAnswers))
    }

    private mutating func fill(
        letters: inout [CrosswordCoordinate: Character],
        filledSlotIDs: inout Set<Int>,
        usedAnswers: inout Set<String>
    ) -> Bool {
        guard Date() < deadline else { return false }

        if filledSlotIDs.count == slots.count {
            return true
        }

        guard let next = nextSlot(letters: letters, filledSlotIDs: filledSlotIDs, usedAnswers: usedAnswers) else {
            return false
        }

        let candidates = validEntries(for: next, letters: letters, usedAnswers: usedAnswers)
            .map { entry in
                (entry, difficulty.rank(for: entry) * 1_000 + Int(random.next() % 1_000))
            }
            .sorted {
                let leftRank = $0.1
                let rightRank = $1.1

                if leftRank == rightRank {
                    return $0.0.normalizedAnswer < $1.0.normalizedAnswer
                }

                return leftRank < rightRank
            }
            .map(\.0)

        for candidate in candidates {
            let answer = candidate.normalizedAnswer
            var changedCoordinates: [CrosswordCoordinate] = []

            for (index, coordinate) in next.cells.enumerated() {
                let character = answer[answer.index(answer.startIndex, offsetBy: index)]
                if letters[coordinate] == nil {
                    changedCoordinates.append(coordinate)
                }
                letters[coordinate] = character
            }

            filledSlotIDs.insert(next.id)
            let addedAnswer = usedAnswers.insert(answer).inserted

            if hasCandidatesForRemainingSlots(letters: letters, filledSlotIDs: filledSlotIDs, usedAnswers: usedAnswers),
               fill(letters: &letters, filledSlotIDs: &filledSlotIDs, usedAnswers: &usedAnswers) {
                return true
            }

            filledSlotIDs.remove(next.id)
            if addedAnswer {
                usedAnswers.remove(answer)
            }
            for coordinate in changedCoordinates {
                letters.removeValue(forKey: coordinate)
            }
        }

        return false
    }

    private func nextSlot(
        letters: [CrosswordCoordinate: Character],
        filledSlotIDs: Set<Int>,
        usedAnswers: Set<String>
    ) -> FillSlot? {
        slots
            .filter { !filledSlotIDs.contains($0.id) }
            .map { slot in
                (slot, validEntries(for: slot, letters: letters, usedAnswers: usedAnswers).count)
            }
            .filter { $0.1 > 0 }
            .sorted {
                if $0.1 == $1.1 {
                    return $0.0.cells.count > $1.0.cells.count
                }

                return $0.1 < $1.1
            }
            .first?
            .0
    }

    private func hasCandidatesForRemainingSlots(
        letters: [CrosswordCoordinate: Character],
        filledSlotIDs: Set<Int>,
        usedAnswers: Set<String>
    ) -> Bool {
        slots
            .filter { !filledSlotIDs.contains($0.id) }
            .allSatisfy { slot in
                !validEntries(for: slot, letters: letters, usedAnswers: usedAnswers).isEmpty
            }
    }

    private func validEntries(
        for slot: FillSlot,
        letters: [CrosswordCoordinate: Character],
        usedAnswers: Set<String>
    ) -> [CrosswordEntry] {
        dictionary.entries(length: slot.cells.count).filter { entry in
            let answer = entry.normalizedAnswer
            guard answer.count == slot.cells.count,
                  difficulty.allows(entry) else {
                return false
            }

            for (index, coordinate) in slot.cells.enumerated() {
                guard let existing = letters[coordinate] else { continue }
                let character = answer[answer.index(answer.startIndex, offsetBy: index)]
                if existing != character {
                    return false
                }
            }

            return true
        }
    }

    private func solutionRows(from letters: [CrosswordCoordinate: Character]) -> [String] {
        (0..<template.size).map { row in
            (0..<template.size).map { column in
                let coordinate = CrosswordCoordinate(row: row, column: column)
                return template.blockCells.contains(coordinate) ? "#" : String(letters[coordinate] ?? " ")
            }
            .joined()
        }
    }

    private static func parseSlots(template: CrosswordTemplate) -> [FillSlot] {
        var slots: [FillSlot] = []
        var nextID = 0

        for row in 0..<template.size {
            var column = 0
            while column < template.size {
                let cells = collectCells(from: CrosswordCoordinate(row: row, column: column), direction: .across, template: template)
                if cells.count > 1 {
                    slots.append(FillSlot(id: nextID, cells: cells))
                    nextID += 1
                    column += cells.count
                } else {
                    column += 1
                }
            }
        }

        for column in 0..<template.size {
            var row = 0
            while row < template.size {
                let cells = collectCells(from: CrosswordCoordinate(row: row, column: column), direction: .down, template: template)
                if cells.count > 1 {
                    slots.append(FillSlot(id: nextID, cells: cells))
                    nextID += 1
                    row += cells.count
                } else {
                    row += 1
                }
            }
        }

        return slots
    }

    private static func collectCells(
        from start: CrosswordCoordinate,
        direction: CrosswordDirection,
        template: CrosswordTemplate
    ) -> [CrosswordCoordinate] {
        guard isOpen(start, template: template) else { return [] }

        let previous = direction == .across
            ? CrosswordCoordinate(row: start.row, column: start.column - 1)
            : CrosswordCoordinate(row: start.row - 1, column: start.column)
        guard !isOpen(previous, template: template) else { return [] }

        var cells: [CrosswordCoordinate] = []
        var cursor = start

        while isOpen(cursor, template: template) {
            cells.append(cursor)
            cursor = direction == .across
                ? CrosswordCoordinate(row: cursor.row, column: cursor.column + 1)
                : CrosswordCoordinate(row: cursor.row + 1, column: cursor.column)
        }

        return cells
    }

    private static func isOpen(_ coordinate: CrosswordCoordinate, template: CrosswordTemplate) -> Bool {
        guard coordinate.row >= 0,
              coordinate.row < template.size,
              coordinate.column >= 0,
              coordinate.column < template.size else {
            return false
        }

        let row = template.rows[coordinate.row]
        let index = row.index(row.startIndex, offsetBy: coordinate.column)
        return row[index] != "#"
    }
}

extension PuzzleDifficulty {
    var scoreRange: ClosedRange<Int> {
        switch self {
        case .easy:
            70...100
        case .medium:
            35...100
        case .hard:
            0...100
        }
    }

    func allows(_ entry: CrosswordEntry) -> Bool {
        scoreRange.contains(entry.score)
    }

    func rank(for entry: CrosswordEntry) -> Int {
        switch self {
        case .easy:
            return 100 - entry.score
        case .medium:
            return abs(62 - entry.score)
        case .hard:
            return entry.score
        }
    }
}

private struct FillSlot {
    let id: Int
    let cells: [CrosswordCoordinate]
}

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x4d595df4d0f33173 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var value = state
        value = (value ^ (value >> 30)) &* 0xbf58476d1ce4e5b9
        value = (value ^ (value >> 27)) &* 0x94d049bb133111eb
        return value ^ (value >> 31)
    }
}
