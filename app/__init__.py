import json
from configparser import ConfigParser

from flask import Flask
from web3 import Web3

config = ConfigParser()
config.read("config.cipa")

chain_url = config.get('chaine', 'url', fallback="http://127.0.0.1")
chain_port = config.get('chaine', 'port', fallback="7545")
abi_path = config.get('contrat', 'chemin_abi', fallback="build/contracts/CipaCoin.json")
contract_address = config.get('contrat', 'adresse', fallback=None)

if contract_address is None:
    raise ValueError("Aucune adresse de contrat n'a été fournie, merci de vérifier le contenu de 'config.cipa'")

w3 = Web3(Web3.HTTPProvider(f"{chain_url}:{chain_port}"))
with open(abi_path) as f:
    abi = json.load(f)["abi"]

contract = w3.eth.contract(address=contract_address, abi=abi)
accounts = w3.eth.accounts

app = Flask(__name__)
app.config['SECRET_KEY'] = 'S I G A N U X'

from app import routes
