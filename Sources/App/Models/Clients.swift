import Vapor

final class Clients<Value: Client> {
	private let eventLoop: EventLoop
	private var clients: [UUID: Value] = [:]
	
	var active: [Value] {
		clients.values.filter { !$0.socket.isClosed }
	}
	
	init(eventLoop: EventLoop) {
		self.eventLoop = eventLoop
	}
	
	deinit {
		eventLoop
			.flatten(clients.values.map { $0.socket.close() })
			.whenFailure { print($0) }
	}
	
	var random: Value? {
		active.randomElement()
	}
	
	func add(_ client: Value) {
		clients[client.id] = client
	}
	
	func remove(_ client: Value) {
		clients[client.id] = nil
	}
	
	func find(_ id: UUID) -> Value? {
		clients[id]
	}
}
