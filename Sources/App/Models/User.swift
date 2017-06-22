//
//  User.swift
//  MotivationQuotes
//
//  Created by Alif on 12/06/2017.
//
//

import Vapor
import FluentProvider
import AuthProvider
import JWTProvider
import JWT
import HTTP

public enum RegistrationError: Error {
  case emailTaken
}

extension RegistrationError: Debuggable {
  public var reason: String {
    let reason: String
    
    switch self {
    case .emailTaken: reason = "Email is already taken"
    }
    
    return "Authentication error: \(reason)"
  }
  
  public var identifier: String {
    switch self {
    case .emailTaken: return "emailtaken"
    }
  }
  
  public var suggestedFixes: [String] {
    return []
  }
  
  public var possibleCauses: [String] {
    return []
  }
}

final class User: Model {
  let storage = Storage()
  
  var email: String
  var password: Bytes
  
  
  /// Creates a new Post
  init(email: String, password: Bytes) {
    self.email = email
    self.password = password
  }
  
  // MARK: Fluent Serialization
  
  init(row: Row) throws {
    email = try row.get("email")
    
    let passwordAsString: String = try row.get("password")
    password = passwordAsString.makeBytes()
  }
  
  func makeRow() throws -> Row {
    var row = Row()
    try row.set("email", email)
    try row.set("password", password.makeString())
    return row
  }
}

// MARK: Fluent Preparation
extension User: Preparation {
  static func prepare(_ database: Database) throws {
    try database.create(self) { builder in
      builder.id()
      builder.string("email")
      builder.string("password")
    }
  }
  
  /// Undoes what was done in `prepare`
  static func revert(_ database: Database) throws {
    try database.delete(self)
  }
}

extension User: SessionPersistable { }

extension User: PasswordAuthenticatable {
  
  static func register(email: String, password: Bytes) throws -> User {
    guard try User.makeQuery().filter("email", email).first() == nil else { throw RegistrationError.emailTaken }
    let user = User(email: email, password: password)
    try user.save()
    return user
  }
  
  var hashedPassword: String? {
    return self.password.makeString()
  }
  
  static var emailKey: String {
    return "email"
  }
  
  static var passwordKey: String {
    return "password"
  }
  
  static var passwordHasher: BCryptHasher {
    return BCryptHasher(cost: 10)
  }
  
  static var passwordVerifier: PasswordVerifier? {
    return User.passwordHasher
  }
  
  func updatePassword(_ password: String) throws {
    self.password = try User.passwordHasher.make(password)
  }
}

extension User: TokenAuthenticatable {
  
  public typealias TokenType = User
  
  static func authenticate(_ token: Token) throws -> User {
    let jwt = try JWT(token: token.string)
    try jwt.verifySignature(using: HS256(key: "SIGNING_KEY".makeBytes()))
    let time = ExpirationTimeClaim(date: Date())
    try jwt.verifyClaims([time])
    guard let userId = jwt.payload.object?[SubjectClaim.name]?.string else { throw AuthenticationError.invalidCredentials }
    guard let user = try User.makeQuery().filter("id", userId).first() else { throw AuthenticationError.invalidCredentials }
    return user
  }
}


class Claims: JSONInitializable {
  var subjectClaimValue : String
  var expirationTimeClaimValue : Double
  public required init(json: JSON) throws {
    guard let subjectClaimValue = try json.get(SubjectClaim.name) as String? else {
      throw AuthenticationError.invalidCredentials
    }
    self.subjectClaimValue = subjectClaimValue
    
    guard let expirationTimeClaimValue = try json.get(ExpirationTimeClaim.name) as String? else {
      throw AuthenticationError.invalidCredentials
    }
    self.expirationTimeClaimValue = Double(expirationTimeClaimValue)!
    
  }
}

extension User: PayloadAuthenticatable {
  typealias PayloadType = Claims
  static func authenticate(_ payload: Claims) throws -> User {
    if payload.expirationTimeClaimValue < Date().timeIntervalSince1970 {
      throw AuthenticationError.invalidCredentials
    }
    
    let userId = payload.subjectClaimValue
    guard let user = try User.makeQuery()
      .filter(idKey, userId)
      .first()
      else {
        throw AuthenticationError.invalidCredentials
    }
    
    return user
  }
}

extension User: NodeRepresentable {
  func makeNode(in context: Context) throws -> Node {
    var node = Node(context)
    try node.set("id", id)
    try node.set("email", email)
    try node.set("password", password)
    return node
  }
}

extension User {
  func profile() throws -> Profile? {
    return try children().first()
  }
}

// MARK: JSON
extension User: JSONConvertible {
  convenience init(json: JSON) throws {
    try self.init(
      email: json.get("email"),
      password: json.get("password")
    )
  }
  
  func makeJSON() throws -> JSON {
    var json = JSON()
    try json.set("id", id)
    try json.set("email", email)
    try json.set("password", password.makeString())
    return json
  }
}

// MARK: HTTP
extension User: ResponseRepresentable { }

extension Request {
  func user() throws -> User {
    return try auth.assertAuthenticated()
  }
}
