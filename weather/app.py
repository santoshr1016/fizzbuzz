from flask import Flask, render_template, request, redirect, url_for, flash
from flask_sqlalchemy import SQLAlchemy
import requests

app = Flask(__name__)
app.config['DEBUG'] = True
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///weather.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = "thisissecret"

db = SQLAlchemy(app)


class City(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), nullable=False)


url = 'http://api.openweathermap.org/data/2.5/weather?q={}&units=metric&appid={}'
key = "3a129bca1687c65ed68ad9d7c96af8e3"


@app.route('/')
def index_get():
    cities = City.query.all()
    weather_data = []

    for city in cities:
        response = get_weather_data(city.name)
        weather = {
            'city': city.name,
            'temperature': response['main']['temp'],
            'description': response['weather'][0]['description'],
            'icon': response['weather'][0]['icon']
        }
        weather_data.append(weather)

    return render_template('weather.html', weather_data=weather_data)


def get_weather_data(city):
    response = requests.get(url.format(city, key)).json()
    return response


@app.route('/', methods=['POST'])
def index_post():
    err_msg = ''
    new_city = request.form.get('city')
    if new_city:
        existing_city = City.query.filter_by(name=new_city).first()
        if not existing_city:
            resp = get_weather_data(new_city)
            if resp['cod'] == 200:
                new_city_obj = City(name=new_city)
                db.session.add(new_city_obj)
                db.session.commit()
            else:
                err_msg = "City {} does not exists in the world".format(new_city)
        else:
            err_msg = '{} already exists'.format(existing_city.name)
    print(err_msg)
    if err_msg:
        flash(err_msg, 'error')
    else:
        flash('City Added successfully')
    return redirect(url_for('index_get'))


@app.route('/delete/<name>')
def delete_city(name):
    city = City.query.filter_by(name=name).first()
    db.session.delete(city)
    db.session.commit()
    flash(f"Successfully deleted city { city.name }", "success")
    return redirect(url_for('index_get'))
