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

struct CrosswordDictionary {
    private let entriesByLength: [Int: [CrosswordEntry]]
    private let cluesByAnswer: [String: String]

    init(entries: [CrosswordEntry]) {
        let normalizedEntries = entries
            .map { entry in
                CrosswordEntry(answer: entry.normalizedAnswer, clue: entry.clue, score: entry.score)
            }
            .filter { !$0.normalizedAnswer.isEmpty }

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

enum CrosswordGenerator {
    static func generate(
        size: Int,
        seed: Int? = nil,
        difficulty: PuzzleDifficulty = .easy,
        timeLimit: TimeInterval = 0.6
    ) -> CrosswordPuzzle? {
        let templates = CrosswordTemplate.templates(for: size)
        guard !templates.isEmpty else { return nil }

        var random = SeededRandomNumberGenerator(seed: UInt64(seed ?? Int.random(in: 1...Int.max)))
        let deadline = Date().addingTimeInterval(timeLimit)
        let dictionary = CrosswordDictionary.bundled

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
