//
//  main.swift
//  Kineo
//
//  Created by Gregory Todd Williams on 6/24/16.
//  Copyright © 2016 Gregory Todd Williams. All rights reserved.
//

import Foundation
import SPARQLSyntax

public struct PeekableIterator<T: IteratorProtocol> : IteratorProtocol {
    public typealias Element = T.Element
    private var generator: T
    private var bufferedElement: Element?
    public  init(generator: T) {
        self.generator = generator
        bufferedElement = self.generator.next()
    }
    
    public mutating func next() -> Element? {
        let r = bufferedElement
        bufferedElement = generator.next()
        return r
    }
    
    public func peek() -> Element? {
        return bufferedElement
    }
    
    mutating func dropWhile(filter: (Element) -> Bool) {
        while bufferedElement != nil {
            if !filter(bufferedElement!) {
                break
            }
            _ = next()
        }
    }
    
    mutating public func elements() -> [Element] {
        var elements = [Element]()
        while let e = next() {
            elements.append(e)
        }
        return elements
    }
}

func getCurrentDateSeconds() -> UInt64 {
    var startTime: time_t
    startTime = time(nil)
    return UInt64(startTime)
}

func getCurrentTime() -> CFAbsoluteTime {
    return CFAbsoluteTimeGetCurrent()
}

func warn(_ items: String...) {
    for string in items {
        fputs(string, stderr)
        fputs("\n", stderr)
    }
}

func printSPARQL(_ qfile: String, pretty: Bool = false, silent: Bool = false, includeComments: Bool = false) throws {
    let url = URL(fileURLWithPath: qfile)
    let sparql = try Data(contentsOf: url)
    let stream = InputStream(data: sparql)
    stream.open()
    let lexer = SPARQLLexer(source: stream, includeComments: includeComments)
    let s = SPARQLSerializer()
    let tokens: UnfoldSequence<SPARQLToken, Int> = sequence(state: 0) { (_) in return lexer.next() }
    if pretty {
        print(s.serializePretty(tokens))
    } else {
        print(s.serialize(tokens))
    }
}

func data(fromFileOrString qfile: String) throws -> Data {
    let url = URL(fileURLWithPath: qfile)
    let data: Data
    if case .some(true) = try? url.checkResourceIsReachable() {
        data = try Data(contentsOf: url)
    } else {
        guard let s = qfile.data(using: .utf8) else {
            fatalError("Could not interpret SPARQL query string as UTF-8")
        }
        data = s
    }
    return data
}

var verbose = true
let argscount = CommandLine.arguments.count
var args = PeekableIterator(generator: CommandLine.arguments.makeIterator())
guard let pname = args.next() else { fatalError("Missing command name") }
guard argscount > 2 else {
    print("Usage: \(pname) [-v] COMMAND [ARGUMENTS]")
    print("       \(pname) parse query.rq")
    print("       \(pname) lint query.rq")
    print("       \(pname) tokens query.rq")
    print("")
    exit(1)
}

if let next = args.peek(), next == "-v" {
    _ = args.next()
    verbose = true
}

let startTime = getCurrentTime()
let startSecond = getCurrentDateSeconds()
var count = 0

if let op = args.next() {
    if op == "parse" {
        var printAlgebra = false
        var printSPARQL = false
        var pretty = true
        if let next = args.peek(), next.lowercased() == "-s" {
            _ = args.next()
            printSPARQL = true
            if next == "-S" {
                pretty = true
            }
        }
        if let next = args.peek(), next == "-a" {
            _ = args.next()
            printAlgebra = true
        }
        if !printAlgebra && !printSPARQL {
            printAlgebra = true
        }
        
        guard let qfile = args.next() else { fatalError("No query file given") }
        do {
            let sparql = try data(fromFileOrString: qfile)
            guard var p = SPARQLParser(data: sparql) else { fatalError("Failed to construct SPARQL parser") }
            let query = try p.parseQuery()
            count = 1
            if printAlgebra {
                print(query.serialize())
            }
            if printSPARQL {
                let s = SPARQLSerializer()
                let tokens  = query.sparqlTokens
                if pretty {
                    print(s.serializePretty(tokens))
                } else {
                    print(s.serialize(tokens))
                }
            }
        } catch let e {
            warn("*** Failed to parse query: \(e)")
        }
    } else if op == "tokens" {
        var printAlgebra = false
        var printSPARQL = false
        if let next = args.peek(), next.lowercased() == "-s" {
            _ = args.next()
            printSPARQL = true
        }
        if let next = args.peek(), next == "-a" {
            _ = args.next()
            printAlgebra = true
        }
        if !printAlgebra && !printSPARQL {
            printAlgebra = true
        }
        
        guard let qfile = args.next() else { fatalError("No query file given") }
        do {
            let sparql = try data(fromFileOrString: qfile)
            let stream = InputStream(data: sparql)
            stream.open()
            let lexer = SPARQLLexer(source: stream, includeComments: true)
            while let t = lexer.next() {
                print("\(t)")
            }
        } catch let e {
            warn("*** Failed to tokenize query: \(e)")
        }
    } else if op == "lint", let qfile = args.next() {
        do {
            let pretty = true
            try printSPARQL(qfile, pretty: pretty, silent: false, includeComments: true)
        } catch let e {
            warn("*** Failed to lint query: \(e)")
        }
    } else {
        warn("Unrecognized operation: '\(op)'")
        exit(1)
    }
}
