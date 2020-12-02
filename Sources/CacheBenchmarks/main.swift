import Foundation

import ArgumentParser

struct CacheBenchmarks: ParsableCommand {
    static var configuration: CommandConfiguration = .init(
        abstract: "A utility for running benchmarks on 'Cache'.",
        subcommands: [
            GenerateCharts.self,
            RunBenchmarks.self,
            Profile.self,
        ],
        defaultSubcommand: RunBenchmarks.self
    )
}

CacheBenchmarks.main()
