import Foundation
import XCTest
@testable import WordPress

class DeleteSiteServiceTests : XCTestCase
{
    let contextManager = TestContextManager()
    var mockRemoteService: MockDeleteSiteServiceRemote!
    var deleteSiteService: DeleteSiteServiceTester!
    
    class MockDeleteSiteServiceRemote : DeleteSiteServiceRemote
    {
        var deleteSiteCalled = false
        var successBlockPassedIn:(() -> ())?
        var failureBlockPassedIn:((NSError) -> ())?
        
        override func deleteSite(siteID: NSNumber, success: (() -> ())?, failure: (NSError -> ())?) {
            deleteSiteCalled = true
            successBlockPassedIn = success
            failureBlockPassedIn = failure
        }
        
        func reset() {
            deleteSiteCalled = false
            successBlockPassedIn = nil
            failureBlockPassedIn = nil
        }
    }
    
    class DeleteSiteServiceTester : DeleteSiteService
    {
        let mockRemoteApi = MockWordPressComApi()
        lazy var mockRemoteService: MockDeleteSiteServiceRemote = {
            return MockDeleteSiteServiceRemote(api: self.mockRemoteApi)
        }()
        
        override func deleteSiteServiceRemoteForBlog(blog: Blog) -> DeleteSiteServiceRemote {
            return mockRemoteService
        }
    }
    
    override func setUp() {
        super.setUp()
  
        deleteSiteService = DeleteSiteServiceTester(managedObjectContext: contextManager.mainContext)
        mockRemoteService = deleteSiteService.mockRemoteService
    }
    
    func insertBlog(context: NSManagedObjectContext) -> Blog {
        let blog = NSEntityDescription.insertNewObjectForEntityForName("Blog", inManagedObjectContext: context) as! Blog
        blog.xmlrpc = "http://mock.blog/xmlrpc.php"
        blog.url = "http://mock.blog/"
        blog.dotComID = 999999

        try! context.obtainPermanentIDsForObjects([blog])
        try! context.save()

        return blog
    }
 
    func testRemoveBlogWithObjectIDWorks() {
        let context = contextManager.mainContext
        let blog = insertBlog(context)
        
        let blogObjectID = blog.objectID
        XCTAssertFalse(blogObjectID.temporaryID, "Should be a permanent object")
        
        let expectation = expectationWithDescription(
        "Remove Blog expectation")
        deleteSiteService.removeBlogWithObjectID(blogObjectID, success: {
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(2, handler: nil)
        
        let shouldBeRemoved = try? context.existingObjectWithID(blogObjectID)
        XCTAssertNil(shouldBeRemoved, "Blog was not removed")
    }

    func testDeleteSiteCallsServiceRemoteDeleteSite() {
        let context = contextManager.mainContext
        let blog = insertBlog(context)
        
        mockRemoteService.reset()
        deleteSiteService.deleteSiteForBlog(blog, success: nil, failure: nil)
        XCTAssertTrue(mockRemoteService.deleteSiteCalled, "Remote DeleteSite should have been called")
    }
    
    func testDeleteSiteCallsSuccessBlock() {
        let context = contextManager.mainContext
        let blog = insertBlog(context)
        
        let expectation = expectationWithDescription("Delete Site success expectation")
        mockRemoteService.reset()
        deleteSiteService.deleteSiteForBlog(blog,
            success: {
                expectation.fulfill()
            }, failure: nil)
        mockRemoteService.successBlockPassedIn?()
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testDeleteSiteCallsFailureBlock() {
        let context = contextManager.mainContext
        let blog = insertBlog(context)
        
        let testError = NSError(domain:"UnitTest", code:0, userInfo:nil)
        let expectation = expectationWithDescription("Delete Site failure expectation")
        mockRemoteService.reset()
        deleteSiteService.deleteSiteForBlog(blog,
            success: nil,
            failure: { error in
                XCTAssertEqual(error, testError, "Error not propagated")
                expectation.fulfill()
            })
        mockRemoteService.failureBlockPassedIn?(testError)
        waitForExpectationsWithTimeout(2, handler: nil)
    }
}
