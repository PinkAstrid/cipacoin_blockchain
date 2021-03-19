const CipaCoin = artifacts.require("CipaCoin");

const truffleAssert = require('truffle-assertions');


// le fonctionnement est chelou, les variables sont pas conservées entre les tests
// par contre tout ce qui est dans la blockchain y reste
// faut faire gaffe à pas redéclarer des trucs par erreur du coup

// pense a faire un "npm install truffle-assertions", ça permet de tester proprement un echec

contract("El Cipatest", async accounts => {

    let alaska = accounts[0];
    let mac = accounts[1];
    let ambroise = accounts[2];
    let amadis = accounts[3];
    let un_pote = accounts[4]; // un type grave sympa mais qui n'est pas eleve à TN

  it("le threshold par défaut devrait etre 20", async () => {
    let instance = await CipaCoin.deployed();
    let balance = await instance.getCipathreshold.call();
    assert.equal(balance.valueOf(), 20);
  });

  it("on peut inscrire des etudiants", async()=>{
    let instance = await CipaCoin.deployed();

    instance.registerStudent(mac);
    let macExists = await instance.studentExists.call(mac);
    assert.equal(macExists, true);

    instance.registerStudent(ambroise);
    let ambroiseExists = await instance.studentExists.call(ambroise);
    assert.equal(ambroiseExists, true);
  });

  it("on ne peut pas inscrire la direction des etudes", async()=>{
    let instance = await CipaCoin.deployed();

    await truffleAssert.reverts(instance.registerStudent(alaska));
  });

  it("on peut creer un club", async()=>{
    let instance = await CipaCoin.deployed();

    instance.registerStudent(amadis);
    instance.createClub(amadis, web3.utils.fromAscii("club multiprises"));

    let clubInt = await instance.getClubIntFromName.call( web3.utils.fromAscii("club multiprises"));
    let clubExists = await instance.clubExists.call(clubInt);

    assert.equal(clubExists, true);
  });

  it("on ne peut pas creer deux clubs identiques", async()=>{
    let instance = await CipaCoin.deployed();

    await truffleAssert.reverts(instance.createClub(amadis, web3.utils.fromAscii("club multiprises")));
  });

  it("la direction des etudes ne peut pas creer de club, un eleve si", async()=>{
    let instance = await CipaCoin.deployed();

    await truffleAssert.reverts(instance.createClub(alaska, web3.utils.fromAscii("club conso")));
    
    instance.createClub(mac, web3.utils.fromAscii("club conso"));
    let clubInt = await instance.getClubIntFromName.call( web3.utils.fromAscii("club conso"));
    let clubExists = await instance.clubExists.call(clubInt);
    assert.equal(clubExists, true);
  });

  it("seul un eleve inscrit peut creer un club", async()=>{
    let instance = await CipaCoin.deployed();

    await truffleAssert.reverts(instance.createClub(un_pote, web3.utils.fromAscii("club tourisme")));
  });

});