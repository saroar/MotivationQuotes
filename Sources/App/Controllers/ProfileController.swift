//
//  ProfileController.swift
//  MotivationQuotes
//
//  Created by Alif on 20/06/2017.
//
//

import Vapor
import HTTP
import AuthProvider
import JWT

final class ProfileController: ResourceRepresentable {

  func index(req: Request) throws -> ResponseRepresentable {
    return try Profile.all().makeJSON()
  }
  
  func create(request: Request) throws -> ResponseRepresentable {
    let profile = try request.profile()
    print(profile)
    try profile.save()
    return profile
  }
  
  func show(req: Request, profile: Profile) throws -> ResponseRepresentable {
    return profile
  }
  
  func update(req: Request, profile: Profile) throws -> ResponseRepresentable {
    try profile.update(for: req)
    try profile.save()
    return profile
  }
  
  func makeResource() -> Resource<Profile> {
    return Resource(
      index: index,
      store: create,
      show: show,
      update: update
    )
  }
}

extension Request {
  func profile() throws -> Profile {
    guard let json = json else { throw Abort.badRequest }
    return try Profile(json: json)
  }
}

extension ProfileController: EmptyInitializable { }
