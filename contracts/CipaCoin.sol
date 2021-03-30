// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract CipaCoin {
    struct Club {
        bytes32 name;
        address pres;
        uint256 cipaClubBalance;
        uint256 totalCipaOwnedSinceNomination;
        uint256 cipaSentToPresSinceNomination;
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

    function getDirectionDesEtudes() public view returns (address) {
        return directionDesEtudes;
    }

    function studentExists(address student) public view returns (bool) {
        return eleves[student].exists;
    }

    function getStudentBalance(address student) public view returns (uint256) {
        require(studentExists(student), "L'etudiant n'existe pas.");
        return eleves[student].cipaStudentBalance;
    }

    function studentHasCert(address student) public view returns (bool) {
        require(studentExists(student), "L'etudiant n'existe pas.");
        return eleves[student].certificat;
    }

    function clubExists(uint256 clubInt) public view returns (bool) {
        return clubInt < clubs.length;
    }

    function getClubName(uint256 clubInt) public view returns (bytes32) {
        require(clubExists(clubInt), "Le club n'est pas connu.");
        return clubs[clubInt].name;
    }

    function getClubPres(uint256 clubInt) public view returns (address) {
        require(clubExists(clubInt), "Le club n'est pas connu.");
        return clubs[clubInt].pres;
    }

    function getClubBalance(uint256 clubInt) public view returns (uint256) {
        require(clubExists(clubInt), "Le club n'est pas connu.");
        return clubs[clubInt].cipaClubBalance;
    }

    function getClubIntFromName(bytes32 name) public view returns (uint256) {
        for (uint256 i = 0; i < clubs.length; i++) {
            if (clubs[i].name == name) return i;
        }
        revert("Aucun club avec ce nom");
    }

    function getCipathreshold() public view returns (uint256) {
        return cipaThreshold;
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

        require(!studentExists(student), "L'eleve est deja inscrit");

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
            msg.sender != student,
            "Un etudiant ne peut s'envoyer des CIPA a lui-meme."
        );

        require(
            studentExists(msg.sender),
            "L'etudiant doit etre inscrit pour pouvoir envoyer des CIPA."
        );

        require(
            studentExists(student),
            "L'etudiant doit etre inscrit pour pouvoir recevoir des CIPA."
        );

        require(
            eleves[msg.sender].cipaStudentBalance >= amount,
            "L'eleve envoyeur n'a pas assez de CIPA."
        );

        require(
            !studentHasCert(student),
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

        require(clubExists(clubInt), "Le club n'est pas connu.");

        clubs[clubInt].cipaClubBalance += amount;
    }

    function sendCipaClubToStudent(
        uint256 clubInt,
        address student,
        uint256 amount
    ) public {
        require(amount > 0, "Le montant de la transaction est nul.");

        require(clubExists(clubInt), "Le club n'est pas connu.");

        require(
            studentExists(student),
            "L'etudiant doit etre inscrit pour pouvoir recevoir des CIPA."
        );

        require(
            msg.sender == getClubPres(clubInt),
            "L'envoyeur n'est pas president du club."
        );

        require(
            clubs[clubInt].cipaClubBalance >= amount,
            "Le club envoyeur n'a pas assez de CIPA."
        );

        require(
            !studentHasCert(student),
            "L'eleve receveur a deja assez de CIPA."
        );

        require(
            !(getClubPres(clubInt) == student) ||
                (((clubs[clubInt].cipaSentToPresSinceNomination + amount) *
                    100) /
                    clubs[clubInt].totalCipaOwnedSinceNomination <
                    20) ||
                (clubs[clubInt].cipaSentToPresSinceNomination == 0 &&
                    amount == 1),
            "Le president ne peut se donner plus de 20% des CIPA recus depuis sa nomination."
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
            studentExists(president),
            "Le president doit etre un etudiant inscrit."
        );

        bool alreadyExists = false;
        for (uint256 i = 0; i < clubs.length; i++) {
            alreadyExists = clubs[i].name == name;
            if (alreadyExists) break;
        }

        require(!alreadyExists, "Le club existe deja.");

        clubs.push(
            Club({
                name: name,
                pres: president,
                cipaClubBalance: 0,
                totalCipaOwnedSinceNomination: 0,
                cipaSentToPresSinceNomination: 0
            })
        );
    }

    function validateCipa() public {
        require(
            studentExists(msg.sender),
            "L'etudiant doit etre inscrit pour pouvoir valider son certificat CIPA"
        );

        require(
            !studentHasCert(msg.sender),
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
            studentExists(newPres),
            "Le president doit etre un etudiant inscrit."
        );

        require(clubExists(clubInt), "Le club n'est pas connu.");

        require(
            getClubPres(clubInt) != newPres,
            "L'etudiant est deja president de ce club."
        );

        clubs[clubInt].pres = newPres;
        clubs[clubInt].totalCipaOwnedSinceNomination = 0;
        clubs[clubInt].cipaSentToPresSinceNomination = 0;
    }
}
