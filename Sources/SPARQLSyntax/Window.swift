//
//  Window.swift
//  SPARQLSyntax
//
//  Created by Gregory Todd Williams on 3/6/19.
//

import Foundation

public enum WindowFunction : String, Codable {
    case rowNumber
    case rank
    
    public var variables: Set<String> {
        switch self {
        case .rowNumber, .rank:
            return Set()
        }
    }
}

extension WindowFunction: CustomStringConvertible {
    public var description: String {
        switch self {
        case .rowNumber:
            return "ROW_NUMBER()"
        case .rank:
            return "RANK()"
        }
    }
}

public extension WindowFunction {
    func replace(_ map: [String:Term]) throws -> WindowFunction {
        switch self {
        case .rank:
            return self
        case .rowNumber:
            return self
        }
    }
    
    func replace(_ map: (Expression) throws -> Expression?) throws -> WindowFunction {
        switch self {
        case .rank:
            return self
        case .rowNumber:
            return self
        }
    }
    
    func rewrite(_ map: (Expression) throws -> RewriteStatus<Expression>) throws -> WindowFunction {
        switch self {
        case .rank:
            return self
        case .rowNumber:
            return self
        }
    }
}

public struct WindowFrame: Hashable, Codable {
    public enum FrameBound: Hashable {
        case current
        case unbound
        case preceding(Expression)
        case following(Expression)
    }
    public enum FrameType: Hashable {
        case rows
        case range
    }
    public var type: FrameType
    public var from: FrameBound
    public var to: FrameBound
    
    public init(type: FrameType, from: FrameBound, to: FrameBound) {
        self.type = type
        self.from = from
        self.to = to
    }
}

extension WindowFrame.FrameBound : Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case expression
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "current":
            self = .current
        case "unbound":
            self = .unbound
        case "preceding":
            let expr = try container.decode(Expression.self, forKey: .expression)
            self = .preceding(expr)
        case "following":
            let expr = try container.decode(Expression.self, forKey: .expression)
            self = .following(expr)
        default:
            throw SPARQLSyntaxError.serializationError("Unexpected window frame bound type '\(type)' found")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .current:
            try container.encode("current", forKey: .type)
        case .unbound:
            try container.encode("unbound", forKey: .type)
        case .preceding(let expr):
            try container.encode("preceding", forKey: .type)
            try container.encode(expr, forKey: .expression)
        case .following(let expr):
            try container.encode("following", forKey: .type)
            try container.encode(expr, forKey: .expression)
        }
    }
}

extension WindowFrame.FrameType : Codable {
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "rows":
            self = .rows
        case "range":
            self = .range
        default:
            throw SPARQLSyntaxError.serializationError("Unexpected window frame type '\(type)' found")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .rows:
            try container.encode("rows", forKey: .type)
        case .range:
            try container.encode("range", forKey: .type)
        }
    }
}


public struct WindowApplication: Hashable, Codable {
    public var windowFunction: WindowFunction
    public var comparators: [Algebra.SortComparator]
    public var partition: [Expression]
    public var frame: WindowFrame
    public init(windowFunction: WindowFunction, comparators: [Algebra.SortComparator], partition: [Expression], frame: WindowFrame) {
        self.windowFunction = windowFunction
        self.comparators = comparators
        self.partition = partition
        self.frame = frame
    }
    public var variables: Set<String> {
        return windowFunction.variables
    }
}

public extension WindowApplication {
    func replace(_ map: [String:Term]) throws -> WindowApplication {
        let cmps = try self.comparators.map { (cmp) in
            try Algebra.SortComparator(ascending: cmp.ascending, expression: cmp.expression.replace(map))
        }
        let partition = try self.partition.map { (e) in
            try e.replace(map)
        }
        let frame = try self.frame.replace(map)
        return WindowApplication(
            windowFunction: windowFunction,
            comparators: cmps,
            partition: partition,
            frame: frame
        )
    }
    
    func replace(_ map: (Expression) throws -> Expression?) throws -> WindowApplication {
        let cmps = try self.comparators.map { (cmp) in
            try Algebra.SortComparator(ascending: cmp.ascending, expression: cmp.expression.replace(map))
        }
        let partition = try self.partition.map { (e) in
            try e.replace(map)
        }
        let frame = try self.frame.replace(map)
        return WindowApplication(
            windowFunction: windowFunction,
            comparators: cmps,
            partition: partition,
            frame: frame
        )
    }
    
    func rewrite(_ map: (Expression) throws -> RewriteStatus<Expression>) throws -> WindowApplication {
        let cmps = try self.comparators.map { (cmp) in
            try Algebra.SortComparator(ascending: cmp.ascending, expression: cmp.expression.rewrite(map))
        }
        let partition = try self.partition.map { (e) in
            try e.rewrite(map)
        }
        let frame = try self.frame.rewrite(map)
        return WindowApplication(
            windowFunction: windowFunction,
            comparators: cmps,
            partition: partition,
            frame: frame
        )
    }
}

extension WindowFrame {
    func replace(_ map: [String:Term]) throws -> WindowFrame {
        return try WindowFrame(
            type: type,
            from: from.replace(map),
            to: to.replace(map)
        )
    }
    
    func replace(_ map: (Expression) throws -> Expression?) throws -> WindowFrame {
        return try WindowFrame(
            type: type,
            from: from.replace(map),
            to: to.replace(map)
        )
    }
    
    func rewrite(_ map: (Expression) throws -> RewriteStatus<Expression>) throws -> WindowFrame {
        let from = try self.from.rewrite(map)
        let to = try self.to.rewrite(map)
        return WindowFrame(
            type: type,
            from: from,
            to: to
        )
    }
}

extension WindowFrame.FrameBound {
    func replace(_ map: [String:Term]) throws -> WindowFrame.FrameBound {
        switch self {
        case .current, .unbound:
            return self
        case .preceding(let e):
            return try .preceding(e.replace(map))
        case .following(let e):
            return try .following(e.replace(map))
        }
    }
    
    func replace(_ map: (Expression) throws -> Expression?) throws -> WindowFrame.FrameBound {
        switch self {
        case .current, .unbound:
            return self
        case .preceding(let e):
            return try .preceding(e.replace(map))
        case .following(let e):
            return try .following(e.replace(map))
        }
    }
    
    func rewrite(_ map: (Expression) throws -> RewriteStatus<Expression>) throws -> WindowFrame.FrameBound {
        switch self {
        case .current, .unbound:
            return self
        case .preceding(let e):
            let expr = try e.rewrite(map)
            return .preceding(expr)
        case .following(let e):
            let expr = try e.rewrite(map)
            return .following(expr)
        }
    }
}

extension WindowFrame: CustomStringConvertible {
    public var description: String {
//        case current
//        case unbound
//        case preceding(Expression)
//        case following(Expression)
        return "\(type) BETWEEN \(from) TO \(to)"
    }
}

extension WindowApplication: CustomStringConvertible {
    public var description: String {
        let f = self.windowFunction.description
        let frame = self.frame
        let order = self.comparators
        let groups = self.partition

        var parts = [String]()
        switch (frame.from, frame.to) {
        case (.unbound, .unbound):
            return "\(f) OVER (PARTITION BY \(groups) ORDER BY \(order))"
        default:
            parts.append(frame.description)
        }
        
        if !groups.isEmpty {
            parts.append("PARTITION BY \(groups)")
        }
        
        if !order.isEmpty {
            parts.append("ORDER BY \(order)")
        }

        return "\(f) OVER (\(parts.joined(separator: " ")))"
    }
}



extension WindowFunction {
    public func sparqlTokens() throws -> AnySequence<SPARQLToken> {
        var tokens = [SPARQLToken]()
        switch self {
        case .rank:
            tokens.append(.keyword("RANK"))
            tokens.append(.lparen)
            tokens.append(.rparen)
        case .rowNumber:
            tokens.append(.keyword("ROW_NUMBER"))
            tokens.append(.lparen)
            tokens.append(.rparen)
        }
        return AnySequence(tokens)
    }
}

extension WindowFrame {
    public func sparqlTokens() throws -> AnySequence<SPARQLToken> {
        var tokens = [SPARQLToken]()
        switch (from, to) {
        case (.unbound, .unbound):
            return AnySequence(tokens)
        default:
            break
        }
        
        switch type {
        case .range:
            tokens.append(.keyword("RANGE"))
        case .rows:
            tokens.append(.keyword("ROWS"))
        }
        
        tokens.append(.keyword("BETWEEN"))
        try tokens.append(contentsOf: from.sparqlTokens())
        tokens.append(.keyword("AND"))
        try tokens.append(contentsOf: to.sparqlTokens())
        return AnySequence(tokens)
    }
}

extension WindowFrame.FrameBound {
    public func sparqlTokens() throws -> AnySequence<SPARQLToken> {
        var tokens = [SPARQLToken]()
        switch self {
        case .unbound:
            tokens.append(.keyword("UNBOUNDED"))
        case .current:
            tokens.append(.keyword("CURRENT"))
            tokens.append(.keyword("ROW"))
        case .following(let e):
            try tokens.append(contentsOf: e.sparqlTokens())
            tokens.append(.keyword("FOLLOWING"))
        case .preceding(let e):
            try tokens.append(contentsOf: e.sparqlTokens())
            tokens.append(.keyword("PRECEDING"))
        }
        return AnySequence(tokens)
    }
}

extension WindowApplication {
    public func sparqlTokens() throws -> AnySequence<SPARQLToken> {
        let frame = self.frame
        let order = self.comparators
        let groups = self.partition
        
        var tokens = [SPARQLToken]()
        try tokens.append(contentsOf: self.windowFunction.sparqlTokens())
        tokens.append(.keyword("OVER"))
        tokens.append(.lparen)
        if !groups.isEmpty {
            tokens.append(.keyword("PARTITION"))
            tokens.append(.keyword("BY"))
            for g in groups {
                try tokens.append(contentsOf: g.sparqlTokens())
            }
        }
        if !order.isEmpty {
            tokens.append(.keyword("ORDER"))
            tokens.append(.keyword("BY"))
            for c in order {
                try tokens.append(contentsOf: c.sparqlTokens())
            }
        }
        try tokens.append(contentsOf: frame.sparqlTokens())
        tokens.append(.rparen)
        return AnySequence(tokens)
    }
}

