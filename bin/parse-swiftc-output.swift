import Foundation

struct Options {
	let debug: Bool
	let colored: Bool
	let arch: String?
}

guard CommandLine.argc >= 3 else {
	print("Usage: \(CommandLine.arguments[0]) <colored: 0|1> [arch]")
	exit(EX_USAGE)
}

let options = Options(
	debug: ProcessInfo.processInfo.environment["DEBUG_OUTPUT"] != nil,
	colored: CommandLine.arguments[1] == "1", 
	arch: CommandLine.arguments[2]
)

func debugPrint(_ message: Any) {
	guard options.debug else { return }
	print(message)
}

enum Format {
	enum Color: Int {
		case red = 1
		case green = 2
		case yellow = 3
		case blue = 4
		case magenta = 5
		case cyan = 6
	}

	case notice
	case making
	case stage(Color)
	case warning
	case error

	func apply(to message: String) -> String {
		func format(_ string: String) -> String { options.colored ? "\u{001B}[\(string)": "" }
		switch self {
		case .notice:
			return "\(format("0;36m"))==> \(format("1;36m"))Notice:\(format("m")) \(message)"
		case .making:
			return "\(format("1;31m"))> \(format("1;3;39m"))\(message)…\(format("m"))"
		case .stage(let color):
			return "\(format("0;3\(color.rawValue)m"))==> \(format("1;39m"))\(message)…\(format("m"))"
		case .warning:
			return "\(format("0;33m"))==> \(format("1;33m"))Warning:\(format("m")) \(message)"
		case .error:
			return "\(format("0;31m"))==> \(format("1;31m"))Error:\(format("m")) \(message)"
		}
	}
}

enum SemanticMessage: CustomStringConvertible {
	case raw(String)
	case compiling(file: String)
	case swiftmoduleHeader(header: String)

	var description: String {
		let archStr = options.arch.map { " (\($0))" } ?? ""
		switch self {
		case .raw(let string):
			return string
		case .compiling(let file):
			return Format.stage(.green).apply(to: "Compiling \(file)\(archStr)")
		case .swiftmoduleHeader(let header):
			return Format.stage(.blue).apply(to: "Generating \(header)\(archStr)")
		}
	}
}

extension Decodable {
	init(container: SingleValueDecodingContainer) throws {
		self = try container.decode(Self.self)
	}
}

protocol OutputBody: Decodable {
	var messages: [SemanticMessage] { get }
}

struct CompileOutput: OutputBody {
	enum Kind: String, Decodable {
		case began
		case finished
	}

	let kind: Kind
	let inputs: [String]?
	let exitStatus: Int?
	let output: String?

	private enum CodingKeys: String, CodingKey {
		case kind
		case inputs
		case exitStatus = "exit-status"
		case output
	}

	var messages: [SemanticMessage] {
		if kind == .finished && (exitStatus ?? 0) != 0, let output = output {
			return [.raw(output)]
		} else {
			return (inputs ?? []).filter { !$0.hasSuffix(".pch") }.map(SemanticMessage.compiling)
		}
	}
}

struct MergeModuleOutput: OutputBody {
	enum Kind: String, Decodable {
		case began
	}

	struct OutputFile: Decodable {
		let type: String
		let path: String
	}

	let kind: Kind
	let outputs: [OutputFile]

	var messages: [SemanticMessage] {
		outputs
			.filter { $0.type == "objc-header" }
			.map { URL(fileURLWithPath: $0.path).lastPathComponent }
			.map(SemanticMessage.swiftmoduleHeader)
	}
}

struct Output: Decodable {
	enum Name: String, Decodable {
		case compile
		case mergeModule = "merge-module"

		var bodyType: OutputBody.Type {
			switch self {
			case .compile:
				return CompileOutput.self
			case .mergeModule:
				return MergeModuleOutput.self
			}
		}
	}

	private enum CodingKeys: String, CodingKey {
		case name
	}

	let name: Name
	let body: OutputBody

	init(from decoder: Decoder) throws {
		let nameContainer = try decoder.container(keyedBy: CodingKeys.self)
		let name = try nameContainer.decode(Name.self, forKey: .name)
		self.name = name

		let bodyContainer = try decoder.singleValueContainer()
		body = try name.bodyType.init(container: bodyContainer)
	}
}

func parseBody(ofLength totalLength: Int) throws {
	let bodyText = sequence(state: 0) { (length: inout Int) -> String? in
		// it is important that we only consume the next line if we have not surpassed the required
		// length. Otherwise, we may consume a line from the next body. Due to this, the length check
		// must occur *before* we call readLine.
		guard length < totalLength,
			let line = readLine(strippingNewline: false)
			else { return nil }
		length += line.utf8.count
		return line
	}.joined().dropLast() // drop \n on final line
	guard let data = bodyText.data(using: .utf8) else { return }

	let decoder = JSONDecoder()
	let output: Output
	// don't halt and catch fire if we can't parse this output. Just move on.
	do {
		output = try decoder.decode(Output.self, from: data)
	} catch {
		debugPrint(error)
		return
	}

	output.body.messages.forEach { print($0) }
}

func spitItOut(startingWith firstLine: String) {
	fputs("\(firstLine)\n", stderr)
	while let line = readLine(strippingNewline: false) {
		fputs(line, stderr)
	}
}

func parse() throws {
	while let line = readLine() {
		// `line` should always be a number (because parseBody eats the rest away).
		// If it isn't numeric, that probably means swiftc is outputting some error,
		// in which case we should just spit it out
		guard let charsToRead = Int(line) else {
			return spitItOut(startingWith: line)
		}
		try parseBody(ofLength: charsToRead)
	}
}

do {
	try parse()
} catch {
	if options.debug {
		fputs("Error: \(error)\n", stderr)
	}
	exit(1)
}
