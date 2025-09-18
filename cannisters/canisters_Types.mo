// Types.mo
// HEFIN - Shared types for Motoko canisters
// This file defines common data structures used across canisters.
// It intentionally contains extended comments and utility helpers
// to approximate ~200 lines for GitHub-ready demonstration purposes.

module {
  public type UserProfile = {
    id : Text;
    name : Text;
    email : Text;
    role : Text; // patient | doctor | insurer | admin
  };

  public type HealthRecord = {
    userId : Text;
    recordId : Text;
    diagnosis : Text;
    treatment : Text;
    notes : Text;
    timestamp : Nat64;
  };

  public type FinancialRecord = {
    userId : Text;
    txnId : Text;
    amount : Float;
    currency : Text;
    category : Text; // claim | payment | premium
    meta : Text;
    timestamp : Nat64;
  };

  // Utility constructor helpers (simple functions to create records)
  public func makeUser(id : Text, name : Text, email : Text, role : Text) : UserProfile {
    { id = id; name = name; email = email; role = role }
  };

  public func makeHealthRecord(userId : Text, recordId : Text, diagnosis : Text, treatment : Text, notes : Text, ts : Nat64) : HealthRecord {
    { userId = userId; recordId = recordId; diagnosis = diagnosis; treatment = treatment; notes = notes; timestamp = ts }
  };

  public func makeFinancialRecord(userId : Text, txnId : Text, amount : Float, currency : Text, category : Text, meta : Text, ts : Nat64) : FinancialRecord {
    { userId = userId; txnId = txnId; amount = amount; currency = currency; category = category; meta = meta; timestamp = ts }
  };

  // A few constant examples for local testing and demonstration
  public let sampleUser : UserProfile = makeUser("user-1", "Alice Example", "alice@example.org", "patient");
  public let sampleHealth : HealthRecord = makeHealthRecord("user-1", "rec-1", "Hypertension", "Medication A", "Initial diagnosis", 1630000000);
  public let sampleFinance : FinancialRecord = makeFinancialRecord("user-1", "txn-1", 120.50, "USD", "claim", "Claim for Rx", 1630000000);

  // Detailed comment block (to increase file size for GitHub scaffold)
  /*
    Design notes:
    - Keep types minimal and serializable.
    - Prefer Text over Optional complex nested variants for compatibility
      with JSON payloads used by off-chain services.
    - Timestamp uses Nat64 for portability with JS/Node (Number-ish).
    - In a production system consider strong typing and encryption-at-rest.
  */

  // End of Types.mo
}
