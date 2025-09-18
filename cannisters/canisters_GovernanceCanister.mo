// GovernanceCanister.mo
// Simple DAO-style governance stub for HEFIN.
// Includes proposals, voting, and simple execution simulation.
// Expanded comments and helper utilities to reach ~200 lines.

import Text "mo:base/Text";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";

actor GovernanceCanister {

  public type Proposal = {
    id : Text;
    title : Text;
    description : Text;
    proposer : Text;
    votesFor : Nat;
    votesAgainst : Nat;
    executed : Bool;
  };

  stable var proposals : [Proposal] = [];

  func findIndex(id : Text) : ?Nat {
    var i : Nat = 0;
    for (p in proposals.vals()) {
      if (p.id == id) return ?i;
      i += 1;
    };
    null
  };

  public func submitProposal(id : Text, title : Text, description : Text, proposer : Text) : async Bool {
    switch (findIndex(id)) {
      case (?_) {
        Debug.print("submitProposal: exists " # id);
        return false;
      };
      case null {
        proposals := Array.append(proposals, [{ id = id; title = title; description = description; proposer = proposer; votesFor = 0; votesAgainst = 0; executed = false }]);
        Debug.print("submitProposal: " # id);
        return true;
      };
    }
  };

  public func vote(id : Text, support : Bool) : async Bool {
    switch (findIndex(id)) {
      case (?i) {
        let p = proposals[i];
        if (support) p.votesFor += 1 else p.votesAgainst += 1;
        proposals[i] := p;
        Debug.print("vote: " # id # " support:" # (if support then "yes" else "no"));
        return true;
      };
      case null {
        Debug.print("vote: not found " # id);
        return false;
      };
    }
  };

  public query func tally(id : Text) : async ?Text {
    switch (findIndex(id)) {
      case (?i) {
        let p = proposals[i];
        ?("For: " # Nat.toText(p.votesFor) # " Against: " # Nat.toText(p.votesAgainst));
      };
      case null null;
    }
  };

  public func execute(id : Text) : async Bool {
    switch (findIndex(id)) {
      case (?i) {
        let p = proposals[i];
        if (p.executed) {
          Debug.print("execute: already executed " # id);
          return false;
        };
        // naive majority rule
        if (p.votesFor > p.votesAgainst) {
          Debug.print("execute: executing " # id);
          proposals[i].executed := true;
          return true;
        } else {
          Debug.print("execute: majority not reached " # id);
          return false;
        };
      };
      case null {
        Debug.print("execute: not found " # id);
        return false;
      };
    }
  };

  public query func listProposals() : async [Proposal] {
    proposals
  };

  public func seedProposal() : async Bool {
    submitProposal("prop-1","Initial funding","Seed the project with initial funds","alice")
  };
};
