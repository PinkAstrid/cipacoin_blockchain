// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract CipaCoin {
    struct Club {
        bytes32 name;
        address president;
        uint256 cipaClubBalance;
        uint256 totalCipaOwnedSinceNomination;
        uint256 cipaSentToPresSinceNomination;
    }

    struct Student {
        address student;
        uint256 cipaStudentBalance;
        bool certificat;
        bool exists;
    }

    address public dumbledore;

    uint256 public cipaThreshold;

    uint8 public maxSelfPaymentPercentage;

    mapping(address => Student) public students;

    Club[] public clubs;

    constructor() public {
        dumbledore = msg.sender;
        cipaThreshold = 20;
        maxSelfPaymentPercentage = 20;
    }

    function getDumbledor() public view returns (address) {
        return dumbledore;
    }

    function studentExists(address student) public view returns (bool) {
        return students[student].exists;
    }

    function getStudentBalance(address student) public view returns (uint256) {
        require(studentExists(student), "L'etudiant n'existe pas.");
        return students[student].cipaStudentBalance;
    }

    function studentHasCert(address student) public view returns (bool) {
        require(studentExists(student), "L'etudiant n'existe pas.");
        return students[student].certificat;
    }

    function clubExists(uint256 clubInt) public view returns (bool) {
        return clubInt < clubs.length;
    }

    function getClubCount() public view returns (uint256) {
        return clubs.length;
    }

    function getClubName(uint256 clubInt) public view returns (bytes32) {
        require(clubExists(clubInt), "Le club n'est pas connu.");
        return clubs[clubInt].name;
    }

    function getClubPres(uint256 clubInt) public view returns (address) {
        require(clubExists(clubInt), "Le club n'est pas connu.");
        return clubs[clubInt].president;
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

    function getMaxSelfPaymentPercentage() public view returns (uint8) {
        return maxSelfPaymentPercentage;
    }

    function setCipaThreshold(uint256 threshold) public {
        require(
            msg.sender == dumbledore,
            "Seule la direction des etudes peut modifier le seuil de validation"
        );

        cipaThreshold = threshold;
    }

    function setMaxSelfPaymentPercentage(uint8 percentage) public {
        require(
            msg.sender == dumbledore,
            "Seule la direction des etudes peut modifier ce ratio"
        );

        require(
            percentage <= 100,
            "Le pourcentage doit etre inferieur ou egal a 100"
        );

        maxSelfPaymentPercentage = percentage;
    }

    function registerStudent(address student) public {
        require(
            msg.sender == dumbledore,
            "Seule la direction des etudes peut inscrire un etudiant"
        );

        require(
            student != dumbledore,
            "La direction des etudes ne peut pas etre un etudiant"
        );

        require(!studentExists(student), "L'etudiant est deja inscrit");

        students[student] = Student({
            student: student,
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
            students[msg.sender].cipaStudentBalance >= amount,
            "L'etudiant envoyeur n'a pas assez de CIPA."
        );

        require(
            !studentHasCert(student),
            "L'etudiant receveur a deja son certificat."
        );

        students[student].cipaStudentBalance += amount;
        students[msg.sender].cipaStudentBalance -= amount;
    }

    function sendCipaAlbusToClub(uint256 clubInt, uint256 amount) public {
        require(amount > 0, "Le montant de la transaction est nul.");
        require(
            msg.sender == dumbledore,
            "Seule la direction des etudes peut creer des CIPA."
        );

        require(clubExists(clubInt), "Le club n'est pas connu.");

        clubs[clubInt].totalCipaOwnedSinceNomination += amount;
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
            "L'etudiant receveur a deja son certificat."
        );

        // le total des points que le president se serait verse si la transaction etait approuvee
        uint256 totalAmount =
            clubs[clubInt].cipaSentToPresSinceNomination + amount;

        // le total est il conforme au maximal autorise
        bool isUnderAllowedValue =
            (totalAmount * 100) /
                clubs[clubInt].totalCipaOwnedSinceNomination <=
                maxSelfPaymentPercentage;

        // permet au president de se verser un point meme s'il represente plus que le pourcentage autorise
        // utile si le club a peu de points a distribuer
        bool isClubPoor =
            clubs[clubInt].cipaSentToPresSinceNomination == 0 && amount == 1;

        require(
            !(getClubPres(clubInt) == student) ||
                isUnderAllowedValue ||
                isClubPoor,
            "Le president ne peut se donner plus de 20% des CIPA recus depuis sa nomination."
        );

        students[student].cipaStudentBalance += amount;
        clubs[clubInt].cipaClubBalance -= amount;

        if (getClubPres(clubInt) == student)
            clubs[clubInt].cipaSentToPresSinceNomination += amount;
    }

    function createClub(address president, bytes32 name) public {
        require(
            msg.sender == dumbledore,
            "Seule la direction des etudes peut creer des clubs"
        );

        require(
            president != dumbledore,
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

        require(
            getTimesPres(president) < 5,
            "L'etudiant est deja president de 5 clubs, il ne peut plus devenir president d'un nouveau club."
        );

        clubs.push(
            Club({
                name: name,
                president: president,
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
            students[msg.sender].cipaStudentBalance >= cipaThreshold,
            "L'etudiant n'a pas assez de point CIPA."
        );

        students[msg.sender].certificat = true;
        students[msg.sender].cipaStudentBalance = 0;
    }

    function getTimesPres(address student) public view returns (uint256) {
        uint256 output = 0;
        for (uint256 i = 0; i < clubs.length; i++)
            if (getClubPres(i) == student) output++;
        return output;
    }

    function nominatePres(address newPres, uint256 clubInt) public {
        require(
            msg.sender == dumbledore,
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

        require(
            getTimesPres(newPres) < 5,
            "L'etudiant est deja president de 5 clubs, il ne peut plus devenir president d'un nouveau club."
        );

        clubs[clubInt].president = newPres;
        clubs[clubInt].totalCipaOwnedSinceNomination = clubs[clubInt].cipaClubBalance;
        clubs[clubInt].cipaSentToPresSinceNomination = 0;
    }
}
