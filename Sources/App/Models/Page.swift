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
    
    @Field(key: "CRC")
    var crc: String?

    init() { }
    

}
