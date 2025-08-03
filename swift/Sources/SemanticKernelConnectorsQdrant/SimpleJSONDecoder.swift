import Foundation

public enum JSONValue {
    case object([String: JSONValue])
    case array([JSONValue])
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
}

public struct SimpleJSONDecoder: Sendable {
    private var data: [UInt8]
    private var index: Int = 0

    public init(data: Data) {
        self.data = [UInt8](data)
    }

    public mutating func decode() throws -> JSONValue {
        skipWhitespace()
        let value = try parseValue()
        skipWhitespace()
        return value
    }

    private mutating func parseValue() throws -> JSONValue {
        guard index < data.count else { throw ParseError.unexpectedEnd }
        let byte = data[index]
        switch byte {
        case UInt8(ascii: "\""):
            return .string(try parseString())
        case UInt8(ascii: "{"):
            return .object(try parseObject())
        case UInt8(ascii: "["):
            return .array(try parseArray())
        case UInt8(ascii: "t"):
            try consumeLiteral("true")
            return .bool(true)
        case UInt8(ascii: "f"):
            try consumeLiteral("false")
            return .bool(false)
        case UInt8(ascii: "n"):
            try consumeLiteral("null")
            return .null
        case UInt8(ascii: "-") , 48...57:
            return .number(try parseNumber())
        default:
            throw ParseError.invalidCharacter(Character(UnicodeScalar(byte)))
        }
    }

    private mutating func parseObject() throws -> [String: JSONValue] {
        var obj: [String: JSONValue] = [:]
        expect("{")
        skipWhitespace()
        if peek() == "}" { index += 1; return obj }
        while true {
            skipWhitespace()
            let key = try parseString()
            skipWhitespace()
            expect(":")
            skipWhitespace()
            let value = try parseValue()
            obj[key] = value
            skipWhitespace()
            if peek() == "," { index += 1; continue }
            else if peek() == "}" { index += 1; break }
            else { throw ParseError.invalidCharacter(peek()) }
        }
        return obj
    }

    private mutating func parseArray() throws -> [JSONValue] {
        var arr: [JSONValue] = []
        expect("[")
        skipWhitespace()
        if peek() == "]" { index += 1; return arr }
        while true {
            let val = try parseValue()
            arr.append(val)
            skipWhitespace()
            if peek() == "," { index += 1; continue }
            else if peek() == "]" { index += 1; break }
            else { throw ParseError.invalidCharacter(peek()) }
        }
        return arr
    }

    private mutating func parseString() throws -> String {
        expect("\"")
        var result = ""
        while index < data.count {
            let byte = data[index]
            index += 1
            if byte == UInt8(ascii: "\"") {
                return result
            } else if byte == UInt8(ascii: "\\") {
                guard index < data.count else { throw ParseError.unexpectedEnd }
                let esc = data[index]
                index += 1
                switch esc {
                case UInt8(ascii: "\""), UInt8(ascii: "\\"), UInt8(ascii: "/"):
                    result.append(Character(UnicodeScalar(esc)))
                case UInt8(ascii: "b"): result.append("\u{0008}")
                case UInt8(ascii: "f"): result.append("\u{000c}")
                case UInt8(ascii: "n"): result.append("\n")
                case UInt8(ascii: "r"): result.append("\r")
                case UInt8(ascii: "t"): result.append("\t")
                case UInt8(ascii: "u"):
                    let hexStart = index
                    let hexEnd = index + 4
                    guard hexEnd <= data.count else { throw ParseError.unexpectedEnd }
                    let hexChars = data[hexStart..<hexEnd].map { Character(UnicodeScalar($0)) }
                    guard let scalar = UInt32(String(hexChars), radix: 16), let uni = UnicodeScalar(scalar) else { throw ParseError.invalidUnicode }
                    result.append(Character(uni))
                    index = hexEnd
                default:
                    throw ParseError.invalidEscape
                }
            } else {
                result.append(Character(UnicodeScalar(byte)))
            }
        }
        throw ParseError.unexpectedEnd
    }

    private mutating func parseNumber() throws -> Double {
        let start = index
        if peek() == "-" { index += 1 }
        while index < data.count, isDigit(data[index]) { index += 1 }
        if peek() == "." { index += 1; while index < data.count, isDigit(data[index]) { index += 1 } }
        let slice = data[start..<index]
        guard let str = String(bytes: slice, encoding: .utf8), let num = Double(str) else { throw ParseError.invalidNumber }
        return num
    }

    private mutating func consumeLiteral(_ literal: String) throws {
        for c in literal.utf8 {
            if index >= data.count || data[index] != c { throw ParseError.invalidLiteral }
            index += 1
        }
    }

    private mutating func expect(_ char: Character) {
        precondition(peek() == char)
        index += 1
    }

    private mutating func skipWhitespace() {
        while index < data.count { let c = data[index]; if c == 32 || c == 9 || c == 10 || c == 13 { index += 1 } else { break } }
    }

    private func peek() -> Character {
        guard index < data.count else { return "\0" }
        return Character(UnicodeScalar(data[index]))
    }

    private func isDigit(_ c: UInt8) -> Bool { c >= 48 && c <= 57 }

    enum ParseError: Error {
        case unexpectedEnd
        case invalidCharacter(Character)
        case invalidNumber
        case invalidLiteral
        case invalidEscape
        case invalidUnicode
    }
}
