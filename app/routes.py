from flask import render_template, flash, redirect, url_for
from web3.exceptions import ContractLogicError

from app import app, contract, accounts, w3
from app.forms import AdminToClubTransferForm, StudentRegistrationForm, ClubCreationForm, \
    ClubToStudentTransferForm, StudentToStudentTransferForm
from app.utils import string_to_bytes32


@app.route('/')
@app.route('/index')
def index():
    return render_template('views/index.html')


@app.route('/display/profiles')
def view_profiles():
    profiles = [(f"Compte {i}", a, contract.caller().getStudentBalance(a), contract.caller().studentHasCert(a)) for
                i, a in enumerate(accounts) if contract.caller().studentExists(a)]
    return render_template('views/actions/other/view_profiles.html', students=profiles)


@app.route('/display/clubs')
def view_clubs():
    clubs = [(i, contract.caller().getClubName(i).decode('utf-8').strip("0"),
              f"Compte {accounts.index(contract.caller().getClubPres(i))}", contract.caller().getClubBalance(i)) for
             i in range(contract.caller().getClubCount())]
    return render_template('views/actions/other/view_clubs.html', clubs=clubs)


@app.route('/transfer/admin/club', methods=['GET', 'POST'])
def admin_to_club():
    form = AdminToClubTransferForm.new()
    if form.validate_on_submit():
        try:
            h = contract.functions.sendCipaAlbusToClub(
                contract.caller().getClubIntFromName(string_to_bytes32(form.club.data)), form.amount.data).transact(
                {'from': accounts[int(form.identify_as.data)]})
            w3.eth.waitForTransactionReceipt(h)
            flash('Transfer of {} CIPA from admin to club {}'.format(
                form.amount.data, form.club.data))
        except ContractLogicError as e:
            flash(str(e).split("revert")[-1])
        return redirect(url_for("index"))
    return render_template("views/actions/transfer/admin_to_club.html", form=form)


@app.route('/transfer/club/student', methods=['GET', 'POST'])
def club_to_student():
    form = ClubToStudentTransferForm.new()
    if form.validate_on_submit():
        try:
            h = contract.functions.sendCipaClubToStudent(
                contract.caller().getClubIntFromName(string_to_bytes32(form.club.data)),
                accounts[int(form.student.data)], form.amount.data).transact(
                {'from': accounts[int(form.identify_as.data)]})
            w3.eth.waitForTransactionReceipt(h)
            flash('Transfer of {} CIPA from club {} to  {}'.format(
                form.amount.data, form.club.data, form.student.data))
        except ContractLogicError as e:
            flash(str(e).split("revert")[-1])
        return redirect(url_for("index"))
    return render_template("views/actions/transfer/club_to_student.html", form=form)


@app.route('/transfer/student/student', methods=['GET', 'POST'])
def student_to_student():
    form = StudentToStudentTransferForm()
    if form.validate_on_submit():
        try:
            h = contract.functions.sendCipaStudentToStudent(
                accounts[int(form.student.data)], form.amount.data).transact(
                {'from': accounts[int(form.identify_as.data)]})
            w3.eth.waitForTransactionReceipt(h)
            flash('Transfer of {} CIPA from student {} to  {}'.format(
                form.amount.data, form.identify_as.data, form.student.data))
        except ContractLogicError as e:
            flash(str(e).split("revert")[-1])
        return redirect(url_for("index"))
    return render_template("views/actions/transfer/student_to_student.html", form=form)


@app.route('/admin/management/register', methods=['GET', 'POST'])
def register_student():
    form = StudentRegistrationForm()
    if form.validate_on_submit():
        try:
            h = contract.functions.registerStudent(accounts[int(form.student.data)]).transact(
                {'from': accounts[int(form.identify_as.data)]})
            w3.eth.waitForTransactionReceipt(h)
            flash('Étudiant {} inscrit avec succès'.format(form.student.data))
        except ContractLogicError as e:
            flash(str(e).split("revert")[-1])
        return redirect(url_for("index"))
    return render_template("views/actions/admin/management/register_student.html", form=form)


@app.route('/admin/management/create', methods=['GET', 'POST'])
def create_club():
    form = ClubCreationForm()
    if form.validate_on_submit():
        try:
            h = contract.functions.createClub(accounts[int(form.president.data)],
                                              string_to_bytes32(form.club_name.data)).transact(
                {'from': accounts[int(form.identify_as.data)]})
            w3.eth.waitForTransactionReceipt(h)
            flash('Club {} créé avec succès'.format(form.club_name.data))
        except ContractLogicError as e:
            flash(str(e).split("revert")[-1])
        return redirect(url_for("index"))
    return render_template("views/actions/admin/management/create_club.html", form=form)