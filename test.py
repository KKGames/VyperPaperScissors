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
    # pprint(bytecode)

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


# Use concise contract for easier reading
rps = ConciseContract(rps)
assert rps.owner() == accounts[0]

# --------------First game------------------
# Rock = 0, Paper = 1, Scissors = 2
# Evaluation: 1 = win, 2 = draw, 3 = loss  (from perspective of player 1)

class Player(object):
    """docstring for Player."""
    def __init__(self, arg):
        super(Player, self).__init__()
        self.arg = arg

class Game(object):
    """docstring for Game."""
    def __init__(self, arg):
        super(Game, self).__init__()
        self.arg = arg

# setup up move and password and players
gameOne = Game(object)
playerOne = Player(object)
bastard = Player(object)
playerOne.address = accounts[1]
bastard.address = accounts[2]
gameOne.challenger = playerOne
gameOne.challengee = bastard
gameOne.gameHash = rps.getGameHash(bastard.address, playerOne.address)
gameOne.wager = 100

playerOne.password = Web3.sha3(text="password")
playerOne.move = 1 # paper
playerOne.hashedMove = rps.getHashedMove(playerOne.move, playerOne.password)



# challenge bastard
txHash = rps.challenge(bastard.address, playerOne.hashedMove, transact={"value": gameOne.wager, "from": playerOne.address})
gameOne.state = 1
pprint("player one challenges using paper with wei amount " + str(gameOne.wager))
# Check variables set properly
assert rps.getGameWager(gameOne.gameHash) == 100
assert rps.getGameHashedMove(gameOne.gameHash, playerOne.address) == playerOne.hashedMove
assert rps.getGameState(gameOne.gameHash) == gameOne.state

# Accept challenge
bastard.password = Web3.sha3(text="greatpassword")
bastard.move = 2   #scissors
bastard.hashedMove = rps.getHashedMove(bastard.move, bastard.password)
txHash = rps.acceptChallenge(playerOne.address, bastard.hashedMove, transact={"value": gameOne.wager, "from": bastard.address})
gameOne.state += 1
pprint("bastard accepts challenge using scissors with wei amount " + str(gameOne.wager))
# Check variables
assert rps.getGameHashedMove(gameOne.gameHash, bastard.address) == bastard.hashedMove
assert rps.getGameState(gameOne.gameHash) == gameOne.state

# Finalize player one move
txHash = rps.finalizeMove(bastard.address, playerOne.move, playerOne.password, transact={"from": playerOne.address})
gameOne.state += 1
assert rps.getGameOpenMove(gameOne.gameHash, playerOne.address) == playerOne.move
assert rps.getGameState(gameOne.gameHash) == gameOne.state

# Finalize bastard move
txHash = rps.finalizeMove(playerOne.address, bastard.move, bastard.password, transact={"from": bastard.address})
assert rps.getGameOpenMove(gameOne.gameHash, bastard.address) == bastard.move
assert rps.getGameState(gameOne.gameHash) == 0
# Check monies were sorted out properly (bastard wins)

assert rps.moneys(bastard.address) == (gameOne.wager * 2)
assert rps.moneys(playerOne.address) == 0
assert rps.moneys(accounts[0]) == 0
gameOne.state = 0
pprint("bastard won and is now owed " + str(gameOne.wager * 2))

# withdraw bastard winnings
txHash = rps.withdraw(transact={"from": bastard.address})
assert rps.moneys(bastard.address) == 0


# Create same game but reverse challenger challengee role
txHash = rps.challenge(playerOne.address, bastard.hashedMove, transact={"value": gameOne.wager, "from": bastard.address})
txHash = rps.acceptChallenge(bastard.address, playerOne.hashedMove, transact={"value": gameOne.wager, "from": playerOne.address})
txHash = rps.finalizeMove(bastard.address, playerOne.move, playerOne.password, transact={"from": playerOne.address})
txHash = rps.finalizeMove(playerOne.address, bastard.move, bastard.password, transact={"from": bastard.address})
assert rps.moneys(bastard.address) == (gameOne.wager * 2)
assert rps.moneys(playerOne.address) == 0
assert rps.moneys(accounts[0]) == 0
txHash = rps.withdraw(transact={"from": bastard.address})
assert rps.moneys(bastard.address) == 0


# create rock player
theRock = Player(object)
theRock.move = 0
theRock.address = accounts[3]
theRock.password = Web3.sha3(text="smellwhatheiscooking")
theRock.hashedMove = rps.getHashedMove(theRock.move, theRock.password)
gameTwo = Game(object)
gameTwo.wager = 69
gameTwo.gameHash = rps.getGameHash(theRock.address, bastard.address)


# Rock beats bastard  (rock vs scissors)
txHash = rps.challenge(bastard.address, theRock.hashedMove, transact={"value": gameTwo.wager, "from": theRock.address})
txHash = rps.acceptChallenge(theRock.address, bastard.hashedMove, transact={"value": gameTwo.wager, "from": bastard.address})
txHash = rps.finalizeMove(bastard.address, theRock.move, theRock.password, transact={"from": theRock.address})
txHash = rps.finalizeMove(theRock.address, bastard.move, bastard.password, transact={"from": bastard.address})
assert rps.moneys(bastard.address) == 0
assert rps.moneys(theRock.address) == (gameTwo.wager * 2)
txHash = rps.withdraw(transact={"from": theRock.address})
assert rps.moneys(bastard.address) == 0
pprint("The rock has beat bastard  (rock vs scissors)")


# Rock gets beat by playerOne  (rock vs paper)
gameThree = Game(object)
gameThree.wager = 11
gameThree.gameHash = rps.getGameHash(theRock.address, playerOne.address)

txHash = rps.challenge(playerOne.address, theRock.hashedMove, transact={"value": gameThree.wager, "from": theRock.address})
txHash = rps.acceptChallenge(theRock.address, playerOne.hashedMove, transact={"value": gameThree.wager, "from": playerOne.address})
txHash = rps.finalizeMove(playerOne.address, theRock.move, theRock.password, transact={"from": theRock.address})
txHash = rps.finalizeMove(theRock.address, playerOne.move, playerOne.password, transact={"from": playerOne.address})
assert rps.moneys(playerOne.address) == (gameThree.wager * 2)
assert rps.moneys(theRock.address) == 0
txHash = rps.withdraw(transact={"from": playerOne.address})
assert rps.moneys(playerOne.address) == 0
pprint("The rock has been beat by playerOne  (rock vs paper)")


# Rock ties RockTwo
theRockTwo = Player(object)
theRockTwo.move = 0
theRockTwo.address = accounts[4]
theRockTwo.password = Web3.sha3(text="smellycook")
theRockTwo.hashedMove = rps.getHashedMove(theRockTwo.move, theRockTwo.password)

tieGame = Game(object)
tieGame.wager = 100   # TODO: make random number and add math.floor to assertions
tieGame.gameHash = rps.getGameHash(theRock.address, theRockTwo.address)
# the rock challenges rockTwo
txHash = rps.challenge(theRockTwo.address, theRock.hashedMove, transact={"value": tieGame.wager, "from": theRock.address})
txHash = rps.acceptChallenge(theRock.address, theRockTwo.hashedMove, transact={"value": tieGame.wager, "from": theRockTwo.address})
# the rock reveals move
txHash = rps.finalizeMove(theRockTwo.address, theRock.move, theRock.password, transact={"from": theRock.address})
assert rps.getGameState(tieGame.gameHash) == 3
txHash = rps.finalizeMove(theRock.address, theRockTwo.move, theRockTwo.password, transact={"from": theRockTwo.address})
assert rps.moneys(theRockTwo.address) == (tieGame.wager * .9)
assert rps.moneys(theRock.address) == (tieGame.wager * .9)
assert rps.moneys(accounts[0]) == (tieGame.wager * 2) * .1
txHash = rps.withdraw(transact={"from": theRock.address})
txHash = rps.withdraw(transact={"from": theRockTwo.address})
txHash = rps.withdraw(transact={"from": accounts[0]})
assert rps.moneys(theRockTwo.address) == 0
pprint("The rock has tied the rock 2")


# Rock fails to play with himself
# gameFour = Game(object)
# gameFour.wager = 100
# gameFour.gameHash = rps.getGameHash(theRock.address, theRock.address)
# txHash = rps.challenge(theRock.address, theRock.hashedMove, transact={"value": gameFour.wager, "from": theRock.address})
# txHash = rps.acceptChallenge(theRock.address, theRock.hashedMove, transact={"value": gameFour.wager, "from": theRock.address})
# txHash = rps.finalizeMove(theRock.address, theRock.move, theRock.password, transact={"from": theRock.address})
# txHash = rps.finalizeMove(theRock.address, theRock.move, theRock.password, transact={"from": theRock.address})
# assert rps.moneys(accounts[0]) == (gameFour.wager * .1)
# assert rps.moneys(theRock.address) == (gameFour.wager * .9) * 2
# txHash = rps.withdraw(transact={"from": theRock.address})
# assert rps.moneys(theRock.address) == 0
# pprint("The rock has tied himself")
