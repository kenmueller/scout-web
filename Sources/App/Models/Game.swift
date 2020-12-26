import Vapor

final class Game {
	struct Start: Encodable {
		let seeker: UUID
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
	
	func sendClients() {
		let clients = self.clients.active
		
		for client in clients {
			do {
				try client.socket.send(User.Users(
					clients.compactMap { $0.id == client.id ? nil : $0.data }
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
		
		for client in clients.active {
			client.socket.send(data)
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
			} else {
				return
			}
			
			self.sendClients()
		}
		
		socket.onClose.whenSuccess { [weak self] in
			guard let self = self, let user = user else { return }
			
			if user === self.seeker {
				self.seeker = nil
			}
			
			self.clients.remove(user)
			self.sendClients()
		}
	}
}
