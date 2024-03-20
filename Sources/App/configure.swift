import NIOSSL
import Fluent
import FluentMySQLDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    var tls = TLSConfiguration.makeClientConfiguration()
    tls.certificateVerification = .none
    
    app.databases.use(DatabaseConfigurationFactory.mysql(
        hostname: "127.0.0.1",
        port: 3306,
        username: "myuser",
        password: "password",
        database: "PageTurner",
        tlsConfiguration: tls
    ), as: .mysql)


    // register routes
    //try routes(app)
    
    let _ = try await TestController.test(on: app.db)
    //try await PageController.test(on: app.db)
    

    
    
    
    
}
