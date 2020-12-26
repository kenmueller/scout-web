import Vapor

extension WebSocket {
	static func data<Data: Encodable>(_ data: Data) throws -> [UInt8] {
		.init(try encoder.encode(data))
	}
	
	func send<Data: Encodable>(_ data: Data) throws {
		send([UInt8](try encoder.encode(data)))
	}
}
