CREATE TYPE action_t AS ENUM ('support', 'protest');
CREATE TYPE vote_t AS ENUM ('upvote', 'downvote');


CREATE TABLE unique_ids(
    id INTEGER PRIMARY KEY
);

CREATE TABLE member(
    id INTEGER REFERENCES unique_ids(id) PRIMARY KEY,
    is_leader BOOLEAN,
    password TEXT,
    latest_activity BIGINT,
    upvotes INTEGER,
    downvotes INTEGER
);

CREATE TABLE authority(
    id INTEGER REFERENCES unique_ids(id) PRIMARY KEY
);

CREATE TABLE project(
    id INTEGER REFERENCES unique_ids(id) PRIMARY KEY,
    authority_id INTEGER REFERENCES authority(id)
);

CREATE TABLE action(
    id INTEGER REFERENCES unique_ids(id) PRIMARY KEY,
    project_id INTEGER REFERENCES project(id),
    member_id INTEGER REFERENCES member(id),
    action_type action_t
);

CREATE TABLE vote(
    action_id INTEGER REFERENCES action(id), 
    member_id INTEGER REFERENCES member(id),
    vote_type vote_t,
    PRIMARY KEY(action_id, member_id)
);
