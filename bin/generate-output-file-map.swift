import Foundation

guard CommandLine.argc >= 4 else {
	print("Usage: \(CommandLine.arguments[0]) <dir> <tag> <files...>")
	exit(1)
}

let dir = CommandLine.arguments[1]
let tag = CommandLine.arguments[2]

var dict: [String: [String: String]] = [:]
for file in CommandLine.arguments[3...] {
	dict[file] = [
		"object": "\(dir)/\(file).\(tag).o",
		"dependencies": "\(dir)/\(file).\(tag).Td"
	]
}
dict[""] = [
	"swift-dependencies": "\(dir)/master.swiftdeps"
]

let json = try JSONEncoder().encode(dict)
print(String(data: json, encoding: .utf8)!)
