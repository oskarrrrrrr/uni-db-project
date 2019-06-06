import sys
import psycopg2
import json


json_2_api_call = {
        'open': '_open',
        'leader': '_leader',
        'support': '_support',
        'protest': '_protest',
        'upvote': '_upvote',
        'downvote': '_downvote',
        'actions': '_actions',
        'project': '_project',
        'votes': '_votes',
        'trolls': '_trolls',
        }



def initialize_db():
    try:
        connection = psycopg2.connect(user = "init",
                                      password = "qwerty",
                                      database = "political_party_db")

        cursor = connection.cursor()
        cursor.execute(open('../sql/init.sql', 'r').read())
        connection.commit()
        #record = cursor.fetchone()

    except (Exception, psycopg2.Error) as error :
        print ("Error while connecting to PostgreSQL", error)

    finally:
        if(connection):
            cursor.close()
            connection.close()


class ApiCall:
    def __init__(self, line):
        self.__dict__ = json.loads(line)
        

class ApiCaller:
    def __init__(self, api_call):
        self.api_call = api_call


    def call(self):
        call_type = list(self.api_call.__dict__)[0]
        if call_type in json_2_api_call:
            getattr(self, json_2_api_call[call_type])()


    def _open(self):
        pass


    def _leader(self):
        pass


    def _support(self):
        pass

    
    def _protest(self):
        pass


    def _upvote(self):
        pass

    
    def _downvote(self):
        pass


    def _actions(self):
        pass


    def _projects(self):
        pass


    def _votes(self):
        pass


    def _trolls(self):
        pass


if sys.argv[1] == '--init':
    initialize_db()


for line in sys.stdin:
    api_caller = ApiCaller(ApiCall(line))
    api_caller.call()

