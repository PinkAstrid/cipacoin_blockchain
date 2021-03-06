# CipaCoin - Projet Blockchain

Par Marie-Astrid Chanteloup et Ambroise Sander

## Tests

Exécuter la commande `truffle test` (ou `npx truffle test` si truffle est installé localement)

## Partie web

Cette partie a été réalisée à l'aide de Flask.

### Installation

Instructions données pour Ubuntu, devrait fonctionner sur tout Linux basé sur Debian, nécessite quelques ajustements pour d'éventuelles autres plateformes.

```bash
sudo apt install -y git python3-venv python3-dev python3-wheel npm
git clone https://gitlab.telecomnancy.univ-lorraine.fr/Marie-Astrid.Chanteloup/blockchain_2a.git
cd blockchain_2a/
npm install truffle truffle-assertions ganache-cli solc
python3 -m venv venv
source venv/bin/activate
python3 -m pip install -r requirements.txt
```

### Exécution

Depuis la racine du repository :

```bash
npx ganache-cli -p 7545 --networkId 5777
```

Laisser ce terminal ouvert et en ouvrir un autre (ou utiliser un outil tel que `screen`), puis exécuter les commandes suivantes dans le second terminal :

```bash
npx truffle migrate
# copier l'adresse du contrat 'CipaCoin' et remplacer celle présente dans le fichier `config.cipa`
python3 -m flask run
```
