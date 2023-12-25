import Nat64 "mo:base/Nat64";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Ledger "canister:ledger";


shared(msg) actor class CashReturn() {
  // Ledger to record the amount of tokens paid from each sender
  private var ledger : HashMap.HashMap<Principal, Nat64> = HashMap.HashMap<Principal, Nat64>(100, Principal.equal, Principal.hash);
  private var currentPrice : Nat64 = 0;
  let owner = msg.caller;

  public type AccountIdentifier = Blob;

  private func sendICP(recipient: Principal, amount: Nat64): async Bool {
    let args = {
      to = recipient;
      fee = { e8s = 10_000}; // The transaction fee, specified in e8s (10,000 e8s = 0.0001 ICP)
      memo = 0;     // An optional memo for the transaction
      from_subaccount = null; // This can be set if you are using subaccounts
      created_at_time = null; // Timestamp, can be set to ensure transaction uniqueness
      amount = {
        e8s = amount;
      };
    };
    let response = await Ledger.transfer(args);

    return true;
  };

  // Function to receive ICP tokens
  public func receiveTokens(amount: Nat64, sender: Principal) {
      ledger.put(sender, amount);
  };

  public query func checkPrice(principal: Principal) : async Nat64 {
      return currentPrice;
  };

    public shared(msg) func setPrice(newPrice: Nat64) {
        assert (owner == msg.caller);
        currentPrice := newPrice;
        // if the new price is lower than the old price,
        // we need to refund the difference
        for ((payer, amount) in ledger.entries()) {
            if (amount >= newPrice) {
                let refund = Nat64.sub(amount, newPrice);
                if (refund > 0) {
                    ledger.put(payer, newPrice);
                    sendICP(payer, refund);
                }
            }
        }
    };

}

