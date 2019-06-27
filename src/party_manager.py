import sys
import psycopg2
import json
import ast


def parse_tuple(string):
    try:
        s = ast.literal_eval(str(string))
        if type(s) == tuple:
            return s
        return
    except:
        return


api_fun_name_to_psql_fun_name = {
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

api_arg_name_to_psql_arg_name = {
        'timestamp': 'timestmp',
        'password': 'password',
        'member': 'member_id',
        'action': 'action_id',
        'project': 'project_id',
        'authority': 'authority_id',
        'type': 'action_type',
        }

api_arg_name_to_psql_type = {
        'timestamp': 'bigint',
        'password': 'text',
        'member': 'integer',
        'action': 'integer',
        'project': 'integer',
        'authority': 'integer',
        'type': 'action_t',
        }


class ApiCall:
    def __init__(self, line):
        self.__dict__ = json.loads(line)
        

class ApiCaller:
    def __init__(self, init=False):
        self.init = init

    def call(self, api_call):
        self.error = False
        self._api_call = api_call
        call_type = list(self._api_call.__dict__)[0]
        if call_type in api_fun_name_to_psql_fun_name:
            getattr(self, api_fun_name_to_psql_fun_name[call_type])()


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
            self._connection.autocommit = True
            self._cursor = self._connection.cursor()

            if self.init:
                self._cursor.execute(open('./init.sql', 'r').read())
                self._connection.commit()
                print(json.dumps({"status": "OK"}))

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
        print(json.dumps({"status": "ERROR"}))

    
    @staticmethod
    def conv_arg(arg, arg_name):
        arg_t = api_arg_name_to_psql_type[arg_name]
        res_str = arg

        if arg_t == 'text':
            res_str = '\'' + res_str  + '\''

        res_str = api_arg_name_to_psql_arg_name[arg_name] + ' := ' + res_str + '::' + arg_t
        return res_str

    
    def _create_psql_fun_str(self, f_name, args_dict):
        args = ', '.join(
                [
                    self.conv_arg(str(args_dict[arg_name]), arg_name)
                    for arg_name in args_dict.keys()
                ]
            )
        return 'SELECT ' + f_name + '(' + args + ');'


    def _call_psql_fun(self, f_name, arg_dict):
        call_str = self._create_psql_fun_str(f_name, arg_dict)
        try:
            self._cursor.execute(call_str)
            self._connection.commit()
        except psycopg2.DatabaseError as e:
            self.error = True
            #print(e)

    def _handle_bool_psql_fun(self, f_name, arg_dict):
        self._call_psql_fun(f_name, arg_dict)
        status = self._cursor.fetchone()
        if bool(status): 
            self._print_status_ok()
        else:
            member.self._print_status_error()
    
    def _handle_set_psql_fun(self, f_name, arg_dict):
        self._call_psql_fun(f_name, arg_dict)
        if not self.error:
            result = [list(parse_tuple(list(x)[0])) for x in self._cursor]
            self._print_status_ok_data(result)
        else:
            self._print_status_error()


    def _leader(self):
        self._handle_bool_psql_fun('leader', self._api_call.leader)
            

    def _support(self):
        self._handle_bool_psql_fun('support', self._api_call.support)
    

    def _protest(self):
        self._handle_bool_psql_fun('protest', self._api_call.protest)


    def _upvote(self):
        self._handle_bool_psql_fun('upvote', self._api_call.upvote)
    

    def _downvote(self):
        self._handle_bool_psql_fun('downvote', self._api_call.downvote)


    def _actions(self):
        self._handle_set_psql_fun('actions', self._api_call.actions)


    def _projects(self):
        self._handle_set_psql_fun('projects', self._api_call.projects)


    def _votes(self):
        self._handle_set_psql_fun('votes', self._api_call.votes)


    def _trolls(self):
        self._handle_set_psql_fun('trolls', self._api_call.trolls)


init = len(sys.argv) > 1 and sys.argv[1] == '--init'
api_caller = ApiCaller(init)

for line in sys.stdin:
    api_caller.call(ApiCall(line))

api_caller.exit()
