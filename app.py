from flask import Flask
from flask_restful import Api
from microservice.resources import Fizzbuzz, HelloApp

app = Flask(__name__)

api = Api(app)
api.add_resource(Fizzbuzz, '/api/fizzbuzz')
api.add_resource(HelloApp, '/')


if __name__ == '__main__':
    app.run(debug=True)
