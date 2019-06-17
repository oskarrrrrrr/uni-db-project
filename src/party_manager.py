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
            print(json.dumps({"status": "OK"}))


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


    @staticmethod 
    def _print_status_ok():
        print(json.dumps({"status": "OK"}))


    @staticmethod
    def _print_status_ok_data(data):
        print(json.dumps({"status": "OK", "data": data}))
    

    @staticmethod
    def _print_status_error():
        print(json.dumps({"status": "Error"}))

    
    @staticmethod
    def conv_arg(arg, arg_t):
        if arg_t == 'text':
            return '\'' + arg + '\'::' + arg_t
        return arg + '::' + arg_t

    
    def _create_psql_fun_str(self, f_name, args_dict, arg_types):
        args = ', '.join([self.conv_arg(str(arg), arg_type) for arg, arg_type in zip(list(args_dict.values()), arg_types)])
        return 'SELECT ' + f_name + '(' + args + ');'


    def _call_psql_fun(self, f_name, arg_dict, arg_types):
        self._cursor.execute(self._create_psql_fun_str(f_name, arg_dict, arg_types))
        self._connection.commit()
    

    def _handle_bool_psql_fun(self, f_name, arg_dict, arg_types):
        self._call_psql_fun(f_name, arg_dict, arg_types)
        status = self._cursor.fetchone()
        if bool(status): 
            self._print_status_ok()
        else:
            self._print_status_error()


    def _leader(self):
        self._handle_bool_psql_fun(
                'leader',
                self._api_call.leader,
                ['bigint', 'text', 'integer']
                )
            

    def _support(self):
        self._handle_bool_psql_fun(
                'support',
                self._api_call.support,
                ['bigint', 'integer', 'text', 'integer', 'integer', 'integer']
                )
    
    def _protest(self):
        self._handle_bool_psql_fun(
                'protest',
                self._api_call.protest,
                ['bigint', 'integer', 'text', 'integer', 'integer', 'integer']
                )


    def _upvote(self):
        self._handle_bool_psql_fun(
                'upvote',
                self._api_call.upvote,
                ['bigint', 'integer', 'text', 'integer']
                )
    
    def _downvote(self):
        self._handle_bool_psql_fun(
                'downvote',
                self._api_call.downvote,
                ['bigint', 'integer', 'text', 'integer']
                )


    def _actions(self):
        print('call actions')


    def _projects(self):
        print('call projects')


    def _votes(self):
        print('call votes')


    def _trolls(self):
        print('call trolls')


if len(sys.argv) > 1 and sys.argv[1] == '--init':
    initialize_db()
    


api_caller = ApiCaller()
for line in sys.stdin:
    #print(line)
    api_caller.call(ApiCall(line))
api_caller.exit()
