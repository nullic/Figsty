import ArgumentParser
import Foundation

struct Figsty: ParsableCommand {
    static let configuration = CommandConfiguration(
        subcommands: [
            RemoteFile.self,
            ValiablesFile.self,
        ],
        defaultSubcommand: RemoteFile.self
    )
}

Figsty.main()
