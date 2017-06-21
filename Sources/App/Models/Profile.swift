//
//  Profile.swift
//  MotivationQuotes
//
//  Created by Alif on 20/06/2017.
//
//

import Vapor
import FluentProvider
import AuthProvider
import JWTProvider
import JWT
import HTTP

final class Profile: Model {
  let storage = Storage()
  
  struct Properties {
    static let id = "id"
    static let firstName   = "firstName"
    static let middleName  = "middleName"
    static let lastName    = "lastName"
    static let dateOfBirth = "dateOfBirth"
  }
  
  public var firstName: String
  public var middleName: String
  public var lastName: String
  public var dateOfBirth: String
  public var userId: Identifier
  
  init(firstName: String, middleName: String, lastName: String, dateOfBirth: String, user: User) throws {
    self.firstName   = firstName
    self.middleName  = middleName
    self.lastName    = lastName
    self.dateOfBirth = dateOfBirth
    self.userId = try user.assertExists()
  }
  
  public init(row: Row) throws {
    self.firstName   = try row.get(Properties.firstName)
    self.middleName  = try row.get(Properties.middleName)
    self.lastName    = try row.get(Properties.lastName)
    self.dateOfBirth = try row.get(Properties.dateOfBirth)
    self.userId        = try row.get(User.foreignIdKey)
  }
  
  public func makeRow() throws -> Row {
    var row = Row()
    try row.set(Properties.firstName, firstName)
    try row.set(Properties.middleName, middleName)
    try row.set(Properties.lastName, lastName)
    try row.set(Properties.dateOfBirth, dateOfBirth)
    try row.set(User.foreignIdKey, userId)
    return row
  }
}

extension Profile: Preparation {
  static func prepare(_ database: Database) throws {
    try database.create(self) { builder in
      builder.id()
      builder.string(Properties.firstName)
      builder.string(Properties.middleName)
      builder.string(Properties.lastName)
      builder.string(Properties.dateOfBirth)
      builder.foreignId(for: User.self)
    }
  }
  
  static func revert(_ database: Database) throws {
    try database.delete(self)
  }
}

//
extension Profile {
  func owner() throws -> Parent<Profile, User> {
    return parent(id: userId)
  }
}

// Mark JSON
extension Profile: JSONConvertible {
  convenience init(json: JSON) throws {
    try self.init(
      firstName:   json.get(Properties.firstName),
      middleName:  json.get(Properties.middleName),
      lastName:    json.get(Properties.lastName),
      dateOfBirth: json.get(Properties.dateOfBirth),
      user:        User.find(json.get("user"))!
    )
  }
  
  func makeJSON() throws -> JSON {
    var json = JSON()
    try json.set(Properties.id, id)
    try json.set(Properties.firstName, firstName)
    try json.set(Properties.middleName, middleName)
    try json.set(Properties.lastName, lastName)
    try json.set(Properties.dateOfBirth, dateOfBirth)
    return json
  }
}

// Mark HTTP
extension Profile: ResponseRepresentable { }

extension Profile: Updateable {
  public static var updateableKeys: [UpdateableKey<Profile>] {
    return [
      UpdateableKey(Properties.firstName, String.self) { profile, firstName in
        profile.firstName = firstName
      }
    ]
  }
}

