from flask import render_template
from flask_restful import Resource, reqparse


class HelloApp(Resource):
    def get(self):
        return render_template("home.html")
        # return {"message": "This is Fizz Buzz home"}, 200


class Fizzbuzz(Resource):
    """
    This is the API which will grab the IP address from running
    container and save it into the database.
    """
    def get(self):
        return {"message": "This is Fizz Buzz api"}, 200

    def post(self):
        parser = reqparse.RequestParser()
        parser.add_argument('number', type=int)
        args = parser.parse_args()
        num = args['number']
        result = []
        for i in range(1, num+1):
            if i % 15 == 0:
                result.append("FizzBuzz")
                continue
            elif i % 3 == 0:
                result.append("Fizz")
                continue
            elif i % 5 == 0:
                result.append("Buzz")
                continue
            result.append(i)

        if len(result):
            data = {'message': "Fizzbuzz computed", 'result': '{}'.format(result)}
            return data, 200
        return {"message": "Couldn't compute the fizzbuzz "}, 404