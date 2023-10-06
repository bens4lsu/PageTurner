import Fluent
import Vapor

final class Page: Model, Content {
    
    static let schema = "TestPages"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "PageID")
    var pageId: Int

    @Field(key: "Version")
    var version: Int
    
    @Field(key: "IsCurrent")
    var isCurrent: Bool
    
    @Field(key: "PageDescription")
    var pageDescription: String
    
    @Field(key: "URL")
    var url: String
    
    @Field(key: "ImageAsBase64String")
    var imageBase64: String

    init() { }
    
    // add new page
    init(on db: Database, pageDescription: String, url: String) async throws {
        var version = 1
        var pageId = 0
        if let existing = try await Page.query(on: db).filter(\.$url == url).filter(\.$isCurrent == true).first() {
            version = existing.version + 1
            pageId = existing.pageId
            existing.isCurrent = false
            try await existing.save(on: db)
        }
        else {
            let maxPageId = try await Page.query(on: db).max(\.$pageId) ?? 0
            pageId = maxPageId + 1
        }
        self.version = version
        self.isCurrent = true
        self.pageId = pageId
        self.pageDescription = pageDescription
        self.url = try await url.urlToBase64Data() ?? ""
    }

}
