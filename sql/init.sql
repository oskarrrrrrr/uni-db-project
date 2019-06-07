CREATE EXTENSION pgcrypto;

-----------
-- TYPES --
-----------

CREATE TYPE action_t AS ENUM ('support', 'protest');
CREATE TYPE vote_t AS ENUM ('upvote', 'downvote');

------------
-- TABLES --
------------

CREATE TABLE IF NOT EXISTS unique_ids(
    id INTEGER PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS member(
    id INTEGER REFERENCES unique_ids(id) PRIMARY KEY,
    is_leader BOOLEAN,
    password TEXT NOT NULL,
    latest_activity BIGINT,
    upvotes INTEGER DEFAULT 0,
    downvotes INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS authority(
    id INTEGER REFERENCES unique_ids(id) PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS project(
    id INTEGER REFERENCES unique_ids(id) PRIMARY KEY,
    authority_id INTEGER REFERENCES authority(id)
);

CREATE TABLE IF NOT EXISTS action(
    id INTEGER REFERENCES unique_ids(id) PRIMARY KEY,
    project_id INTEGER REFERENCES project(id),
    member_id INTEGER REFERENCES member(id),
    action_type action_t
);

CREATE TABLE IF NOT EXISTS vote(
    action_id INTEGER REFERENCES action(id), 
    member_id INTEGER REFERENCES member(id),
    vote_type vote_t,
    PRIMARY KEY(action_id, member_id)
);

---------------
-- FUNCTIONS --
---------------

CREATE OR REPLACE FUNCTION leader(timestmp bigint, password text, member_id integer) RETURNS integer AS $$
    BEGIN
        INSERT INTO unique_ids VALUES(member_id);
        INSERT INTO member VALUES(member_id, True, password, timestmp);
        RETURN timestmp;
    END;
$$ LANGUAGE plpgsql;

-----------
-- USERS --
-----------

CREATE ROLE app WITH ENCRYPTED PASSWORD 'qwerty';
GRANT EXECUTE ON FUNCTION leader TO app;
