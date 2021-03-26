const CipaCoin = artifacts.require("CipaCoin");
const truffleAssert = require('truffle-assertions');


// le fonctionnement est chelou, les variables sont pas conservées entre les tests
// par contre tout ce qui est dans la blockchain y reste
// faut faire gaffe à pas redéclarer des trucs par erreur du coup

// on va essayer de documenter l'evolution de la blockchain au-dessus des fonctions qui la modifie du coup

// pense a faire un "npm install truffle-assertions", ça permet de tester proprement un echec

contract("El Cipatest", async accounts => {

  let alaska = accounts[0]; // la direction des études
  let mac = accounts[1];
  let ambroise = accounts[2];
  let amadis = accounts[3]; // le type avec les multiprises
  let un_pote = accounts[4]; // un type grave sympa mais qui n'est pas eleve à TN

  it("le threshold par défaut devrait etre 20", async () => {
    let instance = await CipaCoin.deployed();
    let balance = await instance.getCipathreshold.call();
    assert.equal(balance.valueOf(), 20);
  });

  // mac ajouté
  // ambroise ajouté
  it("on peut inscrire des etudiants", async () => {
    let instance = await CipaCoin.deployed();

    instance.registerStudent(mac);
    let macExists = await instance.studentExists.call(mac);
    assert.equal(macExists, true);

    instance.registerStudent(ambroise);
    let ambroiseExists = await instance.studentExists.call(ambroise);
    assert.equal(ambroiseExists, true);
  });

  it("on ne peut pas inscrire la direction des etudes", async () => {
    let instance = await CipaCoin.deployed();

    await truffleAssert.reverts(instance.registerStudent(alaska));
  });

  // amadis ajouté
  // club multiprises (0) créé
  it("on peut creer un club", async () => {
    let instance = await CipaCoin.deployed();

    instance.registerStudent(amadis);
    instance.createClub(amadis, web3.utils.fromAscii("club multiprises"));

    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club multiprises"));
    let clubExists = await instance.clubExists.call(clubInt);

    assert.equal(clubExists, true);
  });

  it("on ne peut pas creer deux clubs identiques", async () => {
    let instance = await CipaCoin.deployed();

    await truffleAssert.reverts(instance.createClub(amadis, web3.utils.fromAscii("club multiprises")));
  });

  // club conso (1) créé
  it("la direction des etudes ne peut pas creer de club, un eleve si", async () => {
    let instance = await CipaCoin.deployed();

    await truffleAssert.reverts(instance.createClub(alaska, web3.utils.fromAscii("club conso")));

    instance.createClub(mac, web3.utils.fromAscii("club conso"));
    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club conso"));
    let clubExists = await instance.clubExists.call(clubInt);
    assert.equal(clubExists, true);
  });

  it("seul un eleve inscrit peut creer un club", async () => {
    let instance = await CipaCoin.deployed();

    await truffleAssert.reverts(instance.createClub(un_pote, web3.utils.fromAscii("club tourisme")));
  });

  // club conso +15 -> 15
  it("la direction des etudes peut donner des points a un club", async () => {
    let instance = await CipaCoin.deployed();

    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club conso"));
    instance.sendCipaDirToClub(clubInt, 15);
    let balance = await instance.getClubBalance(clubInt);

    assert.equal(balance, 15);
  });

  it("un etudiant ne peut pas donner des points a un club", async () => {
    let instance = await CipaCoin.deployed();

    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club conso"));
    await truffleAssert.reverts(instance.sendCipaDirToClub(clubInt, 10, { from: ambroise }));
    let balance = await instance.getClubBalance(clubInt);

    assert.equal(balance, 15);
  });

  // club conso -5 -> 10
  // ambroise +5 -> 5
  it("un club peut donner des points a un eleve", async () => {
    let instance = await CipaCoin.deployed();

    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club conso"));
    let clubPres = await instance.getClubPres.call(clubInt);

    instance.sendCipaClubToStudent(clubInt, ambroise, 5, { from: clubPres });

    let clubBalance = await instance.getClubBalance(clubInt);
    let ambroiseBalance = await instance.getStudentBalance(ambroise);

    assert.equal(clubBalance, 10);
    assert.equal(ambroiseBalance, 5);
  });

  it("un club ne peut donner des points qu'a un eleve inscrit", async () => {
    let instance = await CipaCoin.deployed();

    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club conso"));
    let clubPres = await instance.getClubPres.call(clubInt);

    await truffleAssert.reverts(instance.sendCipaClubToStudent(clubInt, un_pote, 10, { from: clubPres }));

    let clubBalance = await instance.getClubBalance(clubInt);

    assert.equal(clubBalance, 10);
  });

  it("un club ne peut pas donner des points a la direction des etudes", async () => {
    let instance = await CipaCoin.deployed();

    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club conso"));
    let clubPres = await instance.getClubPres.call(clubInt);

    await truffleAssert.reverts(instance.sendCipaClubToStudent(clubInt, alaska, 10, { from: clubPres }));

    let clubBalance = await instance.getClubBalance(clubInt);

    assert.equal(clubBalance, 10);
  });

  it("un club ne peut donner plus de points qu'il n'en possede", async () => {
    let instance = await CipaCoin.deployed();

    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club conso"));
    let clubPres = await instance.getClubPres.call(clubInt);

    await truffleAssert.reverts(instance.sendCipaClubToStudent(clubInt, ambroise, 20, { from: clubPres }));

    let clubBalance = await instance.getClubBalance(clubInt);
    let ambroiseBalance = await instance.getStudentBalance(ambroise);

    assert.equal(clubBalance, 10);
    assert.equal(ambroiseBalance, 5);
  });

  it("seul le president d'un club peut donner les points de son club", async () => {
    let instance = await CipaCoin.deployed();

    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club conso"));
    let clubPres = await instance.getClubPres.call(clubInt);

    assert.equal(amadis == clubPres, false);
    await truffleAssert.reverts(instance.sendCipaClubToStudent(clubInt, ambroise, 5, { from: amadis }));

    let clubBalance = await instance.getClubBalance(clubInt);
    let ambroiseBalance = await instance.getStudentBalance(ambroise);

    assert.equal(clubBalance, 10);
    assert.equal(ambroiseBalance, 5);
  });


  // ambroise -2 -> 3
  // mac +2 -> 2
  it("un eleve peut envoyer des cipa a un autre eleve", async () => {
    let instance = await CipaCoin.deployed();

    instance.sendCipaStudentToStudent(mac, 2, { from: ambroise });

    let ambroiseBalance = await instance.getStudentBalance(ambroise);
    let macBalance = await instance.getStudentBalance(mac);

    assert.equal(ambroiseBalance, 3);
    assert.equal(macBalance, 2);
  });

  it("un eleve ne peut envoyer plus de cipa qu'il n'en possede", async () => {
    let instance = await CipaCoin.deployed();

    await truffleAssert.reverts(instance.sendCipaStudentToStudent(ambroise, 10, { from: mac }));

    let ambroiseBalance = await instance.getStudentBalance(ambroise);
    let macBalance = await instance.getStudentBalance(mac);

    assert.equal(ambroiseBalance, 3);
    assert.equal(macBalance, 2);
  });

  it("un eleve ne peut envoyer des cipa qu'a un autre eleve", async () => {
    let instance = await CipaCoin.deployed();

    await truffleAssert.reverts(instance.sendCipaStudentToStudent(un_pote, 1, { from: mac }));

    let ambroiseBalance = await instance.getStudentBalance(ambroise);
    let macBalance = await instance.getStudentBalance(mac);

    assert.equal(ambroiseBalance, 3);
    assert.equal(macBalance, 2);
  });

});