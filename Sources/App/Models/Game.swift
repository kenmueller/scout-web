import Vapor

final class Game {
	struct Start: Encodable {
		let seeker: UUID
	}
	
	struct RestartRequest: Decodable {
		let restart: Bool
	}
	
	struct RestartResponse: Encodable {
		let restart = true
	}
	
	let clients: Clients<User>
	var seeker: User?
	
	init(eventLoop: EventLoop) {
		clients = .init(eventLoop: eventLoop)
	}
	
	var ready: Bool {
		clients.active.allSatisfy { $0.ready }
	}
	
	func startIfReady() throws {
		guard seeker == nil && ready else { return }
		
		seeker = clients.random
		try sendStart()
	}
	
	func sendUsers() {
		let users = clients.active
		
		for user in users {
			do {
				try user.socket.send(User.Users(
					users.compactMap { $0.id == user.id ? nil : $0.data }
				))
			} catch {
				print(error)
			}
		}
	}
	
	func sendStart() throws {
		guard let seeker = seeker?.id else {
			return
		}
		
		let data = try WebSocket.data(Start(seeker: seeker))
		
		for user in clients.active {
			user.socket.send(data)
		}
	}
	
	func ping(_ id: UUID) throws {
		guard let user = clients[id], !user.pinged else { return }
		
		user.pinged = true
		try user.socket.send(User.Pinged())
	}
	
	func find(_ id: UUID) throws {
		guard let user = clients[id], !user.found else { return }
		
		user.found = true
		try user.socket.send(User.Found())
	}
	
	func restart() throws {
		let data = try WebSocket.data(RestartResponse())
		let users = clients.active
		
		for user in users {
			user.ready = false
			user.pinged = false
			user.found = false
		}
		
		for user in users {
			user.socket.send(data)
		}
		
		seeker = nil
	}
	
	func connect(_ socket: WebSocket) {
		var user: User?
		
		socket.onBinary { [weak self] _, data in
			guard let self = self else { return }
			
			if let data = try? decoder.decode(User.Init.self, from: data) {
				guard user == nil else { return }
				
				user = User(id: data.id, socket: socket, name: data.name)
				self.clients.add(user!)
			} else if let ready = try? decoder.decode(User.Ready.self, from: data).ready {
				guard let user = user else { return }
				
				user.ready = ready
				
				do {
					try self.startIfReady()
				} catch {
					print(error)
				}
			} else if let id = try? decoder.decode(User.Ping.self, from: data).id {
				do {
					try self.ping(id)
				} catch {
					print(error)
				}
			} else if let id = try? decoder.decode(User.Find.self, from: data).id {
				do {
					try self.find(id)
				} catch {
					print(error)
				}
			} else if (try? decoder.decode(RestartRequest.self, from: data)) != nil {
				do {
					try self.restart()
				} catch {
					print(error)
				}
			} else {
				return
			}
			
			self.sendUsers()
		}
		
		socket.onClose.whenSuccess { [weak self] in
			guard let self = self, let user = user else { return }
			
			if user === self.seeker {
				self.seeker = nil
			}
			
			self.clients.remove(user)
			self.sendUsers()
		}
	}
}
