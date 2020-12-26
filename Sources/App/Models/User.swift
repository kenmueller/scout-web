import Vapor

final class User: Client {
	struct Init: Decodable {
		let id: UUID
		let name: String
	}
	
	struct Ready: Decodable {
		let ready: Bool
	}
	
	struct Data: Encodable {
		let id: UUID
		let name: String
		let ready: Bool
	}
	
	struct Users: Encodable {
		let users: [Data]
		
		init(_ users: [Data]) {
			self.users = users
		}
	}
	
	let name: String
	var ready = false
	var found = false
	
	var data: Data {
		.init(id: id, name: name, ready: ready)
	}
	
	init(id: UUID, socket: WebSocket, name: String) {
		self.name = name
		super.init(id: id, socket: socket)
	}
}
