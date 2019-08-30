pragma solidity ^0.4.0;
pragma experimental ABIEncoderV2;

import "./ByteUtils.sol";
import "./RLP.sol";
import "./ECRecovery.sol";


/**
 * @title PlasmaCore
 * @dev Utilities for working with and decoding Plasma MVP transactions.
 */
library PlasmaCore {
    using ByteUtils for bytes;
    using RLP for bytes;
    using RLP for RLP.RLPItem;


    /*
     * Storage
     */
    uint256 constant internal NUM_TXS = 4;
    uint256 constant internal BLOCK_OFFSET = 1000000000;
    uint256 constant internal TX_OFFSET = 10000;
    uint256 constant internal PROOF_SIZE_BYTES = 512;
    uint256 constant internal SIGNATURE_SIZE_BYTES = 65;

    struct TransactionInput {
        uint256 blknum;
        uint256 txindex;
        uint256 oindex;
    }

    struct TransactionOutput {
        bytes32 guard;
        address token;
        uint256 amount;
    }

    struct Transaction {
        uint256 txtype;
        TransactionInput[NUM_TXS] inputs;
        TransactionOutput[NUM_TXS] outputs;
        bytes32 metadata;
    }


    /*
     * Internal functions
     */

    /**
     * @dev Decodes an RLP encoded transaction.
     * @param _tx RLP encoded transaction.
     * @return Decoded transaction.
     */
    function decode(bytes memory _tx)
        internal
        view
        returns (Transaction)
    {
        RLP.RLPItem[] memory txList = _tx.toRLPItem().toList();
        require(txList.length == 4);

        Transaction memory decodedTx;
        decodedTx.txtype = txList[0].toUint();
        RLP.RLPItem[] memory inputs = txList[1].toList();
        RLP.RLPItem[] memory outputs = txList[2].toList();
        decodedTx.metadata = txList[3].toBytes32();
        bool[] memory emptySeen = new bool[](2);

        for (uint i = 0; i < NUM_TXS; i++) {
            RLP.RLPItem[] memory input = inputs[i].toList();
            decodedTx.inputs[i] = TransactionInput({
                blknum: input[0].toUint(),
                txindex: input[1].toUint(),
                oindex: input[2].toUint(),
                signer: input[3].toAddress()
            });

            // check for empty inputs - disallow gaps
            if (decodedTx.inputs[i].blknum == 0
              && decodedTx.inputs[i].txindex == 0
              && decodedTx.inputs[i].oindex == 0) emptySeen[0] = true;
            else require(emptySeen[0] == false, "Gaps in inputs are not allowed ");

            RLP.RLPItem[] memory output = outputs[i].toList();
            decodedTx.outputs[i] = TransactionOutput({
                guard: output[0].toBytes32(),
                token: output[1].toAddress(),
                amount: output[2].toUint()
            });

            // check for empty outputs - disallow gaps
            if (decodedTx.outputs[i].guard == 0
             && decodedTx.outputs[i].token == 0
             && decodedTx.outputs[i].amount == 0) emptySeen[1] = true;
            else require(emptySeen[1] == false, "Gaps in outputs are not allowed ");
        }

        return decodedTx;
    }

    /**
     * @dev Given an UTXO position, returns the block number.
     * @param _utxoPos Output identifier to decode.
     * @return The output's block number.
     */
    function getBlknum(uint256 _utxoPos)
        internal
        pure
        returns (uint256)
    {
        return _utxoPos / BLOCK_OFFSET;
    }

    /**
     * @dev Given an UTXO position, returns the transaction index.
     * @param _utxoPos Output identifier to decode.
     * @return The output's transaction index.
     */
    function getTxIndex(uint256 _utxoPos)
        internal
        pure
        returns (uint256)
    {
        return (_utxoPos % BLOCK_OFFSET) / TX_OFFSET;
    }

    /**
     * @dev Given an UTXO position, returns the output index.
     * @param _utxoPos Output identifier to decode.
     * @return The output's index.
     */
    function getOindex(uint256 _utxoPos)
        internal
        pure
        returns (uint8)
    {
        return uint8(_utxoPos % TX_OFFSET);
    }

    /**
     * @dev Given an UTXO position, returns transaction position.
     * @param _utxoPos Output identifier to decode.
     * @return The transaction position.
     */
    function getTxPos(uint256 _utxoPos)
        internal
        pure
        returns (uint256)
    {
        return _utxoPos / TX_OFFSET;
    }

    /**
     * @dev Returns the identifier for an input to a transaction.
     * @param _tx RLP encoded input.
     * @param _inputIndex Index of the input to return.
     * @return A combined identifier.
     */
    function getInputUtxoPosition(bytes memory _tx, uint8 _inputIndex)
        internal
        view
        returns (uint256)
    {
        Transaction memory decodedTx = decode(_tx);
        TransactionInput memory input = decodedTx.inputs[_inputIndex];
        return input.blknum * BLOCK_OFFSET + input.txindex * TX_OFFSET + input.oindex;
    }

    /**
     * @dev Returns an output to a transaction.
     * @param _tx RLP encoded transaction.
     * @param _outputIndex Index of the output to return.
     * @return The transaction output.
     */
    function getOutput(bytes memory _tx, uint8 _outputIndex)
        internal
        view
        returns (TransactionOutput)
    {
        Transaction memory decodedTx = decode(_tx);
        return decodedTx.outputs[_outputIndex];
    }

    /**
     * @dev Slices a signature off a list of signatures.
     * @param _signatures A list of signatures in bytes form.
     * @param _index Which signature to slice.
     * @return A signature in bytes form.
     */
    function sliceSignature(bytes memory _signatures, uint256 _index)
        internal
        pure
        returns (bytes)
    {
        return _sliceOne(_signatures, SIGNATURE_SIZE_BYTES, _index);
    }

    /* function checkConfirmSig(bytes _confirmSigs, uint256 txType, TransactionInput[4] memory inputs, bytes32 blockroot) */
    /*     view */
    /* { */
    /*     address[NUM_TXS] memory signers; */
    /*     // get signers */
    /*     for (uint i = 0; i < NUM_TXS; i++) { */
    /*         if (inputs[i].blknum == 0) break; */
    /*         signers[i] = ECRecovery.recover(blockroot, sliceSignature(_confirmSigs, i)); */
    /*     } */

    /*     // check if for every input there exits a valid signature from a signer */
    /*     for (i = 0; i < NUM_TXS; i++) { */
    /*         for (uint j = 0; j < NUM_TXS; j++) { */
    /*             if (inputs[i].blknum == 0) break; */
    /*             if (inputs[i].signer == signers[j]) continue; */
    /*         } */
    /*         require(false, "Missing confirmation signature"); */
    /*     } */
    /* } */


    /**
     * @dev Slices a Merkle proof off a list of proofs.
     * @param _proofs A list of proofs in bytes form.
     * @param _index Which proof to slice.
     * @return A proof in bytes form.
     */
    function sliceProof(bytes memory _proofs, uint256 _index)
        internal
        pure
        returns (bytes)
    {
        return _sliceOne(_proofs, PROOF_SIZE_BYTES, _index);
    }


    /*
     * Private functions
     */

    /**
     * @dev Slices an element off a list of equal-sized elements in bytes form.
     * @param _list A list of equal-sized elements in bytes.
     * @param _length Size of each item.
     * @param _index Which item to slice.
     * @return A single element at the specified index.
     */
    function _sliceOne(bytes memory _list, uint256 _length, uint256 _index)
        private
        pure
        returns (bytes)
    {
        return _list.slice(_length * _index, _length);
    }
}
