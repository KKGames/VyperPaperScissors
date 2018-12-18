# @title rock paper scissors
# @notice

# game struct
games: public({
    wager: wei_value,
    state: uint256,
    hashedMove: bytes32[address],
    openMove: uint256[address]
}[bytes32])

# wei owed
moneys: public(wei_value[address])

# win/loss/tie evaluations
evaluation: public(uint256[bytes32])


owner: public(address)

# --------------------------------Public getters-------------------------------
@public
@constant
def getHashedMove(move: uint256, movePassword: bytes32) -> bytes32:
    return sha3(concat(convert(move, bytes32), movePassword))


@public
@constant
def hashUints(a: uint256, b: uint256) -> bytes32:
    return sha3(concat(convert(a, bytes32), convert(b, bytes32)))

@public
@constant
def getGameHash(a: address, b: address) -> bytes32:
    if convert(a, uint256) < convert(b, uint256):
        return sha3(concat(convert(a, bytes32), convert(b, bytes32)))
    else:
        return sha3(concat(convert(b, bytes32), convert(a, bytes32)))


@public
@constant
def getGameState(gameHash: bytes32) -> uint256:
    return self.games[gameHash].state
# --------------------------------------------------------------------------------



# Rock = 0, Paper = 1, Scissors = 2
# Evaluation: 1 = win, 2 = draw, 3 = loss  (from perspective of player 1)
@public
def __init__():
    self.owner = msg.sender
    # pre-set evaluation results
    self.evaluation[sha3(concat(convert(1, bytes32), convert(0, bytes32)))] = 1
    self.evaluation[sha3(concat(convert(1, bytes32), convert(2, bytes32)))] = 3
    self.evaluation[sha3(concat(convert(1, bytes32), convert(1, bytes32)))] = 2
    self.evaluation[sha3(concat(convert(0, bytes32), convert(0, bytes32)))] = 2
    self.evaluation[sha3(concat(convert(0, bytes32), convert(2, bytes32)))] = 1
    self.evaluation[sha3(concat(convert(0, bytes32), convert(1, bytes32)))] = 3
    self.evaluation[sha3(concat(convert(2, bytes32), convert(0, bytes32)))] = 3
    self.evaluation[sha3(concat(convert(2, bytes32), convert(2, bytes32)))] = 2
    self.evaluation[sha3(concat(convert(2, bytes32), convert(1, bytes32)))] = 1



@private
def evaluateMoves(gameHash: bytes32, p1: address, p2: address) -> bool:
    result: uint256 = self.evaluation[self.hashUints(self.games[gameHash].openMove[p1], self.games[gameHash].openMove[p2])]
    if (result == 1):
        self.moneys[p1] += self.games[gameHash].wager * 2
        return True
    if (result == 3):
        self.moneys[p2] += self.games[gameHash].wager * 2
        return True
    if (result == 2):
        ownerAmount: wei_value = (self.games[gameHash].wager * 10) / 100
        playerAmount: wei_value = self.games[gameHash].wager - ownerAmount
        self.moneys[self.owner] += ownerAmount * 2
        self.moneys[p1] += playerAmount
        self.moneys[p2] += playerAmount
        return True
    return False

# @notice start match by challenging a bastard
@public
@payable
def challenge(bastard: address, hiddenMove: bytes32):
    gameHash: bytes32 = self.getGameHash(msg.sender, bastard)
    assert self.games[gameHash].state == 0
    # self.games[gameHash] = {wager: msg.value, state: 1, hashedMove[msg.sender]: hiddenMove, openMove[msg.sender]: 0}
    self.games[gameHash].wager = msg.value
    self.games[gameHash].state = 1
    self.games[gameHash].hashedMove[msg.sender] = hiddenMove


@public
@payable
def acceptChallenge(challenger: address, hashedMove: bytes32):
    gameHash: bytes32 = self.getGameHash(msg.sender, challenger)
    assert self.games[gameHash].state == 1
    assert msg.value == self.games[gameHash].wager
    self.games[gameHash].state += 1
    self.games[gameHash].hashedMove[msg.sender] = hashedMove

# #TODO: Check that move is valid
@public
def finalizeMove(bastard: address, move: uint256, movePassword: bytes32) -> bool:
    assert move == 0 or move == 1 or move == 2
    gameHash: bytes32 = self.getGameHash(msg.sender, bastard)
    assert self.games[gameHash].state == 2 or self.games[gameHash].state == 3
    self.games[gameHash].state += 1
    assert self.games[gameHash].hashedMove[msg.sender] == self.getHashedMove(move, movePassword)
    self.games[gameHash].hashedMove[msg.sender] = convert(0, bytes32)   #TODO: find delete syntax
    self.games[gameHash].openMove[msg.sender] = move
    if (self.games[gameHash].state == 4):
        assert self.evaluateMoves(gameHash, msg.sender, bastard)
    return True
