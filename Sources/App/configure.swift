import Vapor

public func configure(_ app: Application) throws {
	let game = Game(eventLoop: app.eventLoopGroup.next())
	
	app.webSocket { _, socket in
		game.connect(socket)
	}
}
