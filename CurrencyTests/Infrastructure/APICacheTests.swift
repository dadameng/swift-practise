@testable import Currency
import XCTest

final class APICacheTests: XCTestCase {
    struct MockJSONResponseDecoder: ResponseDecoder {
        private let jsonDecoder = JSONDecoder()
        func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
            try jsonDecoder.decode(type, from: data)
        }
    }

    struct MockJSONResponseEncoder: ResponseEncoder {
        private let jsonEncoder = JSONEncoder()
        func encode(_ from: some Encodable) throws -> Data {
            try jsonEncoder.encode(from)
        }
    }

    var cache: DefaultAPICache!
    let memCache = NSCache<NSString, CacheWrapper<Any>>()
    let fileMgr = FileManager.default

    override func setUp() {
        super.setUp()
        cache = DefaultAPICache(
            maxCacheAge: 3600,
            maxMemoryCost: 1024,
            maxCacheSize: 1024,
            memCache: memCache,
            diskEncoder: MockJSONResponseEncoder(),
            diskDecoder: MockJSONResponseDecoder()
        )
        cache.generatePath = mockDiskCachePath
    }

    override func tearDown() {
        memCache.removeAllObjects()
        do {
            try fileMgr.removeItem(at: fileMgr.temporaryDirectory)
        } catch { print("APICacheTests tearDown error \(error)")
        }
        super.tearDown()
    }

    func mockDiskCachePath(key: String) -> URL {
        fileMgr.temporaryDirectory.appendingPathComponent("APICacheTests").appendingPathComponent("test/\(key)")
    }

    func testStoreMemoryCache_whenStoreKey_thenSuccessed() {
        let testObject = "TestString"
        let testKey = "TestKey_\(UUID().uuidString)"

        cache.storeMemoryCache(with: testObject, key: testKey)
        let storedObject = memCache.object(forKey: testKey as NSString)?.value as? String
        XCTAssertEqual(storedObject, testObject, "Stored object should match the test object")
    }

    func testStoreResponseToDisk_whenStoreToDisk_thenSuccessed() {
        let testObject = "TestString"
        let testKey = "TestKey_\(UUID().uuidString)"
        let expectation = XCTestExpectation(description: "Disk storage")

        cache.storeResponseToDisk(with: testObject, key: testKey)

        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            let diskPath = self.mockDiskCachePath(key: testKey)
            let fileExists = self.fileMgr.fileExists(atPath: diskPath.path)
            DispatchQueue.main.async {
                XCTAssertTrue(fileExists, "File should exist on disk")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 10)
    }

    func testResponseFromDiskCache_whenCacheHasValue_thenRetrieveSuccess() {
        let testObject = "TestString"
        let testKey = "TestKey_\(UUID().uuidString)"

        let diskPath = mockDiskCachePath(key: testKey)
        let encodedData = try! MockJSONResponseEncoder().encode(testObject)

        do {
            try fileMgr.createDirectory(
                atPath: diskPath.deletingLastPathComponent().path,
                withIntermediateDirectories: true,
                attributes: nil
            )
            try encodedData.write(to: diskPath, options: .atomic)
        } catch {
            XCTFail("Setup error: \(error)")
            return
        }
        let expectation = XCTestExpectation(description: "Disk retrieval")
        Task {
            do {
                let retrievedObject: String? = try await cache.responseFromDiskCache(key: testKey)
                XCTAssertEqual(retrievedObject, testObject, "Retrieved object should match the stored object")
                expectation.fulfill()
            } catch {
                XCTFail("Expected successful response, received error: \(error)")
            }
        }

        wait(for: [expectation], timeout: 10)
        do {
            try fileMgr.removeItem(at: diskPath)
        } catch {
            print("Error cleaning up test files: \(error)")
        }
    }

    func testResponseFromMemory_whenCacheHasValue_thenRetrieveSuccess() {
        let testObject = "TestString"
        let testKey = "TestKey_\(UUID().uuidString)"
        cache.storeMemoryCache(with: testObject, key: testKey)
        let _: String? = cache.responseFromMemoryCache(key: testKey)
        if let cachedWrapper = memCache.object(forKey: testKey as NSString) {
            XCTAssertEqual(cachedWrapper.value as! String, testObject, "Retrieved object should store to the memory")
        } else {
            XCTFail("Failed to retrieve object from memory cache")
        }
    }

    func testResponseFromConvince_whenDiskCacheHasValueAndMemNoCache_thenRetrieveFromDiskAndStoreToMemory() {
        let testObject = "TestString"
        let testKey = "TestKey_\(UUID().uuidString)"

        let diskPath = mockDiskCachePath(key: testKey)
        let encodedData = try! MockJSONResponseEncoder().encode(testObject)
        do {
            try fileMgr.createDirectory(
                atPath: diskPath.deletingLastPathComponent().path,
                withIntermediateDirectories: true,
                attributes: nil
            )
            try encodedData.write(to: diskPath, options: .atomic)
        } catch {
            XCTFail("Setup error: \(error)")
            return
        }

        let expectation = XCTestExpectation(description: "Convenience Response retrieval")
        Task {
            do {
                let retrievedObject: String? = try await cache.convenienceResponse(key: testKey)
                XCTAssertEqual(retrievedObject, testObject, "Retrieved object should match the stored object")
                if let cachedWrapper = memCache.object(forKey: testKey as NSString) {
                    XCTAssertEqual(cachedWrapper.value as! String, testObject, "Retrieved object should store to the memory")
                } else {
                    XCTFail("Failed to retrieve object from memory cache")
                }
                expectation.fulfill()
            } catch {
                XCTFail("Expected successful response, received error: \(error)")
            }
        }

        wait(for: [expectation], timeout: 10)
        do {
            try fileMgr.removeItem(at: diskPath)
        } catch {
            print("Error cleaning up test files: \(error)")
        }
    }
}
