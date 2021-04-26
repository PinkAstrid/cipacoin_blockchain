import json

from flask import Flask
from web3 import Web3
from web3.contract import ConciseContract

w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:7545"))
with open("build/contracts/CipaCoin.json") as f:
    abi = json.load(f)["abi"]

address = "0x468973774Ce61Af965Ff10919b0133cBd1Fc1539"
contract = w3.eth.contract(address=address, abi=abi)
accounts = w3.eth.accounts

app = Flask(__name__)
app.config['SECRET_KEY'] = 'S I G A N U X'

from app import routes
