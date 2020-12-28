import Vapor
import Socket

public func configure(_ app: Application) throws {
	app.webSocket(onUpgrade: SocketRoom<User>().register)
}
