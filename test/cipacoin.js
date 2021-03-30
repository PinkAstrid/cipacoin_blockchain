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
    assert.isOk(balance.eqn(20));
  });

  // mac ajouté
  // ambroise ajouté
  it("on peut inscrire des etudiants", async () => {
    let instance = await CipaCoin.deployed();

    assert.isNotOk(await instance.studentExists.call(mac), "l'etudiant existe avant l'execution du test");
    instance.registerStudent(mac);
    assert.isOk(await instance.studentExists.call(mac), "l'etudiant n'existe pas alors qu'il a bien ete cree");

    assert.isNotOk(await instance.studentExists.call(ambroise), "l'etudiant existe avant l'execution du test");
    instance.registerStudent(ambroise);
    assert.isOk(await instance.studentExists.call(ambroise), "l'etudiant n'existe pas alors qu'il a bien ete cree");
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

    assert.isOk(clubExists, "le club n'existe pas alors qu'il a bien ete cree");
  });

  it("on ne peut pas creer deux clubs identiques", async () => {
    let instance = await CipaCoin.deployed();

    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club multiprises"));
    let clubExists = await instance.clubExists.call(clubInt);

    assert.isOk(clubExists);

    await truffleAssert.reverts(instance.createClub(amadis, web3.utils.fromAscii("club multiprises")));
  });

  // club conso (1) créé
  it("la direction des etudes ne peut pas creer de club, un eleve si", async () => {
    let instance = await CipaCoin.deployed();

    await truffleAssert.reverts(instance.createClub(alaska, web3.utils.fromAscii("club conso")));

    instance.createClub(mac, web3.utils.fromAscii("club conso"));
    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club conso"));
    let clubExists = await instance.clubExists.call(clubInt);
    assert.isOk(clubExists);
  });

  it("seul un eleve inscrit peut creer un club", async () => {
    let instance = await CipaCoin.deployed();

    await truffleAssert.reverts(instance.createClub(un_pote, web3.utils.fromAscii("club tourisme")));
  });

  // club conso +15 -> 15
  it("la direction des etudes peut donner des points a un club", async () => {
    let instance = await CipaCoin.deployed();

    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club conso"));
    instance.sendCipaAlbusToClub(clubInt, 15);
    let balance = await instance.getClubBalance(clubInt);

    assert.equal(balance, 15);
  });

  it("un etudiant ne peut pas donner des points a un club", async () => {
    let instance = await CipaCoin.deployed();

    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club conso"));
    await truffleAssert.reverts(instance.sendCipaAlbusToClub(clubInt, 10, { from: ambroise }));
    let balance = await instance.getClubBalance(clubInt);

    assert.equal(balance, 15);
  });

  // club conso -5 -> 10
  // ambroise +5 -> 5
  it("un club peut donner des points a un eleve", async () => {
    let instance = await CipaCoin.deployed();

    let amount = 5

    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club conso"));
    let clubPres = await instance.getClubPres.call(clubInt);

    let ambroiseInitialBalance = await instance.getStudentBalance(ambroise);
    let clubInitialBalance = await instance.getClubBalance(clubInt);

    instance.sendCipaClubToStudent(clubInt, ambroise, amount, { from: clubPres });

    let clubFinalBalance = await instance.getClubBalance(clubInt);
    let ambroiseFinalBalance = await instance.getStudentBalance(ambroise);

    assert.isOk(clubInitialBalance.subn(amount).eq(clubFinalBalance));
    assert.isOk(ambroiseInitialBalance.addn(amount).eq(ambroiseFinalBalance));
  });

  it("un club ne peut donner des points qu'a un eleve inscrit", async () => {
    let instance = await CipaCoin.deployed();

    let amount = 10;

    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club conso"));
    let clubPres = await instance.getClubPres.call(clubInt);

    let clubInitialBalance = await instance.getClubBalance(clubInt);

    await truffleAssert.reverts(instance.sendCipaClubToStudent(clubInt, un_pote, amount, { from: clubPres }));

    let clubFinalBalance = await instance.getClubBalance(clubInt);

    assert.isOk(clubInitialBalance.eq(clubFinalBalance), "le nombre de CIPA du club a change alors que la transaction est censee echouer");
  });

  it("un club ne peut pas donner des points a la direction des etudes", async () => {
    let instance = await CipaCoin.deployed();

    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club conso"));
    let clubPres = await instance.getClubPres.call(clubInt);

    let clubInitialBalance = await instance.getClubBalance(clubInt);

    await truffleAssert.reverts(instance.sendCipaClubToStudent(clubInt, alaska, 10, { from: clubPres }));

    let clubFinalBalance = await instance.getClubBalance(clubInt);

    assert.isOk(clubInitialBalance.eq(clubFinalBalance), "le nombre de CIPA du club a change alors que la transaction est censee echouer");
  });

  it("un club ne peut donner plus de points qu'il n'en possede", async () => {
    let instance = await CipaCoin.deployed();

    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club conso"));
    let clubPres = await instance.getClubPres.call(clubInt);

    let ambroiseInitialBalance = await instance.getStudentBalance(ambroise);
    let clubInitialBalance = await instance.getClubBalance(clubInt);

    await truffleAssert.reverts(instance.sendCipaClubToStudent(clubInt, ambroise, clubInitialBalance.addn(1), { from: clubPres }));

    let clubFinalBalance = await instance.getClubBalance(clubInt);
    let ambroiseFinalBalance = await instance.getStudentBalance(ambroise);

    assert.isOk(clubInitialBalance.eq(clubFinalBalance));
    assert.isOk(ambroiseInitialBalance.eq(ambroiseFinalBalance));
  });

  it("seul le president d'un club peut donner les points de son club", async () => {
    let instance = await CipaCoin.deployed();

    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club conso"));
    let clubPres = await instance.getClubPres.call(clubInt);

    let ambroiseInitialBalance = await instance.getStudentBalance(ambroise);
    let clubInitialBalance = await instance.getClubBalance(clubInt);

    assert.equal(amadis == clubPres, false);
    await truffleAssert.reverts(instance.sendCipaClubToStudent(clubInt, ambroise, 5, { from: amadis }));

    let clubFinalBalance = await instance.getClubBalance(clubInt);
    let ambroiseFinalBalance = await instance.getStudentBalance(ambroise);

    assert.isOk(clubInitialBalance.eq(clubFinalBalance));
    assert.isOk(ambroiseInitialBalance.eq(ambroiseFinalBalance));
  });


  // ambroise -2 -> 3
  // mac +2 -> 2
  it("un eleve peut envoyer des cipa a un autre eleve", async () => {
    let instance = await CipaCoin.deployed();

    let amount = 2;

    let ambroiseInitialBalance = await instance.getStudentBalance(ambroise);
    let macInitialBalance = await instance.getStudentBalance(mac);

    instance.sendCipaStudentToStudent(mac, amount, { from: ambroise });

    let ambroiseFinalBalance = await instance.getStudentBalance(ambroise);
    let macFinalBalance = await instance.getStudentBalance(mac);

    assert.isOk(ambroiseInitialBalance.gten(amount, "l'etudiant n'a pas assez de CIPA pour effectuer le test"));
    assert.isOk(ambroiseInitialBalance.subn(amount).eq(ambroiseFinalBalance));
    assert.isOk(macInitialBalance.addn(amount).eq(macFinalBalance));
  });

  it("un eleve ne peut envoyer plus de cipa qu'il n'en possede", async () => {
    let instance = await CipaCoin.deployed();

    let ambroiseInitialBalance = await instance.getStudentBalance(ambroise);
    let macInitialBalance = await instance.getStudentBalance(mac);

    await truffleAssert.reverts(instance.sendCipaStudentToStudent(ambroise, macInitialBalance.addn(1), { from: mac }));

    let ambroiseFinalBalance = await instance.getStudentBalance(ambroise);
    let macFinalBalance = await instance.getStudentBalance(mac);

    assert.isOk(ambroiseInitialBalance.eq(ambroiseFinalBalance), "le nombre de CIPA de l'etudiant a change alors que la transaction est censee echouer");
    assert.isOk(macInitialBalance.eq(macFinalBalance), "le nombre de CIPA du club a change alors que la transaction est censee echouer");
  });

  it("un eleve ne peut envoyer des cipa qu'a un autre eleve", async () => {
    let instance = await CipaCoin.deployed();

    let amount = 1;

    let ambroiseInitialBalance = await instance.getStudentBalance(ambroise);
    let macInitialBalance = await instance.getStudentBalance(mac);

    await truffleAssert.reverts(instance.sendCipaStudentToStudent(un_pote, amount, { from: mac }));

    let ambroiseFinalBalance = await instance.getStudentBalance(ambroise);
    let macFinalBalance = await instance.getStudentBalance(mac);

    assert.isOk(macInitialBalance.gten(amount), "l'etudiant n'a pas de points CIPA, il doit en avoir pour effectuer ce test");
    assert.isOk(ambroiseInitialBalance.eq(ambroiseFinalBalance), "le nombre de CIPA de l'etudiant a change alors que la transaction est censee echouer");
    assert.isOk(macInitialBalance.eq(macFinalBalance), "le nombre de CIPA de l'etudiant a change alors que la transaction est censee echouer");
  });

  it("un eleve ne peut pas s'envoyer des cipa a lui-meme", async () => {
    let instance = await CipaCoin.deployed();

    let amount = 1;

    let macInitialBalance = await instance.getStudentBalance(mac);
    await truffleAssert.reverts(instance.sendCipaStudentToStudent(mac, amount, { from: mac }));
    let macFinalBalance = await instance.getStudentBalance(mac);

    assert.isOk(macInitialBalance.gten(amount), "l'etudiant n'a pas de points CIPA, il doit en avoir pour effectuer ce test");
    assert.isOk(macInitialBalance.eq(macFinalBalance), "le nombre de CIPA de l'etudiant a change alors que la transaction est censee echouer");
  });

  it("un president ne peut pas voler la caisse", async () => {
    let instance = await CipaCoin.deployed();

    instance.createClub(ambroise, web3.utils.fromAscii("club mots au pif"));

    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club mots au pif"));

    instance.sendCipaAlbusToClub(clubInt, 15);

    await truffleAssert.reverts(instance.sendCipaClubToStudent(clubInt, ambroise, 4, { from: ambroise }));

  });

  it("mais il peut quand meme un peu taper dedans", async () => {
    let instance = await CipaCoin.deployed();

    let clubInt = await instance.getClubIntFromName.call(web3.utils.fromAscii("club mots au pif"));

    await truffleAssert.reverts(instance.sendCipaClubToStudent(clubInt, ambroise, 3, { from: ambroise }));

  });

});