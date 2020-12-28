import Foundation
import Socket

final class User: SocketClient {
	struct Share: SocketShare {
		var seeker: User?
	}
	
	struct Query: SocketQuery {
		let id: UUID
		let name: String
	}
	
	struct Start: SocketMessage {
		static let id = "start"
		
		let seeker: UUID
	}
	
	struct Restart: SocketMessage {
		static let id = "restart"
	}
	
	struct Ready: SocketMessage {
		static let id = "ready"
		
		let ready: Bool
	}
	
	struct Ping: SocketMessage {
		static let id = "ping"
		
		let id: UUID
	}
	
	struct Pinged: SocketMessage {
		static let id = "pinged"
	}
	
	struct Find: SocketMessage {
		static let id = "find"
		
		let id: UUID
	}
	
	struct Found: SocketMessage {
		static let id = "found"
	}
	
	struct Users: SocketMessage {
		static let id = "users"
		
		let users: [Data]
	}
	
	struct Data: Codable {
		let id: UUID
		let name: String
		let ready: Bool
		let pinged: Bool
		let found: Bool
		
		init(_ user: User) {
			id = user.id
			name = user.name
			ready = user.ready
			pinged = user.pinged
			found = user.found
		}
	}
	
	let room: Room
	let socket: Socket
	
	let id: UUID
	let name: String
	var ready = false
	var pinged = false
	var found = false
	
	var data: Data {
		.init(self)
	}
	
	var allReady: Bool {
		room.clients.allSatisfy(\.value.ready)
	}
	
	init(room: Room, socket: Socket, query: Query) {
		self.room = room
		self.socket = socket
		
		id = query.id
		name = query.name
		
		socket.on { (ready: Ready) in
			do {
				self.ready = ready.ready
				
				try self.startIfReady()
				try self.updateUsers()
			} catch {
				print(error)
			}
		}
		
		socket.on { (ping: Ping) in
			do {
				guard let user = room.clients[ping.id], !user.pinged else { return }
				
				user.pinged = true
				
				try user.socket.send(Pinged())
				try self.updateUsers()
			} catch {
				print(error)
			}
		}
		
		socket.on { (find: Find) in
			do {
				guard let user = room.clients[find.id], !user.found else { return }
				
				user.found = true
				
				try user.socket.send(Found())
				try self.updateUsers()
			} catch {
				print(error)
			}
		}
		
		socket.on { (restart: Restart) in
			do {
				for (_, user) in room.clients {
					user.ready = false
					user.pinged = false
					user.found = false
				}
				
				for (_, user) in room.clients {
					try user.socket.send(restart)
				}
				
				try self.updateUsers()
				room.share.seeker = nil
			} catch {
				print(error)
			}
		}
		
		socket.onDisconnect {
			do {
				if self.id == room.share.seeker?.id {
					room.share.seeker = nil
				}
				
				try self.updateUsers()
			} catch {
				print(error)
			}
		}
	}
	
	func onConnect() {
		do {
			try self.updateUsers()
		} catch {
			print(error)
		}
	}
	
	func startIfReady() throws {
		guard
			room.share.seeker == nil && allReady,
			let seeker = room.clients.randomElement()?.value
		else { return }
		
		let message = Start(seeker: seeker.id)
		room.share.seeker = seeker
		
		for (_, user) in room.clients {
			try user.socket.send(message)
		}
	}
	
	func updateUsers() throws {
		for (_, user) in room.clients {
			try user.socket.send(Users(
				users: room.clients.compactMap {
					$1.id == user.id ? nil : $1.data
				}
			))
		}
	}
}
