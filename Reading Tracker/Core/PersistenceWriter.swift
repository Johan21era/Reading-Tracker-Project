//  PersistenceWriter.swift
//  Reading Tracker
//
//  FINAL TRACES / UPGRADE #4 (safe slice): a dedicated OWNED serial queue
//  that executes ALL library disk writes. Replaces the ad-hoc detached-task
//  chain in DataStore.enqueueWrite — identical FIFO ordering contract, but
//  the executor is owned and named, so future SQLite-style stores can adopt
//  it directly (fixes the cross-thread handle issue from P6-G: everything
//  touching a DB handle will run on THIS queue).
//
//  Why DispatchQueue over an actor here: encode/write closures are
//  synchronous by nature; a serial queue gives owned serialization without
//  async-entry friction at every call site, and plays perfectly with the
//  semaphore drain in saveImmediately().

import Foundation

final class PersistenceWriter: @unchecked Sendable {
    static let shared = PersistenceWriter()

    private let queue: DispatchQueue

    init(label: String = "readingtracker.persistence.writer") {
        queue = DispatchQueue(label: label, qos: .utility) // serial by default
    }

    /// Enqueues an encode+write job. FIFO ordering guaranteed.
    /// Returns a handle whose `value` resolves after this job completes
    /// ("nil" = success), preserving DataStore's observer pattern.
    func enqueue(encode: @escaping @Sendable () throws -> Data,
                 write: @escaping @Sendable (Data) throws -> Void)
        -> Task<String?, Never> {
        Task.detached(priority: .utility) { () -> String? in
            await self.perform(encode: encode, write: write)
        }
    }

    private func perform(encode: @escaping @Sendable () throws -> Data,
                         write: @escaping @Sendable (Data) throws -> Void) async -> String? {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async {
                continuation.resume()
            }
        }
        do {
            let data = try encode()
            try write(data)
            return nil
        } catch {
            return "\(error)"
        }
    }

    /// Synchronous barrier for saveImmediately paths (drains ALL pending).
    func drainSync() {
        queue.sync(flags: .barrier) {}
    }
}
