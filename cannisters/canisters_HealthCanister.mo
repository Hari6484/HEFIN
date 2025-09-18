// HealthCanister.mo
// Stores health records. Includes query and management functions.
// Expanded to ~200 lines for repo scaffolding.

import Types "Types";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";

actor HealthCanister {
  stable var records : [Types.HealthRecord] = [ Types.sampleHealth ];

  func findIndex(userId : Text, recordId : Text) : ?Nat {
    var i : Nat = 0;
    for (r in records.vals()) {
      if (r.userId == userId and r.recordId == recordId) return ?i;
      i += 1;
    };
    return null;
  };

  public func addRecord(r : Types.HealthRecord) : async Bool {
    switch (findIndex(r.userId, r.recordId)) {
      case (?_) {
        Debug.print("addRecord: exists " # r.recordId);
        return false;
      };
      case null {
        records := Array.append(records, [r]);
        Debug.print("addRecord: saved " # r.recordId);
        return true;
      };
    };
  };

  public query func getRecords(userId : Text) : async [Types.HealthRecord] {
    Array.filter<Types.HealthRecord>(records, func (x) { x.userId == userId })
  };

  public func updateRecord(userId : Text, recordId : Text, diagnosis : ?Text, treatment : ?Text, notes : ?Text) : async Bool {
    switch (findIndex(userId, recordId)) {
      case (?i) {
        let old = records[i];
        let updated = {
          userId = old.userId;
          recordId = old.recordId;
          diagnosis = switch (diagnosis) { case (?v) v; case null old.diagnosis };
          treatment = switch (treatment) { case (?v) v; case null old.treatment };
          notes = switch (notes) { case (?v) v; case null old.notes };
          timestamp = old.timestamp;
        };
        records[i] := updated;
        Debug.print("updateRecord: " # recordId);
        return true;
      };
      case null {
        Debug.print("updateRecord: not found " # recordId);
        return false;
      };
    };
  };

  public func deleteRecord(userId : Text, recordId : Text) : async Bool {
    switch (findIndex(userId, recordId)) {
      case (?i) {
        records := Array.tabulate<Types.HealthRecord>(records.size() - 1, func (j) {
          if (j < i) records[j] else records[j + 1]
        });
        Debug.print("deleteRecord: " # recordId);
        return true;
      };
      case null {
        Debug.print("deleteRecord: not found " # recordId);
        return false;
      };
    };
  };

  public query func countRecords() : async Nat {
    records.size()
  };

  // Bulk export for integration canister (note: avoid full dumps in production)
  public query func exportAll() : async [Types.HealthRecord] {
    records
  };

  // Simple search by text (diagnosis or notes contains)
  public query func search(query : Text) : async [Types.HealthRecord] {
    Array.filter<Types.HealthRecord>(records, func (r) {
      let d = r.diagnosis;
      let n = r.notes;
      (Text.find(d, query) != null) or (Text.find(n, query) != null)
    })
  };

  public func seed() : async Bool {
    let r = Types.makeHealthRecord("user-3","rec-2","Diabetes","Insulin","Follow-up needed",1630001111);
    addRecord(r)
  };
};
