extension String {
    static let variableStartLexeme = "{{"
    static let variableEndLexeme = "}}"

    static let blockStartLexeme = "{%"
    static let blockEndLexeme = "%}"

    static let blockNoBRStartLexeme = "{%-"
    static let blockNoBREndLexeme = "-%}\n"

    static let commentStartLexeme = "{#"
    static let commentEndLexeme = "#}"
}

struct Lexer {
  let templateString: String

  init(templateString: String) {
    self.templateString = templateString
  }

  struct LexemePair {
    var start: String
    var end: String
  }

  func createToken(string:String) -> Token {
    func strip(pair: LexemePair) -> String {
      let start = string.index(string.startIndex, offsetBy: pair.start.characters.count)
      let end = string.index(string.endIndex, offsetBy: -pair.end.characters.count)
      return string[start..<end].trim(character: " ")
    }

    if string.hasPrefix(.variableStartLexeme) {
      return .variable(value: strip(pair: LexemePair(start: .variableStartLexeme, end: .variableEndLexeme)))
    } else if string.hasPrefix(.blockNoBRStartLexeme) {
      return .block(value: strip(pair: LexemePair(start: .blockNoBRStartLexeme, end: .blockNoBREndLexeme)))
    } else if string.hasPrefix(.blockStartLexeme) {
      return .block(value: strip(pair: LexemePair(start: .blockStartLexeme, end: .blockEndLexeme)))
    } else if string.hasPrefix(.commentStartLexeme) {
      return .comment(value: strip(pair: LexemePair(start: .commentStartLexeme, end: .commentEndLexeme)))
    }

    return .text(value: string)
  }

  /// Returns an array of tokens from a given template string.
  func tokenize() -> [Token] {
    var tokens: [Token] = []

    let scanner = Scanner(templateString)

    let lexicalKeys: [String] = [
        .variableStartLexeme,
        .blockNoBRStartLexeme,
        .blockStartLexeme,
        .commentStartLexeme
    ]
    let lexicalMap: [String: String] = [
      .variableStartLexeme: .variableEndLexeme,
      .blockStartLexeme: .blockEndLexeme,
      .blockNoBRStartLexeme: .blockNoBREndLexeme,
      .commentStartLexeme: .commentEndLexeme
    ]

    while !scanner.isEmpty {
      if let text = scanner.scan(until: lexicalKeys) {
        if !text.1.isEmpty {
          tokens.append(createToken(string: text.1))
        }

        let end = lexicalMap[text.0]!
        let result = scanner.scan(until: end, returnUntil: true)
        tokens.append(createToken(string: result))
      } else {
        tokens.append(createToken(string: scanner.content))
        scanner.content = ""
      }
    }

    return tokens
  }
}


class Scanner {
  var content: String

  init(_ content: String) {
    self.content = content
  }

  var isEmpty: Bool {
    return content.isEmpty
  }

  func scan(until: String, returnUntil: Bool = false) -> String {
    if until.isEmpty {
      return ""
    }

    var index = content.startIndex
    while index != content.endIndex {
      let substring = content.substring(from: index)

      if substring.hasPrefix(until) {
        let result = content.substring(to: index)
        content = substring

        if returnUntil {
          content = content.substring(from: until.endIndex)
          return result + until
        }

        return result
      }

      index = content.index(after: index)
    }

    return ""
  }

  func scan(until: [String]) -> (String, String)? {
    if until.isEmpty {
      return nil
    }

    var index = content.startIndex
    while index != content.endIndex {
      let substring = content.substring(from: index)
      for string in until {
        if substring.hasPrefix(string) {
          let result = content.substring(to: index)
          content = substring
          return (string, result)
        }
      }

      index = content.index(after: index)
    }

    return nil
  }
}


extension String {
  func findFirstNot(character: Character) -> String.Index? {
    var index = startIndex

    while index != endIndex {
      if character != self[index] {
        return index
      }
      index = self.index(after: index)
    }

    return nil
  }

  func findLastNot(character: Character) -> String.Index? {
    var index = self.index(before: endIndex)

    while index != startIndex {
      if character != self[index] {
        return self.index(after: index)
      }
      index = self.index(before: index)
    }

    return nil
  }

  func trim(character: Character) -> String {
    let first = findFirstNot(character: character) ?? startIndex
    let last = findLastNot(character: character) ?? endIndex
    return self[first..<last]
  }
}
