psql postgres -c "DROP DATABASE IF EXISTS political_party_db;"
psql postgres -c "CREATE DATABASE political_party_db;"
psql postgres -c "DROP USER IF EXISTS app;"
