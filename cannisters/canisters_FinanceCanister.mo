// FinanceCanister.mo
// Stores finance transactions & claims. Includes utility functions and export hooks.

import Types "Types";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";

actor FinanceCanister {
  stable var txns : [Types.FinancialRecord] = [ Types.sampleFinance ];

  func findIndex(userId : Text, txnId : Text) : ?Nat {
    var i : Nat = 0;
    for (t in txns.vals()) {
      if (t.userId == userId and t.txnId == txnId) return ?i;
      i += 1;
    };
    return null;
  };

  public func addTransaction(t : Types.FinancialRecord) : async Bool {
    switch (findIndex(t.userId, t.txnId)) {
      case (?_) {
        Debug.print("addTransaction: exists " # t.txnId);
        return false;
      };
      case null {
        txns := Array.append(txns, [t]);
        Debug.print("addTransaction: saved " # t.txnId);
        return true;
      };
    };
  };

  public query func getTransactions(userId : Text) : async [Types.FinancialRecord] {
    Array.filter<Types.FinancialRecord>(txns, func (x) { x.userId == userId })
  };

  public func updateTransaction(userId : Text, txnId : Text, amount : ?Float, category : ?Text, meta : ?Text) : async Bool {
    switch (findIndex(userId, txnId)) {
      case (?i) {
        let old = txns[i];
        let updated = {
          userId = old.userId;
          txnId = old.txnId;
          amount = switch (amount) { case (?v) v; case null old.amount };
          currency = old.currency;
          category = switch (category) { case (?v) v; case null old.category };
          meta = switch (meta) { case (?v) v; case null old.meta };
          timestamp = old.timestamp;
        };
        txns[i] := updated;
        Debug.print("updateTransaction: " # txnId);
        return true;
      };
      case null {
        Debug.print("updateTransaction: not found " # txnId);
        return false;
      };
    };
  };

  public func deleteTransaction(userId : Text, txnId : Text) : async Bool {
    switch (findIndex(userId, txnId)) {
      case (?i) {
        txns := Array.tabulate<Types.FinancialRecord>(txns.size() - 1, func (j) {
          if (j < i) txns[j] else txns[j + 1]
        });
        Debug.print("deleteTransaction: " # txnId);
        return true;
      };
      case null {
        Debug.print("deleteTransaction: not found " # txnId);
        return false;
      };
    };
  };

  public query func countTxns() : async Nat {
    txns.size()
  };

  public query func exportAll() : async [Types.FinancialRecord] {
    txns
  };

  public func seed() : async Bool {
    let t = Types.makeFinancialRecord("user-4","txn-2",250.0,"USD","payment","Premium paid",1630002222);
    addTransaction(t)
  };
};
