import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous tests remain unchanged]

Clarinet.test({
  name: "Ensure proper role management",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "game-guard",
        "create-community",
        [types.ascii("Test Gaming Community")],
        wallet_1.address
      ),
      Tx.contractCall(
        "game-guard",
        "join-community",
        [types.uint(1)],
        wallet_2.address
      ),
      Tx.contractCall(
        "game-guard",
        "update-member-role",
        [types.uint(1), types.principal(wallet_2.address), types.ascii("moderator")],
        wallet_1.address
      ),
    ]);
    
    assertEquals(block.receipts.length, 3);
    block.receipts[2].result.expectOk().expectBool(true);
  },
});
