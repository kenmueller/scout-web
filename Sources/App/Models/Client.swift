import Vapor

class Client {
	let id: UUID
	let socket: WebSocket
	
	init(id: UUID, socket: WebSocket) {
		self.id = id
		self.socket = socket
	}
}
