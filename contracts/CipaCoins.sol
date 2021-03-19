// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract CipaCoins {
    struct Club {
        bytes32 name;
        address pres;
        uint256 cipaClubBalance;
    }

    struct Eleve {
        address eleve;
        uint256 cipaStudentBalance;
        bool certificat;
        bool exists;
    }

    address public directionDesEtudes;

    uint256 public cipaThreshold;

    mapping(address => Eleve) public eleves;

    Club[] public clubs;

    constructor() public {
        directionDesEtudes = msg.sender;
        cipaThreshold = 20;
    }

    function setCipaThreshold(uint256 threshold) public {
        require(
            msg.sender == directionDesEtudes,
            "Seule la direction des etudes peut modifier le seuil de validation"
        );

        cipaThreshold = threshold;
    }

    function registerStudent(address student) public {
        require(
            msg.sender == directionDesEtudes,
            "Seule la direction des etudes peut inscrire un etudiant"
        );

        require(
            student != directionDesEtudes,
            "La direction des etudes ne peut pas etre un etudiant"
        );

        require(!eleves[student].exists, "L'eleve est deja inscrit");

        eleves[student] = Eleve({
            eleve: student,
            cipaStudentBalance: 0,
            certificat: false,
            exists: true
        });
    }

    function sendCipaStudentToStudent(address student, uint256 amount) public {
        require(amount > 0, "Le montant de la transaction est nul.");

        require(
            eleves[msg.sender].exists,
            "L'etudiant doit etre inscrit pour pouvoir envoyer des CIPA."
        );
        require(
            eleves[student].exists,
            "L'etudiant doit etre inscrit pour pouvoir recevoir des CIPA."
        );

        require(
            eleves[msg.sender].cipaStudentBalance >= amount,
            "L'eleve envoyeur n'a pas assez de CIPA."
        );

        require(
            !eleves[student].certificat,
            "L'eleve receveur a deja assez de CIPA."
        );

        eleves[student].cipaStudentBalance += amount;
        eleves[msg.sender].cipaStudentBalance -= amount;
    }

    function sendCipaDirToClub(uint256 clubInt, uint256 amount) public {
        require(amount > 0, "Le montant de la transaction est nul.");
        require(
            msg.sender == directionDesEtudes,
            "Seule la direction des etudes peut creer des CIPA."
        );

        require(clubInt < clubs.length, "Le club n'est pas connu.");

        clubs[clubInt].cipaClubBalance += amount;
    }

    function sendCipaClubToStudent(
        uint256 clubInt,
        address student,
        uint256 amount
    ) public {
        require(amount > 0, "Le montant de la transaction est nul.");

        require(clubInt < clubs.length, "Le club n'est pas connu.");

        require(
            eleves[student].exists,
            "L'etudiant doit etre inscrit pour pouvoir recevoir des CIPA."
        );

        require(
            msg.sender == clubs[clubInt].pres,
            "L'envoyeur n'est pas president du club."
        );

        require(
            clubs[clubInt].cipaClubBalance >= amount,
            "Le club envoyeur n'a pas assez de CIPA."
        );

        require(
            !eleves[student].certificat,
            "L'eleve receveur a deja assez de CIPA."
        );

        eleves[student].cipaStudentBalance += amount;
        clubs[clubInt].cipaClubBalance -= amount;
    }

    function createClub(address president, bytes32 name) public {
        require(
            msg.sender == directionDesEtudes,
            "Seule la direction des etudes peut creer des clubs"
        );

        require(
            president != directionDesEtudes,
            "La direction des etudes ne peut pas etre a la tete d'un club"
        );

        require(
            eleves[president].exists,
            "Le president doit etre un etudiant inscrit."
        );

        bool alreadyExists = false;
        for (uint256 i = 0; i < clubs.length; i++) {
            alreadyExists = alreadyExists || (clubs[i].name == name);
        }

        require(!alreadyExists, "Le club existe deja.");

        clubs.push(Club({name: name, pres: president, cipaClubBalance: 0}));
    }

    function validateCipa() public {
        require(
            eleves[msg.sender].exists,
            "L'etudiant doit etre inscrit pour pouvoir valider son certificat CIPA"
        );

        require(
            !eleves[msg.sender].certificat,
            "L'etudiant a deja valide son certificat CIPA"
        );

        require(
            eleves[msg.sender].cipaStudentBalance >= cipaThreshold,
            "L'etudiant n'a pas assez de point CIPA."
        );

        eleves[msg.sender].certificat = true;
        eleves[msg.sender].cipaStudentBalance = 0;
    }

    function makePres(address newPres, uint256 clubInt) public {
        require(
            msg.sender == directionDesEtudes,
            "Seule la direction des etudes peut nommer un president."
        );

        require(
            eleves[newPres].exists,
            "Le president doit etre un etudiant inscrit."
        );

        require(clubInt < clubs.length, "Le club n'est pas connu.");

        require(
            clubs[clubInt].pres != newPres,
            "L'etudiant est deja president de ce club."
        );

        clubs[clubInt].pres = newPres;
    }
}
