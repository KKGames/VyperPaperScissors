from eth_tester import EthereumTester
import json
from pprint import pprint

import web3


from web3 import Web3
from web3.contract import ConciseContract

# https://pypi.org/project/eth-tester/

# https://web3py.readthedocs.io/en/stable/contracts.html

t = EthereumTester()
accounts = t.get_accounts()

# web3.py instance
w3 = Web3(Web3.EthereumTesterProvider())
w3.eth.defaultAccount = w3.eth.accounts[0]

with open('rps.bin') as deployCode:
    bytecode = deployCode.read()
    bytecode = hex(int(bytecode, 16))
    pprint(bytecode)

with open('rps.json') as abiCode:
    abi = json.load(abiCode)
    abiCode.close()
    # pprint(abi)

print("owner is " + accounts[0])


# Instantiate and deploy contract
RPS = w3.eth.contract(abi=abi, bytecode=bytecode)
txHash = RPS.constructor().transact()

# receipt = t.get_transaction_receipt(txHash)
tx_receipt = w3.eth.waitForTransactionReceipt(txHash)

rpsAddress = tx_receipt.contractAddress

# Instantiate contract
rps = w3.eth.contract(address=rpsAddress, abi=abi)
pprint("contract address: " + str(rps.address))
pprint(rps.abi)

# Use concise contract for easier reading
rps = ConciseContract(rps)
assert rps.owner() == accounts[0]

# First game
password = Web3.sha3(text="password")
hashedMove = rps.getHashedMove(1, password)
pprint(hashedMove)

challenger = accounts[1]
bastard = accounts[2]
# txHash = rps.challenge(bastard, hashedMove, {"value": 100, "from": challenger})

# assert rps.functions.owner().call() == accounts[0]
