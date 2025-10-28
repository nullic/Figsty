import ArgumentParser
import PathKit

extension Path: @retroactive _SendableMetatype {}
extension Path: @retroactive ExpressibleByArgument, @retroactive Decodable {
    public init?(argument: String) {
        self.init(argument)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedString = try container.decode(String.self)
        self.init(decodedString)
    }
}
