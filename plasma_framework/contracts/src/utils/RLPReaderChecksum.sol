pragma solidity ^0.5.0;

/**
 * @author pepesza, paulperegud@gmail.com
 * @dev helps to check if RLP decoding as implemented in RLPReader is one-to-one
 */

import "../../src/utils/RLPReader.sol";

contract RLPReaderChecksum {

    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    function please_throw(uint256 input)
        public
        pure
        returns (bytes32)
    {
        require(input == 5);
        return bytes32(0);
    }

    function decodeAndChecksum(bytes memory _data)
        public
        pure
        returns (bytes32)
    {
        RLPReader.RLPItem memory item = _data.toRlpItem();
        return walk(item, bytes32(0));
    }

    function walk(RLPReader.RLPItem memory node, bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        if (node.isList()) {
            RLPReader.RLPItem[] memory list = node.toList();
            for (uint i = 0; i < list.length; i++) {
                RLPReader.RLPItem memory item = list[i];
                hash = walk(item, hash);
            }
            // To distinguish between [1, [2]] and [1,2]
            // add a marker when going up in the tree.
            return keccak256(abi.encodePacked(hash, uint256(1)));
        }
        return keccak256(abi.encodePacked(hash, node.toUint()));
    }
}
