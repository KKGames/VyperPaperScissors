# Rock Paper Scissors
This is a Vyper implementation of the rock paper scissors game.

# Getting started
Create a virtual environment
`virtualenv -p python3 environmentName`

Initiate virtual environment
`source environmentName/bin/activate`

Clone into repo
`git clone https://github.com/KKGames/VyperPaperScissors`

Move into folder and install package requirements
`pip install -e requirements.txt`

Run tests:
`python test.py`


# Testing

To store ABI changes made to contract:
```
vyper -f abi RPS.vy > rps.json
```

To store Bytecode changes:
```
vyper - bytecode RPS.vy > rps.bin
```

Run tests:
```
python test.py
```
