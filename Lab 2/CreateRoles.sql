CREATE ROLE admin_role;

CREATE ROLE manager_role;

CREATE ROLE viewer_role;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_role;
GRANT ALL PRIVILEGES ON DATABASE "NotaryOffice" TO admin_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO manager_role;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO manager_role;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO viewer_role;

CREATE USER admin_user WITH PASSWORD 'admin_pass';
GRANT admin_role TO admin_user;

CREATE USER manager_user WITH PASSWORD 'manager_pass';
GRANT manager_role TO manager_user;

CREATE USER viewer_user WITH PASSWORD 'viewer_pass';
GRANT viewer_role TO viewer_user;