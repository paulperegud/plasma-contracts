"""
Regression test for bug in RLP decoder.
"""

import pytest
import rlp

from eth_utils import encode_hex

from rlp.sedes import big_endian_int
import eth_utils as utils

address = rlp.sedes.Binary.fixed_length(20, allow_empty=True)


class Eight(rlp.Serializable):
    fields = [
        ('f0', big_endian_int),
        ('f1', big_endian_int),
        ('f2', big_endian_int),
        ('f3', big_endian_int),
        ('f4', big_endian_int),
        ('f5', big_endian_int),
        ('f6', address),
        ('f7', address)
    ]


class Eleven(rlp.Serializable):
    fields = [
        ('f0', big_endian_int),
        ('f1', big_endian_int),
        ('f2', big_endian_int),
        ('f3', big_endian_int),
        ('f4', big_endian_int),
        ('f5', big_endian_int),
        ('f6', big_endian_int),
        ('f7', big_endian_int),
        ('f8', address),
        ('f9', address),
        ('f10', address)
    ]


@pytest.fixture
def rlp_test(ethtester, get_contract):
    contract = get_contract('RLPTest')
    ethtester.chain.mine()
    return contract


def test_rlp_tx_eight(ethtester, rlp_test):
    tx = Eight(0, 1, 2, 3, 4, 5, ethtester.a0, ethtester.a1)
    tx_bytes = rlp.encode(tx, Eight)
    assert [5, encode_hex(ethtester.a0), encode_hex(ethtester.a1)] == rlp_test.eight(tx_bytes)


def test_rlp_tx_eleven(ethtester, rlp_test):
    tx = Eleven(0, 1, 2, 3, 4, 5, 6, 7, ethtester.a0, ethtester.a1, ethtester.a2)
    tx_bytes = rlp.encode(tx, Eleven)
    assert [7, encode_hex(ethtester.a0), encode_hex(ethtester.a1), encode_hex(ethtester.a2)] == rlp_test.eleven(tx_bytes)
