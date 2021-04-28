def string_to_bytes32(data):
    if len(data) > 32:
        b32 = data[:32]
    else:
        b32 = data.ljust(32, '0')
    return bytes(b32, 'utf-8')


def generate_club_line(contract, accounts, club_int):
    name = contract.caller().getClubName(club_int).decode('utf-8').strip("0")
    president = f"Compte {accounts.index(contract.caller().getClubPres(club_int))}"
    balance = contract.caller().getClubBalance(club_int)
    total = contract.caller().getClubOwnedSinceNomination(club_int)
    sent = contract.caller().getClubSentToPresSinceNomination(club_int)
    ratio = f"{round(0 if total == 0 else (sent / total) * 100)} %"

    return club_int, name, president, balance, total, sent, ratio
