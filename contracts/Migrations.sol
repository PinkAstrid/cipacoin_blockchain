// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract CipaCoins{
  
  struct Club{
    bytes32 name;
    address pres;
    uint cipaClubBalance;
  }

  struct Eleve{
    address eleve;
    uint cipaStudentBalance;
    bool certificat;
  }

  address public directionDesEtudes;

  uint cipaThreashHold;

  mapping(address => Eleve) public eleves;

  Club[] public clubs;

  constructor(){
		directionDesEtudes = msg.sender;
	}

  function sendCipaStudentToStudent(address student, uint amount) public {
    require(
      eleves[msg.sender].cipaStudentBalance>amount,
      "L'eleve envoyeur n'a pas assez de CIPA."
    );

    require(
      !eleves[student].certificat,
      "L'eleve receveur a deja assez de CIPA."
    );
    
    eleves[student].cipaStudentBalance+=amount;
    eleves[msg.sender].cipaStudentBalance-=amount;
  }

  function sendCipaDirToClub(uint amount, uint clubInt) public {
    require(
      msg.sender== directionDesEtudes,
      "Seule la direction des etudes peut creer des CIPA."
    );

    require(
      clubInt>=clubs.length,
      "Le club n'est pas connu."
    ); 
    
    clubs[clubInt].cipaClubBalance+=amount;
  }

  function sendCipaClubToStudent(address student, uint amount, uint clubInt) public {
    require(
      clubInt>=clubs.length,
      "Le club n'est pas connu."
    );

    require(
      msg.sender==clubs[clubInt].pres,
      "L'envoyeur n'est pas president du club."
    );
    
    require(
      clubs[clubInt].cipaClubBalance>amount,
      "Le club envoyeur n'a pas assez de CIPA."
    );

    require(
      !eleves[student].certificat,
      "L'eleve receveur a deja assez de CIPA."
    );
    
    eleves[student].cipaStudentBalance+=amount;
    clubs[clubInt].cipaClubBalance-=amount;
  }

  function createClub(address president, bytes32 name) public {
    require(
      msg.sender== directionDesEtudes,
      "Seule la direction des etudes peut creer des clubs"
    );

    bool alreadyExists = false;
    for(uint i = 0; i < clubs.length; i++ ){
      alreadyExists = (clubs[i].name != name);
    }

    require(
      !alreadyExists,
      "Le club existe deja."
    );

    Club storage nveauClub;
    nveauClub.name = name;
    nveauClub.pres = president;
    nveauClub.cipaClubBalance = 0;

    clubs.push(nveauClub);
  }

  function validateCipa() public{
    require(
      !eleves[msg.sender].certificat,
      "L'etudiant a deja valide son certificat CIPA"
    );

    require(
      eleves[msg.sender].cipaStudentBalance >= cipaThreashHold,
      "L'etudiant n'a pas assez de point CIPA."
    );

    eleves[msg.sender].certificat = true;
    eleves[msg.sender].cipaStudentBalance = 0;
  }

  function makePres(address newPres, uint clubInt) public{
    require(
      msg.sender== directionDesEtudes,
      "Seule la direction des etudes peut nommer un president."
    );

    require(
      clubInt<clubs.length,
       "Le club n'est pas connu."
    ); 
    
    clubs[clubInt].pres = newPres;
  }
}