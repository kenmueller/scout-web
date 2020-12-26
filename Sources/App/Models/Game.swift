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
	
	func startIfReady() {
		guard seeker == nil && ready else { return }
		
		seeker = clients.random
		sendStart()
	}
	
	func sendClients() {
		let clients = self.clients.active
		
		for client in clients {
			let users = User.Users(
				clients.compactMap { $0.id == client.id ? nil : $0.data }
			)
			
			guard let data = try? encoder.encode(users) else {
				print("Unable to get users")
				continue
			}
			
			client.socket.send([UInt8](data))
		}
	}
	
	func sendStart() {
		guard
			let seeker = seeker?.id,
			let start = try? encoder.encode(Start(seeker: seeker))
		else {
			print("Unable to get start data")
			return
		}
		
		let data = [UInt8](start)
		
		for client in clients.active {
			client.socket.send(data)
		}
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
				self.startIfReady()
			} else {
				return
			}
			
			self.sendClients()
		}
		
		socket.onClose.whenSuccess { [weak self] in
			guard let self = self, let user = user else { return }
			
			self.clients.remove(user)
			self.sendClients()
		}
	}
}
