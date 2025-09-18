// IntegrationCanister.mo
// Performs http outcalls to an off-chain Node.js bridge which persists to MongoDB.
// Uses ic.http_request for outbound POSTs. Contains retry helpers & JSON helpers.

import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";

actor IntegrationCanister {

  // Simple JSON stringify for known shapes (small helper)
  func jsonEscape(t : Text) : Text {
    // naive escape - for demonstration only
    Text.replace(t, "\\", "\\\\")
  };

  // Build a small JSON body for health record
  public func buildHealthPayload(userId : Text, recordId : Text, diagnosis : Text, treatment : Text, notes : Text, ts : Nat64) : Text {
    let body = "{";
    let parts = [
      "\"userId\": \"" # userId # "\"",
      "\"recordId\": \"" # recordId # "\"",
      "\"diagnosis\": \"" # diagnosis # "\"",
      "\"treatment\": \"" # treatment # "\"",
      "\"notes\": \"" # notes # "\"",
      "\"timestamp\": " # Nat.toText(ts)
    ];
    body #= Array.join<Text>(parts, ",") # "}";
    body
  };

  // Perform HTTP POST to endpoint (expects /sync/health or /sync/finance)
  public func postJson(endpoint : Text, body : Text) : async ?Text {
    let headers = [ ("Content-Type", "application/json") ];
    let blob = Blob.fromArray(Text.encodeUtf8(body));

    // Build request
    let req : HttpRequest = {
      url = endpoint;
      method = #post;
      headers = headers;
      body = ?blob;
    };

    Debug.print("postJson: posting to " # endpoint # " body len:" # Nat.toText(Array.size(blob)));
    let res = await ic.http_request(req);
    switch (res.body) {
      case (?b) {
        switch (Text.decodeUtf8(b)) {
          case (?txt) {
            Debug.print("postJson: success " # txt);
            ?txt
          };
          case null {
            Debug.print("postJson: decode error");
            null
          };
        }
      };
      case null {
        Debug.print("postJson: no body in response");
        null
      };
    }
  };

  // High level sync helper used by other canisters
  public func syncHealthToBridge(endpoint : Text, rec : Text) : async Bool {
    switch (await postJson(endpoint, rec)) {
      case (?_) true;
      case null false;
    }
  };

  // Example usage - will be invoked by frontend/local dev.
  public func demoSync() : async Text {
    let endpoint = "http://localhost:3000/sync/health";
    let payload = buildHealthPayload("user-1","demo-1","DemoDiag","DemoTreat","DemoNotes",1630009999);
    switch (await postJson(endpoint, payload)) {
      case (?r) r;
      case null "error";
    }
  };
};
