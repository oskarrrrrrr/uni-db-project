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
        connection = psycopg2.connect(user     = "init",
                                      password = "qwerty",
                                      database = "student")

        cursor = connection.cursor()
        cursor.execute(open('../sql/init.sql', 'r').read())
        connection.commit()

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
    def __init__(self):
        pass


    def call(self, api_call):
        self._api_call = api_call
        call_type = list(self._api_call.__dict__)[0]
        if call_type in json_2_api_call:
            getattr(self, json_2_api_call[call_type])()


    def exit(self):
        if self._connection:
            self._cursor.close()
            self._connection.close()


    def _open(self):
        try:
            self._connection = psycopg2.connect(
                    user     = self._api_call.open['login'],
                    password = self._api_call.open['password'],
                    database = self._api_call.open['database']
                    )
            self._cursor = self._connection.cursor()

        except (Exception, psycopg2.Error) as error:
            print('Error while connection to PostgreSQL', error)
            exit()


    def _leader(self):
        self._cursor.execute('select leader(' + \
                str(self._api_call.leader['timestamp']) + ', ' + \
                '\'' + str(self._api_call.leader['password'])  + '\', ' + \
                str(self._api_call.leader['member'])    + ');')
        self._connection.commit() 
        result = self._cursor.fetchone()
        print('result: ' + str(result))


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

api_caller = ApiCaller()
for line in sys.stdin:
    api_caller.call(ApiCall(line))
api_caller.exit()
