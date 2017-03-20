--WARNING: Every sql statement must be in its own line.

-- First initialize node. Create group, create node and create root user. Only this created
-- user is able to change schema or change configuration. Once initialization is done
-- console will be connected as this user. Every user created in this stage will have all privileges.
-- Which means you should not create more than one. Add additional users later.
use config
insert into groups values ('grp1','cluster')
-- localnode() is whatever is in vm.args (-name ....) for node we are connected to.
insert into nodes values (localnode(),'grp1')
CREATE USER 'root' IDENTIFIED BY 'mocenum'
commit

-- Still in config db, now add second user to run queries with
CREATE USER 'mocenum' IDENTIFIED BY 'mocenum'
-- * means user has access to all actor types
GRANT read,write ON * to 'mocenum'
-- We could also set a user that only has access to type1 actors with
-- CREATE USER 'type1user' IDENTIFIED BY 'type1pass'
-- GRANT read,write ON type1 to 'type1user';
commit
