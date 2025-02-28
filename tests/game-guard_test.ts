import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can create and update community",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "game-guard",
        "create-community",
        [types.ascii("Test Gaming Community")],
        wallet_1.address
      ),
      Tx.contractCall(
        "game-guard",
        "update-community",
        [types.uint(1), types.ascii("Updated Community Name")],
        wallet_1.address
      ),
    ]);
    
    assertEquals(block.receipts.length, 2);
    block.receipts[0].result.expectOk().expectUint(1);
    block.receipts[1].result.expectOk().expectBool(true);
  },
});

Clarinet.test({
  name: "Ensure proper treasury management",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "game-guard",
        "create-community",
        [types.ascii("Test Gaming Community")],
        wallet_1.address
      ),
      Tx.contractCall(
        "game-guard",
        "deposit",
        [types.uint(1), types.uint(1000)],
        wallet_1.address
      ),
      Tx.contractCall(
        "game-guard",
        "withdraw",
        [types.uint(1), types.uint(500)],
        wallet_1.address
      ),
    ]);
    
    assertEquals(block.receipts.length, 3);
    block.receipts[1].result.expectOk().expectBool(true);
    block.receipts[2].result.expectOk().expectBool(true);
  },
});
