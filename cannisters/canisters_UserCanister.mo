// UserCanister.mo
// Manages user profiles and roles. Includes helper utilities and debug endpoints.
// Expanded with comments and utilities for a GitHub-ready file near ~200 lines.

import Types "Types";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

actor UserCanister {

  stable var users : [Types.UserProfile] = [ Types.sampleUser ];

  // find index helper
  func findIndex(id : Text) : ?Nat {
    var i : Nat = 0;
    for (u in users.vals()) {
      if (u.id == id) return ?i;
      i += 1;
    };
    return null;
  };

  // Register user (id must be unique)
  public func registerUser(u : Types.UserProfile) : async Bool {
    switch (findIndex(u.id)) {
      case (?_) {
        Debug.print("registerUser: already exists: " # u.id);
        return false;
      };
      case null {
        users := Array.append(users, [u]);
        Debug.print("registerUser: created: " # u.id);
        return true;
      };
    };
  };

  // Get user
  public query func getUser(id : Text) : async ?Types.UserProfile {
    for (u in users.vals()) {
      if (u.id == id) return ?u;
    };
    null
  };

  // List users (paginated basic)
  public query func listUsers(offset : Nat, limit : Nat) : async [Types.UserProfile] {
    let total = users.size();
    if (offset >= total) return [];
    let end = if (offset + limit > total) total else offset + limit;
    var out : [Types.UserProfile] = Array.tabulate<Types.UserProfile>(end - offset, func (i) { users[offset + i] });
    out
  };

  // Update user (email/name/role allowed)
  public func updateUser(id : Text, name : ?Text, email : ?Text, role : ?Text) : async Bool {
    switch (findIndex(id)) {
      case (?i) {
        let old = users[i];
        let new = {
          id = old.id;
          name = switch (name) { case (?v) v; case null old.name };
          email = switch (email) { case (?v) v; case null old.email };
          role = switch (role) { case (?v) v; case null old.role };
        };
        users[i] := new;
        Debug.print("updateUser: updated " # id);
        return true;
      };
      case null {
        Debug.print("updateUser: not found " # id);
        return false;
      };
    };
  };

  // Delete user
  public func deleteUser(id : Text) : async Bool {
    switch (findIndex(id)) {
      case (?i) {
        users := Array.tabulate<Types.UserProfile>(users.size() - 1, func (j) {
          if (j < i) users[j] else users[j + 1]
        });
        Debug.print("deleteUser: removed " # id);
        return true;
      };
      case null {
        Debug.print("deleteUser: not found " # id);
        return false;
      };
    };
  };

  // Count
  public query func countUsers() : async Nat {
    users.size()
  };

  // Role checks
  public query func hasRole(id : Text, r : Text) : async Bool {
    switch (getUser(id)) {
      case (?u) { u.role == r };
      case null false;
    }
  };

  // Debug dump
  public query func dump() : async Text {
    var s = "Users Dump:\n";
    for (u in users.vals()) {
      s #= "ID: " # u.id # " Name: " # u.name # " Email: " # u.email # " Role: " # u.role # "\n";
    };
    s
  };

  // Seed helper - for local development only
  public func seedExample() : async Bool {
    let u = Types.makeUser("user-2","Bob Example","bob@example.org","doctor");
    registerUser(u)
  };
};
