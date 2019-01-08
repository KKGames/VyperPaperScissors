# @title rock paper scissors
# @notice

# game struct
struct Game:
    wager: wei_value
    state: uint256
    deadline: uint256    #amount of time given for player to make a move
    hashedMove: map(address, bytes32)
    openMove: map(address, uint256)


# wei owed
moneys: public(map(address, wei_value))

# win/loss/tie evaluations
evaluation: public(map(bytes32, uint256))

games : public(map(bytes32, Game))
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

#------------------------Game Struct Data---------------------------
@public
@constant
def getGameState(gameHash: bytes32) -> uint256:
    return self.games[gameHash].state

@public
@constant
def getGameWager(gameHash: bytes32) -> wei_value:
    return self.games[gameHash].wager

@public
@constant
def getGameHashedMove(gameHash: bytes32, player: address) -> bytes32:
    return self.games[gameHash].hashedMove[player]

@public
@constant
def getGameOpenMove(gameHash: bytes32, player: address) -> uint256:
    return self.games[gameHash].openMove[player]
# --------------------------------------------------------------------------------



# Rock = 0, Paper = 1, Scissors = 2
# Evaluation: 1 = win, 2 = draw, 3 = loss  (from perspective of player 1)
@public
def __init__():
    self.owner = msg.sender
    # pre-set evaluation results
    self.evaluation[sha3(concat(convert(0, bytes32), convert(2, bytes32)))] = 1  # rock vs scissors
    self.evaluation[sha3(concat(convert(1, bytes32), convert(0, bytes32)))] = 1  # paper vs rock
    self.evaluation[sha3(concat(convert(2, bytes32), convert(1, bytes32)))] = 1  # scissors vs paper
    self.evaluation[sha3(concat(convert(0, bytes32), convert(0, bytes32)))] = 2  # rock vs rock
    self.evaluation[sha3(concat(convert(1, bytes32), convert(1, bytes32)))] = 2  # paper vs paper
    self.evaluation[sha3(concat(convert(2, bytes32), convert(2, bytes32)))] = 2  # scissors vs scissors
    self.evaluation[sha3(concat(convert(0, bytes32), convert(1, bytes32)))] = 3  # rock vs paper
    self.evaluation[sha3(concat(convert(1, bytes32), convert(2, bytes32)))] = 3  # paper vs scissors
    self.evaluation[sha3(concat(convert(2, bytes32), convert(0, bytes32)))] = 3  # scissors vs rock



@private
def evaluateMoves(gameHash: bytes32, p1: address, p2: address) -> bool:
    result: uint256 = self.evaluation[self.hashUints(self.games[gameHash].openMove[p1], self.games[gameHash].openMove[p2])]
    assert result == 1 or result == 2 or result == 3
    if (result == 1):
        self.moneys[p1] += self.games[gameHash].wager * 2
        return True
    if (result == 3):
        self.moneys[p2] += self.games[gameHash].wager * 2
        return True
    if (result == 2):
        ownerAmount: wei_value = (self.games[gameHash].wager * 10) / 100
        playerAmount: wei_value = self.games[gameHash].wager - ownerAmount
        self.moneys[self.owner] += (ownerAmount * 2)
        self.moneys[p1] += playerAmount
        self.moneys[p2] += playerAmount
        assert (playerAmount + ownerAmount) == self.games[gameHash].wager
        return True
    return False

# @notice start match by challenging a bastard
@public
@payable
def challenge(bastard: address, hiddenMove: bytes32):
    assert bastard != msg.sender
    assert msg.value > 10
    gameHash: bytes32 = self.getGameHash(msg.sender, bastard)
    assert self.games[gameHash].state == 0
    self.games[gameHash].wager = msg.value
    self.games[gameHash].state = 1
    self.games[gameHash].hashedMove[msg.sender] = hiddenMove


@public
@payable
def acceptChallenge(challenger: address, hashedMove: bytes32):
    gameHash: bytes32 = self.getGameHash(msg.sender, challenger)
    assert self.games[gameHash].state == 1
    assert msg.value == self.games[gameHash].wager
    self.games[gameHash].deadline = now + 3600   # one hour for bastard to make a move
    self.games[gameHash].state += 1
    self.games[gameHash].hashedMove[msg.sender] = hashedMove

# @notice either player can reveal move here once challenge is accepted
# TODO: delete game variables
@public
def finalizeMove(bastard: address, move: uint256, movePassword: bytes32) -> bool:
    assert move == 0 or move == 1 or move == 2
    gameHash: bytes32 = self.getGameHash(msg.sender, bastard)
    assert self.games[gameHash].state == 2 or self.games[gameHash].state == 3
    assert self.games[gameHash].deadline > now
    assert self.games[gameHash].hashedMove[msg.sender] == self.getHashedMove(move, movePassword)
    self.games[gameHash].hashedMove[msg.sender] = convert(0, bytes32)   #TODO: find delete syntax
    self.games[gameHash].openMove[msg.sender] = move
    if (self.games[gameHash].state == 3):
        assert self.evaluateMoves(gameHash, msg.sender, bastard)
        self.games[gameHash].state = 0
    else:
        self.games[gameHash].state += 1
        self.games[gameHash].deadline = now + 3600
    return True

@public
def withdraw():
    owed: wei_value = self.moneys[msg.sender]
    assert owed > 0
    self.moneys[msg.sender] = 0
    assert self.moneys[msg.sender] == 0
    send(msg.sender, owed)

# @public
# def cancelGame(bastard: address):
#     gameHash: bytes32 = self.getGameHash(msg.sender, bastard)
#     state: uint256 = self.games[gameHash].state
#     deadlinePassed: bool = self.games[gameHash].deadline < now
#     assert state > 0 and deadlinePassed
#     if state == 1:
#         if self.games[gameHash].hashedMove[msg.sender] != convert(0, bytes32):
#             self.moneys[msg.sender] += self.games[gameHash].wager
#     if state == 2:   # challenge accepted but neither have revealed move
#         self.moneys[bastard] += self.games[gameHash].wager
#         self.moneys[msg.sender] += self.games[gameHash].wager
