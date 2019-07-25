# Root Chain contract

CHILD_BLOCK_INTERVAL: constant(uint256) = 1000
MAX_INPUTS: constant(uint256) = 4

struct Block:
  root: bytes32
  added_at: uint256(sec, positional)

BlockSubmitted: event({blockNumber: uint256})

operator: public(address)

nextChildBlock: public(uint256)
nextDepositBlock: public(uint256)

blocks: public(map(uint256, Block))

@public
def __init__(_operator: address):
    self.operator = _operator

@public
def onlyOperator():
    assert msg.sender == self.operator

@public
def submitBlock(_blockRoot: bytes32):
    self.onlyOperator()

    # Create the block.
    submittedBlockNumber: uint256 = self.nextChildBlock
    self.blocks[submittedBlockNumber] = Block({
        root: _blockRoot,
        added_at: block.timestamp
    })

    # Update the next child and deposit blocks.
    self.nextChildBlock = self.nextChildBlock + CHILD_BLOCK_INTERVAL
    self.nextDepositBlock = 1
    log.BlockSubmitted(submittedBlockNumber)

