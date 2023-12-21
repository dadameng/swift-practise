import Foundation

protocol APICache {
    var maxCacheAge: TimeInterval { get }
    var maxMemoryCost: Int { get }
    var maxCacheSize: Int { get }

    func convenienceStore<T: Codable>(with response: T, key: String)
    func storeMemoryCache<T: Codable>(with response: T, key: String)
    func storeResponseToDisk<T: Codable>(with response: T, key: String)

    func convenienceResponse<T: Codable>(key: String) async throws -> T?
    func responseFromMemoryCache<T: Codable>(key: String) -> T?
    func responseFromDiskCache<T: Codable>(key: String) async throws -> T?

    func removeMemoryCache(key: String)
    func removeDiskCache(key: String)
    func cleanMemoryCache()
    func cleanDishCache()
}

class CacheWrapper<T>: NSObject {
    let value: T

    init(value: T) {
        self.value = value
    }
}

final class DefaultAPICache: APICache {
    private let namespace = "com.dadameng.APICache"

    var maxCacheAge: TimeInterval
    var maxMemoryCost: Int
    var maxCacheSize: Int

    private let memCache: NSCache<NSString, CacheWrapper<Any>>
    private let diskCachePath: URL

    private let diskEncoder: ResponseEncoder
    private let diskDecoder: ResponseDecoder

    private let fileManager: FileManager
    unowned var ioQueue: DispatchQueue

    init(
        maxCacheAge: TimeInterval,
        maxMemoryCost: Int,
        maxCacheSize: Int,
        memCache: NSCache<NSString, CacheWrapper<Any>>,
        diskEncoder: ResponseEncoder,
        diskDecoder: ResponseDecoder,
        diskCachePath: URL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!,
        fileManager: FileManager = FileManager.default,
        ioQueue: DispatchQueue = DispatchQueue.global(qos: .background)
    ) {
        self.maxCacheAge = maxCacheAge
        self.maxMemoryCost = maxMemoryCost
        self.maxCacheSize = maxCacheSize
        self.memCache = memCache
        self.memCache.name = namespace
        self.diskEncoder = diskEncoder
        self.diskDecoder = diskDecoder
        self.diskCachePath = diskCachePath.appendingPathComponent(namespace)
        self.fileManager = fileManager
        self.ioQueue = ioQueue
        prepareDirectory()
    }

    private func prepareDirectory() {
        guard !fileManager.fileExists(atPath: diskCachePath.path) else { return }

        do {
            try fileManager.createDirectory(
                atPath: diskCachePath.path,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            print("APICache createDirectory error \(error)")
        }
    }

    private func diskPath(key: String) -> URL {
        diskCachePath.appendingPathComponent(key)
    }

    func convenienceStore(with response: some Codable, key: String) {
        storeMemoryCache(with: response, key: key)
        storeResponseToDisk(with: response, key: key)
    }

    func storeMemoryCache(with response: some Codable, key: String) {
        memCache.setObject(CacheWrapper(value: response), forKey: key as NSString)
    }

    func storeResponseToDisk(with response: some Codable, key: String) {
        let diskPath = diskPath(key: key)
        ioQueue.async {
            do {
                print("start print write data")
                let encodedData = try self.diskEncoder.encode(response)
                try encodedData.write(to: diskPath, options: .atomic)
            } catch {
                print("write cache error on request : \(diskPath) ")
            }
        }
    }

    func convenienceResponse<T: Codable>(key: String) async throws -> T? {
        if let memoryResponse: T = responseFromMemoryCache(key: key) {
            return memoryResponse
        }

        do {
            if let diskResponse: T = try await responseFromDiskCache(key: key) {
                storeMemoryCache(with: diskResponse, key: key)
                return diskResponse
            }
        } catch {
            throw error
        }

        return nil
    }

    func responseFromMemoryCache<T: Codable>(key: String) -> T? {
        guard let wrapper = memCache.object(forKey: NSString(string: key)) as? CacheWrapper<T> else {
            return nil
        }
        return wrapper.value
    }

    func responseFromDiskCache<T: Codable>(key: String) async throws -> T? {
        let diskPathURL = diskPath(key: key)

        return try await withCheckedThrowingContinuation { continuation in
            ioQueue.async {
                do {
                    guard self.fileManager.fileExists(atPath: diskPathURL.path) else {
                        continuation.resume(throwing: NSError(domain: "FileNotFoundError", code: 404, userInfo: nil))
                        return
                    }
                    let data = try Data(contentsOf: diskPathURL)
                    let decodedResponse = try self.diskDecoder.decode(T.self, from: data)
                    continuation.resume(returning: decodedResponse)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func removeMemoryCache(key: String) { memCache.removeObject(forKey: key as NSString) }

    func removeDiskCache(key: String) {
        ioQueue.async {
            let diskURL = self.diskPath(key: key)
            try? self.fileManager.removeItem(at: diskURL)
        }
    }

    func cleanMemoryCache() {
        memCache.removeAllObjects()
    }

    func cleanDishCache() {
        ioQueue.async {
            let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .contentModificationDateKey, .totalFileAllocatedSizeKey]

            guard let fileEnumerator = FileManager.default.enumerator(
                at: self.diskCachePath,
                includingPropertiesForKeys: resourceKeys,
                options: .skipsHiddenFiles
            ) else { return }

            let expirationDate = Date().addingTimeInterval(-self.maxCacheAge)
            var filesToDelete = [URL]()
            var currentCacheSize: Int = 0
            var cacheFiles = [URL: URLResourceValues]()

            for case let fileURL as URL in fileEnumerator {
                guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
                      let isDirectory = resourceValues.isDirectory,
                      let modificationDate = resourceValues.contentModificationDate,
                      let fileSize = resourceValues.totalFileAllocatedSize
                else {
                    continue
                }

                if !isDirectory, modificationDate < expirationDate {
                    filesToDelete.append(fileURL)
                    continue
                }

                if !isDirectory {
                    currentCacheSize += fileSize
                    cacheFiles[fileURL] = resourceValues
                }
            }

            for fileURL in filesToDelete {
                try? self.fileManager.removeItem(at: fileURL)
            }

            if self.maxCacheSize > 0, currentCacheSize > self.maxCacheSize {
                let desiredCacheSize = self.maxCacheSize / 2

                let sortedFiles = fileEnumerator.allObjects as? [URL] ?? []
                    .filter { try! $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == false }
                    .sorted {
                        let date1 = try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                        let date2 = try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                        return date1 ?? Date.distantPast < date2 ?? Date.distantPast
                    }

                for fileURL in sortedFiles {
                    guard let fileSize = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize else {
                        continue
                    }

                    try? self.fileManager.removeItem(at: fileURL)
                    currentCacheSize -= fileSize

                    if currentCacheSize <= desiredCacheSize {
                        break
                    }
                }
            }
        }
    }
}
