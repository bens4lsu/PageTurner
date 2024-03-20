import NIOSSL
import Fluent
import FluentMySQLDriver
import Vapor
import QueuesFluentDriver
import Queues

// configures your application

extension DatabaseID {
    static let emailDb = DatabaseID(string: "emailDb")
}

public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    let settings = ConfigurationSettings()
    
    var logger = Logger(label: "logger")
    logger.logLevel = settings.loggerLogLevel
    
    #if DEBUG
    logger.debug("Running in debug.")
    #endif
    
    
    app.http.server.configuration.port = settings.host.listenOnPort
    var tls = TLSConfiguration.makeClientConfiguration()
    tls.certificateVerification = settings.certificateVerification
    
    app.databases.use(DatabaseConfigurationFactory.mysql(
        hostname: settings.database.hostname,
        port: settings.database.port,
        username: settings.database.username,
        password: settings.database.password,
        database: "PageTurner",
        tlsConfiguration: tls
    ), as: .mysql)
    
    app.databases.use(.mysql(
        hostname: settings.database.hostname,
        port: settings.database.port,
        username: settings.database.username,
        password: settings.database.password,
        database: "Mailer",
        tlsConfiguration: tls
    ), as: .emailDb)

    app.queues.use(.fluent())
    //JobMetadataMigrate().prepare(on: app.db(.mysql))
    
    
    let testJob = TestJob(settings: settings, logger: logger)
    
    #if DEBUG
    app.queues.schedule(testJob).minutely().at(18)
    #else
    app.queues.schedule(testJob).hourly().at(18)
    #endif
    
    try app.queues.startScheduledJobs()

    // register routes
    //try routes(app)
    
    //let _ = try await TestController.test(on: app.db)
    //try await PageController.test(on: app.db)
    
}
