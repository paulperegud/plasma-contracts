import rlp
from rlp.sedes import big_endian_int, binary, CountableList
import eth_utils as utils
from plasma_core.constants import NULL_SIGNATURE, NULL_ADDRESS
from plasma_core.utils.eip712_struct_hash import hash_struct
from plasma_core.utils.signatures import sign, get_signer
from plasma_core.utils.transactions import encode_utxo_id
from rlp.exceptions import (SerializationError, DeserializationError)


def pad_list(to_pad, value, required_length):
    return to_pad + [value] * (required_length - len(to_pad))

address = rlp.sedes.Binary.fixed_length(20, allow_empty=True)

class TransactionInput(rlp.Serializable):

    fields = (
        ('blknum', big_endian_int),
        ('txindex', big_endian_int),
        ('oindex', big_endian_int)
    )

    @property
    def identifier(self):
        return encode_utxo_id(self.blknum, self.txindex, self.oindex)

class TransactionOutput(rlp.Serializable):

    fields = (
        ('owner', address),
        ('token', address),
        ('amount', big_endian_int)
    )

    def __init__(self, owner=NULL_ADDRESS, token=NULL_ADDRESS, amount=0):
        self.owner = utils.normalize_address(owner)
        self.token = utils.normalize_address(token)
        self.amount = amount


class Transaction(rlp.Serializable):

    NUM_TXOS = 4
    DEFAULT_INPUT = (0, 0, 0)
    DEFAULT_OUTPUT = (NULL_ADDRESS, NULL_ADDRESS, 0)
    fields = (
        ('inputs', CountableList(TransactionInput, NUM_TXOS)),
        ('outputs', CountableList(TransactionOutput, NUM_TXOS)),
        ('metadata', binary)
    )

    def __init__(self,
                 inputs=[DEFAULT_INPUT] * NUM_TXOS,
                 outputs=[DEFAULT_OUTPUT] * NUM_TXOS,
                 metadata=None,
                 signatures=[NULL_SIGNATURE] * NUM_TXOS,
                 signers=[NULL_ADDRESS] * NUM_TXOS):
        assert all(len(o) == 3 for o in outputs)
        padded_inputs = pad_list(inputs, self.DEFAULT_INPUT, self.NUM_TXOS)
        padded_outputs = pad_list(outputs, self.DEFAULT_OUTPUT, self.NUM_TXOS)

        self.inputs = [TransactionInput(*i) for i in padded_inputs]
        self.outputs = [TransactionOutput(*o) for o in padded_outputs]
        self.metadata = metadata
        self.signatures = signatures[:]
        self._signers = signers[:]
        self.spent = [False] * self.NUM_TXOS

    @property
    def hash(self):
        return utils.sha3(self.encoded)

    @property
    def signers(self):
        return self._signers

    @property
    def encoded(self):
        return rlp.encode(self)

    @property
    def is_deposit(self):
        return all([i.blknum == 0 for i in self.inputs])

    def sign(self, index, key, verifyingContract=None):
        hash = hash_struct(self, verifyingContract=verifyingContract)
        sig = sign(hash, key)
        self.signatures[index] = sig
        self._signers[index] = get_signer(hash, sig) if sig != NULL_SIGNATURE else NULL_ADDRESS

    @staticmethod
    def serialize(obj):
        try:
            cls = Transaction.exclude(['metadata']) if obj.metadata is None else Transaction
            field_value = [getattr(obj, field) for field, _ in cls.fields]
            ret = cls.get_sedes().serialize(field_value)
            return ret
        except Exception as e:
            raise SerializationError(e.format_exc, obj)

    @staticmethod
    def deserialize(obj):
        raise DeserializationError("not yet implemented", obj)
