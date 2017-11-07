import Foundation

/// MediaSyncCoordinator is responsible for syncing media
/// items from the server, independently of a specific view controller. It should be accessed
/// via the `shared` singleton.
///
public class MediaSyncCoordinator: NSObject {

    static let shared = MediaSyncCoordinator()
    private let context = ContextManager.sharedInstance().newDerivedContext()

    // Init marked private to ensure use of shared singleton.
    private override init() {}

    /// Sync the specified blog media library.
    ///
    /// - parameter blog: The blog from where to sync the media library from.
    ///
    func syncMedia(of blog: Blog, success: (() -> ())?, failure: ((Error) -> ())? ) {
        let service = MediaService(managedObjectContext: context)
        service.syncMediaLibrary(for: blog, success: success, failure: failure)
    }
}
