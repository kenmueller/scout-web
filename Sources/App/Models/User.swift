import Vapor

final class User: Client {
	struct Init: Decodable {
		let `init`: Bool
		let id: UUID
		let name: String
	}
	
	struct Ready: Decodable {
		let ready: Bool
	}
	
	struct Ping: Decodable {
		let ping: Bool
		let id: UUID
	}
	
	struct Find: Decodable {
		let find: Bool
		let id: UUID
	}
	
	struct Pinged: Encodable {
		let pinged = true
	}
	
	struct Found: Encodable {
		let found = true
	}
	
	struct Data: Encodable {
		let data = true
		let id: UUID
		let name: String
		let ready: Bool
		let pinged: Bool
		let found: Bool
	}
	
	struct Users: Encodable {
		let users: [Data]
		
		init(_ users: [Data]) {
			self.users = users
		}
	}
	
	let name: String
	var ready = false
	var pinged = false
	var found = false
	
	var data: Data {
		.init(id: id, name: name, ready: ready, pinged: pinged, found: found)
	}
	
	init(id: UUID, socket: WebSocket, name: String) {
		self.name = name
		super.init(id: id, socket: socket)
	}
}
