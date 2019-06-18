CREATE EXTENSION pgcrypto;

-----------
-- TYPES --
-----------

CREATE TYPE action_t AS ENUM ('support', 'protest');
CREATE TYPE vote_t AS ENUM ('upvote', 'downvote');

CREATE TYPE action_ret AS(
    action_id integer,
    action_type action_t,
    project_id integer,
    authority_id integer,
    upvotes integer,
    downvotes integer
);

CREATE TYPE project_ret AS(
    project_id integer,
    authority_id integer
);

CREATE TYPE votes_ret AS(
    member_id integer,
    upvotes integer,
    downvotes integer
);

CREATE TYPE trolls_ret AS(
    member_id integer,
    upvotes integer,
    downvotes integer,
    active text
);

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

-----------------------
-- PRIVATE FUNCTIONS --
-----------------------


CREATE OR REPLACE FUNCTION is_member_frozen(member_id integer, timestmp bigint) RETURNS boolean AS $$
    DECLARE
        latest_activity bigint;
    BEGIN
        SELECT member.latest_activity FROM member WHERE member.id = member_id INTO latest_activity;
        RETURN age(to_timestamp(timestmp), to_timestamp(latest_activity)) >= INTERVAL '1 YEAR';
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION add_member(
    member_id integer,
    password text,
    timestmp bigint,
    is_leader boolean DEFAULT False
) RETURNS void AS $$
    BEGIN
        INSERT INTO unique_ids VALUES(member_id);
        INSERT INTO member (id, is_leader, password, latest_activity) VALUES(member_id, is_leader, password, timestmp);
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION add_member_if_new(
    member_id integer,
    password text,
    timestmp bigint,
    is_leader boolean DEFAULT False
) RETURNS boolean AS $$
    BEGIN
        IF member_id NOT IN (SELECT member.id FROM member) THEN
            PERFORM add_member(member_id, password, timestmp, is_leader);
            RETURN True;
        END IF;
        RETURN False;
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION update_member_latest_activity(member_id integer, timestmp bigint) RETURNS void AS $$
    BEGIN
       UPDATE member SET latest_activity = timestmp WHERE id = member_id;
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION handle_member(member_id integer, password text, timestmp bigint) RETURNS boolean AS $$
    DECLARE
        is_new boolean;
        password_ok boolean;
    BEGIN

        IF is_member_frozen(member_id, timestmp) THEN
            RETURN False;
        END IF;

        SELECT add_member_if_new(member_id, password, timestmp) INTO is_new;
        IF NOT is_new THEN
            SELECT check_password(member_id, password) INTO password_ok;
            IF NOT password_ok THEN
                RETURN False; 
            END IF;
        END IF;
        RETURN True;
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION check_password(member_id integer, password text) RETURNS boolean AS $$
    BEGIN
        RETURN (SELECT member.password FROM member WHERE member.id = member_id) = password;
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION add_project(project_id integer, authority_id integer) RETURNS boolean AS $$
    BEGIN
        INSERT INTO unique_ids VALUES(project_id), (authority_id);
        INSERT INTO authority VALUES(authority_id);
        INSERT INTO project VALUES(project_id, authority_id);
        RETURN True;
    END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION add_action(
    action_type action_t,
    timestmp bigint,
    member_id integer,
    password text,
    action_id integer,
    project_id integer,
    authority_id integer DEFAULT NULL
    ) RETURNS boolean AS $$
    DECLARE
        member_ok boolean;
        project_ok boolean;
    BEGIN 

        SELECT handle_member(member_id, password, timestmp) INTO member_ok;
        IF NOT member_ok THEN 
            RETURN False;
        END IF;

        IF project_id NOT IN (SELECT id FROM unique_ids) THEN
            SELECT add_project(project_id, authority_id) INTO project_ok;
            IF NOT project_ok THEN
                RETURN False;
            END IF;
        END IF;
    
        INSERT INTO unique_ids VALUES (action_id); 
        INSERT INTO action VALUES (action_id, project_id, member_id, action_type);

        RETURN True;
        
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_vote(
    vote_type vote_t,
    member_id integer,
    action_id integer
    ) RETURNS boolean AS $$
    BEGIN
        INSERT INTO vote VALUES(action_id, member_id, vote_type);
        RETURN True; 
    END;
$$ LANGUAGE plpgsql security definer;


-------------------
-- API FUNCTIONS --
-------------------

CREATE OR REPLACE FUNCTION leader(timestmp bigint, password text, member_id integer) RETURNS boolean AS $$
    BEGIN
        PERFORM add_member(member_id, password, timestmp, True);
        RETURN True;
    END;
$$ LANGUAGE plpgsql security definer;

CREATE OR REPLACE FUNCTION support(
    timestmp bigint,
    member_id integer,
    password text,
    action_id integer,
    project_id integer,
    authority_id integer DEFAULT NULL
    ) RETURNS boolean AS $$
    BEGIN
        RETURN add_action('support', timestmp, member_id, password, action_id, project_id, authority_id);
    END;
$$ LANGUAGE plpgsql security definer;

CREATE OR REPLACE FUNCTION protest(
    timestmp bigint,
    member_id integer,
    password text,
    action_id integer,
    project_id integer,
    authority_id integer DEFAULT NULL
    ) RETURNS boolean AS $$
    BEGIN
        RETURN add_action('protest', timestmp, member_id, password, action_id, project_id, authority_id);
    END;
$$ LANGUAGE plpgsql security definer;

CREATE OR REPLACE FUNCTION upvote(
    timestmp bigint,
    member_id integer,
    password text,
    action_id integer
    ) RETURNS boolean AS $$
    DECLARE
        member_ok boolean;
    BEGIN
        SELECT handle_member(member_id, password, timestmp) INTO member_ok;
        IF NOT member_ok THEN 
            RETURN False;
        END IF;
        
        IF action_id NOT IN (SELECT id FROM action) THEN
            RETURN False;
        END IF;

        RETURN add_vote('upvote', member_id, action_id);
    END;
$$ LANGUAGE plpgsql security definer;

CREATE OR REPLACE FUNCTION downvote(
    timestmp bigint,
    member_id integer,
    password text,
    action_id integer
    ) RETURNS boolean AS $$
    DECLARE
        member_ok boolean;
    BEGIN
        SELECT handle_member(member_id, password, timestmp) INTO member_ok;
        IF NOT member_ok THEN 
            RETURN False;
        END IF;

        IF action_id NOT IN (SELECT id FROM action) THEN
            RETURN False;
        END IF;

        RETURN add_vote('downvote', member_id, action_id);  
    END;
$$ LANGUAGE plpgsql security definer;

CREATE OR REPLACE FUNCTION actions(
    timestmp bigint,
    member_id integer,
    password text,
    action_type action_t DEFAULT NULL,
    project_id integer DEFAULT NULL,
    authority_id integer DEFAULT NULL
    ) RETURNS action_ret AS $$
    DECLARE
        ret action_ret;
    BEGIN

        IF is_member_frozen(member_id, timestmp) THEN
            --OR (SELECT * FROM member WHERE member.id = member_id AND member.is_leader) IS NULL THEN
            RETURN False;
        END IF;
        
        SELECT action.id, action.action_type, action.project_id, project.authority_id, SUM(member.upvotes)::int, SUM(member.downvotes)::int
        FROM action JOIN member ON action.member_id = member.id
            JOIN project ON action.project_id = project.id
        GROUP BY action.id, project.authority_id
        ORDER BY action.id ASC INTO ret;

        -- TODO filter using optional parameters
        
        RETURN ret;

    END;
$$ LANGUAGE plpgsql security definer;

CREATE OR REPLACE FUNCTION projects(
    timestmp bigint,
    member_id integer,
    password text,
    authority_id integer DEFAULT NULL
    ) RETURNS project_ret AS $$
    DECLARE
        ret project_ret;
    BEGIN
        SELECT * FROM project INTO ret;
        RETURN ret; 
    END;
$$ LANGUAGE plpgsql security definer;

CREATE OR REPLACE FUNCTION votes(
    timestmp bigint,
    member_id integer,
    password text,
    action_id integer DEFAULT NULL,
    project_id integer DEFAULT NULL
    ) RETURNS SETOF votes_ret AS $$
    BEGIN
        RETURN QUERY
            SELECT member.id,
                (COUNT(vote.action_id) FILTER (WHERE vote.vote_type = 'upvote'))::int AS upvotes,
                (COUNT(vote.action_id) FILTER (WHERE vote.vote_type = 'downvote'))::int AS downvotes
            FROM member LEFT JOIN vote ON member.id = vote.member_id
            GROUP BY member.id
            ORDER BY member.id ASC;
    END;
$$ LANGUAGE plpgsql security definer;

CREATE OR REPLACE FUNCTION trolls(
    timestmp bigint
    ) RETURNS SETOF trolls_ret AS $$
    BEGIN
        RETURN QUERY
            SELECT member.id, member.upvotes, member.downvotes, INITCAP(is_member_frozen(member.id, timestmp)::text)
            FROM member
            ORDER BY member.downvotes - member.upvotes;
    END;
$$ LANGUAGE plpgsql security definer;

-----------
-- USERS --
-----------

CREATE ROLE app WITH ENCRYPTED PASSWORD 'qwerty';
ALTER ROLE app WITH LOGIN;

GRANT EXECUTE ON FUNCTION leader   TO app;
GRANT EXECUTE ON FUNCTION support  TO app;
GRANT EXECUTE ON FUNCTION protest  TO app;
GRANT EXECUTE ON FUNCTION upvote   TO app;
GRANT EXECUTE ON FUNCTION downvote TO app;
GRANT EXECUTE ON FUNCTION actions  TO app;
GRANT EXECUTE ON FUNCTION projects TO app;
GRANT EXECUTE ON FUNCTION votes    TO app;
GRANT EXECUTE ON FUNCTION trolls   TO app;
