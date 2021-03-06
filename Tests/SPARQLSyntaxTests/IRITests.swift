import XCTest
import Foundation
import SPARQLSyntax

#if os(Linux)
extension IRITest {
    static var allTests : [(String, (IRITest) -> () throws -> Void)] {
        return [
            ("testIRI_AbsoluteWithBase", testIRI_AbsoluteWithBase),
            ("testIRI_FragmentWithBase", testIRI_FragmentWithBase),
            ("testIRI_FullPathWithBase", testIRI_FullPathWithBase),
            ("testIRI_RelativeWithBase", testIRI_RelativeWithBase),
            ("testIRI_Namespace", testIRI_Namespace),
        ]
    }
}
#endif

// swiftlint:disable type_body_length
class IRITest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testIRI_FragmentWithBase() {
        let base = IRI(string: "file:///Users/greg/data/prog/git/sparql/kineo/rdf-tests/sparql11/data-r2/algebra/two-nested-opt.rq")
        XCTAssertNotNil(base)
        let rel = "#x1"
        let i = IRI(string: rel, relativeTo: base)
        XCTAssertNotNil(i)
        if let i = i {
            XCTAssertEqual(i.absoluteString, "file:///Users/greg/data/prog/git/sparql/kineo/rdf-tests/sparql11/data-r2/algebra/two-nested-opt.rq#x1")
        }
    }
    
    func testIRI_RelativeWithBase() {
        let base = IRI(string: "file:///Users/greg/data/prog/git/sparql/kineo/rdf-tests/sparql11/data-r2/algebra/two-nested-opt.rq")
        let rel = "x1"
        let i = IRI(string: rel, relativeTo: base)
        XCTAssertNotNil(i)
        XCTAssertEqual(i!.absoluteString, "file:///Users/greg/data/prog/git/sparql/kineo/rdf-tests/sparql11/data-r2/algebra/x1")
    }
    
    func testIRI_FullPathWithBase() {
        let base = IRI(string: "file:///Users/greg/data/prog/git/sparql/kineo/rdf-tests/sparql11/data-r2/algebra/two-nested-opt.rq")
        let rel = "/x1"
        let i = IRI(string: rel, relativeTo: base)
        XCTAssertNotNil(i)
        XCTAssertEqual(i!.absoluteString, "file:///x1")
    }
    
    func testIRI_Namespace() {
        let ns = Namespace.rdf
        let type = ns.type
        XCTAssertEqual(type, "http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
        
        guard let n = ns.iri(for: "nil") else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(n.absoluteString, "http://www.w3.org/1999/02/22-rdf-syntax-ns#nil")
    }
    
    func testIRI_file() {
        let i = IRI(fileURLWithPath: "/tmp")
        XCTAssertNotNil(i)
        let iri = i!
        XCTAssertEqual(iri.absoluteString, "file:///tmp")
    }
}
