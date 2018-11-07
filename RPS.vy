games: public({
  wager: wei_value,
  state: uint256,
  playerMove: bytes32[address]
}[bytes32])

moneys: public(uint256[address])
evaluation: public(uint256[bytes32])


owner: public(address)

@public
def __init__():
  self.owner = msg.sender
  self.evaluation[sha3("Paper", "Rock")] = 1
  self.evaluation[sha3("Paper", "Scissors")] = 3
  self.evaluation[sha3("Paper", "Paper")] = 2
  self.evaluation[sha3("Rock", "Rock")] = 2
  self.evaluation[sha3("Rock", "Scissors")] = 1
  self.evaluation[sha3("Rock", "Paper")] = 3
  self.evaluation[sha3("Scissors", "Rock")] = 3
  self.evaluation[sha3("Scissors", "Scissors")] = 2
  self.evaluation[sha3("Scissors", "Paper")] = 1

@public
@payable
def challenge(bastard: address, secretMove: bytes32):
  gameHash: bytes32 = getPairHash(msg.sender, bastard)
  assert self.games[gameHash].state == 0
  self.games[gameHash] = {wager: msg.value, state: 1}
  self.games[gameHash].playerMove[msg.sender] = secretMove


@public
@payable
def acceptChallenge(challenger: address, secretMove: bytes32):
  gameHash: bytes32 = getPairHash(msg.sender, challenger)
  assert self.games[gameHash].state == 1
  assert msg.value == self.games[gameHash].wager
  self.games[gameHash].state += 1
  self.games[gameHash].playerMove[msg.sender] = secretMove

#TODO: Check that move is valid
@public
def finalizeMove(bastard: address, move: string, movePassword: string) -> bool:
  gameHash: bytes32 = getPairHash(msg.sender, bastard)
  assert self.games[gameHash].state == 2 or self.games[gameHash].state == 3
  self.games[gameHash].state += 1
  assert self.games[gameHash].playerMove[msg.sender] == sha3(move, movePassword)
  self.games[gameHash].playerMove[msg.sender] = sha3(move)
  if (self.games[gameHash].state == 4):
      assert evaluateMoves(gameHash, msg.sender, bastard)
  return True

@private
def evaluateMoves(gameHash: bytes32, p1: address, p2: address) -> bool:
  result: uint256 = self.evaluation[sha3(self.games[gameHash].playerMove[p1], self.games[gameHash].playerMove[p2])]
  if (result == 1):
    moneys[p1] += games[gameHash].wager * 2
    return True
  if (result == 3):
    moneys[p2] += games[gameHash].wager * 2
    return True
  if (result == 2):
    ownerAmount: uint256 = (games[gameHash].wager * 10) / 100
    playerAmount: uint256 = games[gameHash].wager - ownerAmount
    moneys[owner] += ownerAmount * 2
    moneys[p1] += playerAmount
    moneys[p2] += playerAmount
    return True
  return False

@public
@constant
def getHashedMove(move: string, movePassword: string) -> bytes32:
  return sha3(_move, _movePassword)



@public
def getPairHash(a: address, b: address) -> bytes32:
  if (a < b):
    return sha3(a, b)
  else:
    return sha3(b, a)
