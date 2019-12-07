import Foundation
import SwiftSyntax

class CollectPipeline: SyntaxVisitor {
    
    var sources: [SourceDetail] = []
    var sourceExtensions: [SourceDetail] = []
    private let context: CollectContext
    private var rules: [SourceCollectRule] = []
    
    init(context: CollectContext) {
        self.context = context
        self.rules = context.configuration.rules.compactMap { $0 as? SourceCollectRule }
    }
    
    func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        if rules.contains(where: { $0.skip(node) }) {
            return .visitChildren
        }
        
        if let position = findLocaiton(syntax: node.identifier) {
            collect(SourceDetail(name: node.identifier.text, sourceKind: .class, location: position))
        }
        return .visitChildren
    }
    
    func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        if rules.contains(where: { $0.skip(node) }) {
            return .visitChildren
        }
        if let position = findLocaiton(syntax: node.identifier) {
            collect(SourceDetail(name: node.identifier.text, sourceKind: .struct, location: position))
        }
        return .visitChildren
    }
    
    func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        if rules.contains(where: { $0.skip(node) }) {
            return .visitChildren
        }
        let ps = node.signature.input.parameterList.compactMap {
            $0.firstName?.text
        }
        let function = Function(name: node.identifier.text, parameters: ps)
        if let position = findLocaiton(syntax: node.identifier) {
            collect(SourceDetail(name: function.description, sourceKind: .function, location: position))
        }
        return .visitChildren
    }
    
    func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        if let position = findLocaiton(syntax: node.identifier) {
            collect(SourceDetail(name: node.identifier.text, sourceKind: .enum, location: position))
        }
        return .visitChildren
    }
    
    func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        if let position = findLocaiton(syntax: node.identifier) {
            collect(SourceDetail(name: node.identifier.text, sourceKind: .protocol, location: position))
        }
        return .visitChildren
    }
    
    func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
        if let position = findLocaiton(syntax: node.identifier) {
            collect(SourceDetail(name: node.identifier.text, sourceKind: .typealias, location: position))
        }
        return .visitChildren
    }
    
    func visit(_ node: OperatorDeclSyntax) -> SyntaxVisitorContinueKind {
        if let position = findLocaiton(syntax: node.identifier) {
            collect(SourceDetail(name: node.identifier.text, sourceKind: .operator, location: position))
        }
        return .visitChildren
    }
    
    func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        for token in node.extendedType.tokens {
            if let position = findLocaiton(syntax: token) {
                sourceExtensions.append(SourceDetail(name: token.text , sourceKind: .extension, location: position))
            }
        }
        return .visitChildren
    }
}

extension CollectPipeline {
    
    func collect(_ source: SourceDetail) {
        if !checkWhitelist(source: source) {
            sources.append(source)
        }
    }
    
    func findLocaiton(syntax: Syntax) -> SourceLocation? {
        let position = context.sourceLocationConverter.location(for: syntax.positionAfterSkippingLeadingTrivia)
        guard let line = position.line,
            let column = position.column else {
            return nil
        }
        return SourceLocation(path: context.filePath, line: line, column: column, offset: position.offset)
    }
}