import sys
import psycopg2

print(*(sys.argv[1:]))

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
