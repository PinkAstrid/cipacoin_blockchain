from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, BooleanField, SubmitField, SelectField, IntegerField
from wtforms.validators import DataRequired, ValidationError, InputRequired, Length, Regexp, NumberRange

import app
from app import accounts, contract

accounts_choices = [(i, f"Compte {i}") for i in range(len(accounts))]


def EthAddr(form, field):
    if not app.w3.isAddress(field.data):
        raise ValidationError('Field must be a valid eth address')


class GenericForm(FlaskForm):
    identify_as = SelectField("S'identifier en tant que", choices=accounts_choices, validators=[InputRequired()])
    submit = SubmitField("Valider")


class AdminToClubTransferForm(GenericForm):
    club = SelectField(validators=[InputRequired()])
    amount = IntegerField("Montant", validators=[InputRequired()])

    @classmethod
    def new(cls):
        form = cls()
        form.club.choices = [contract.caller().getClubName(x).decode('utf-8').strip("0") for x in
                             range(contract.caller().getClubCount())]
        return form


class ClubToStudentTransferForm(GenericForm):
    club = SelectField(validators=[InputRequired()])
    student = SelectField("Étudiant", choices=accounts_choices, validators=[InputRequired()])
    amount = IntegerField("Montant", validators=[InputRequired()])

    @classmethod
    def new(cls):
        form = cls()
        form.club.choices = [contract.caller().getClubName(x).decode('utf-8').strip("0") for x in
                             range(contract.caller().getClubCount())]
        return form


class StudentToStudentTransferForm(GenericForm):
    student = SelectField("Étudiant", choices=accounts_choices, validators=[InputRequired()])
    amount = IntegerField("Montant", validators=[InputRequired()])


class StudentRegistrationForm(GenericForm):
    student = SelectField("Étudiant", choices=accounts_choices, validators=[InputRequired()])


class ClubCreationForm(GenericForm):
    president = SelectField("Président", choices=accounts_choices, validators=[InputRequired()])
    club_name = StringField("Nom du club", validators=[InputRequired(), Length(max=32),
                                                       Regexp("[A-Za-z0-9 ]+")])


class PresidentChangeForm(GenericForm):
    club = SelectField(validators=[InputRequired()])
    president = SelectField("Nouveau Président", choices=accounts_choices, validators=[InputRequired()])

    @classmethod
    def new(cls):
        form = cls()
        form.club.choices = [contract.caller().getClubName(x).decode('utf-8').strip("0") for x in
                             range(contract.caller().getClubCount())]
        return form


class ValidationThresholdForm(GenericForm):
    amount = IntegerField("Valeur", validators=[InputRequired(), NumberRange(min=0)])


class SelfPaymentThresholdForm(GenericForm):
    amount = IntegerField("Pourcentage", validators=[InputRequired(), NumberRange(min=0, max=100)])


class CertificateValidationForm(GenericForm):
    pass
