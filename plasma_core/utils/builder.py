from vyper import compiler
from ethereum.tools import tester

# Get a new chain
chain = tester.Chain()
# Set the vyper compiler to run when the vyper language is requested
tester.languages['vyper'] = compiler.Compiler()

with open('my_contract.vy' 'r') as f:
    source_code = f.read()
# Compile and Deploy contract to provisioned testchain
# (e.g. run __init__ method) with given args (e.g. init_args)
# from msg.sender = t.k1 (private key of address 1 in test acconuts)
# and supply 1000 wei to the contract
init_args = ['arg1', 'arg2', 3]
contract = chain.contract(source_code, language="vyper",
        init_args, sender=t.k1, value=1000)

contract.myMethod() # Executes myMethod on the tester "chain"
chain.mine() # Mines the above transaction (and any before it) into a block
