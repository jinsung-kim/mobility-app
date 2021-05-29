//
//  DatabaseManager.swift
//  NYU Mobility
//
//  Created by Jin Kim on 5/28/21.
//

import Foundation
import FirebaseDatabase

/// Manager object to read and write data to the real time Firebase database
final class DatabaseManager {
    
    // Referenced throughout view controllers
    static let shared = DatabaseManager()
    
    // Reference to the database
    private let database = Database.database().reference()
    
    static func safeEmail(_ emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

extension DatabaseManager {
    
    /// Returns dictionary node at child path
    public func getDataFor(path: String,
                           completion: @escaping (Result<Any, Error>) -> Void) {
        database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}

// MARK: - Account Management
extension DatabaseManager {
    
    public enum DatabaseError: Error {
        case failedToFetch
        
        public var localizedDescription: String {
            switch (self) {
            case .failedToFetch:
                return "Database fetching failed"
            }
        }
    }
    
    /// Given the details of a session, this function will add the session under the specialists' code database
    public func insertSession(_ session: NSDictionary, completion: @escaping (Bool) -> Void) {
        self.database.child("session").observeSingleEvent(of: .value, with: {
            snapshot in
            if var sessions = snapshot.value as? [NSDictionary] {
                sessions.append(session)
                self.database.child("session").setValue(sessions, withCompletionBlock: {
                    error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    completion(true)
                })
            } else { // No sessions yet -> Start the array
                self.database.child("session").setValue([session], withCompletionBlock: {
                    error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    completion(true)
                })
            }
        })
    }
}
