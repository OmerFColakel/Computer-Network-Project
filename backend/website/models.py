from flask_login import UserMixin
from .extensions import db



class User(db.Model, UserMixin):
    __tablename__ = 'users'
    id = db.Column(db.Text(), primary_key=True)
    email = db.Column(db.String(), unique=True, nullable=False)
    password_hash = db.Column(db.Text(), nullable=False)
    current_directory = db.Column(db.Text(), nullable=False)
