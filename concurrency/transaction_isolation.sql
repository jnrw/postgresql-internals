-- create tables
CREATE TABLE IF NOT EXISTS accounts  (
    id BIGINT PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    name VARCHAR(255) NOT NULL CHECK (name <> ''),
    balance DECIMAL(15, 2) DEFAULT 0.00 CHECK (balance >= 0.00)
);

-- insert initial data
INSERT INTO accounts (name, balance) VALUES ('Alice', 1000);
INSERT INTO accounts (name, balance) VALUES ('Bob', 500);

-- Transaction Isolation Levels: Read committed, Repeatable read, Serializable

--  Dirty read: A transaction reads data written by a concurrent uncommitted transaction.
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED; -- Session A
UPDATE accounts SET name = 'Anne' WHERE name = 'Alice'; -- Session A
BEGIN  TRANSACTION ISOLATION LEVEL READ COMMITTED; -- Session B
SELECT * FROM accounts; -- Session B -> dirty read not allowed, Session B can't see the updates;
ROLLBACK; -- Session B
ROLLBACK; -- Session A

--  Nonrepeatable read: A transaction re-reads data it has previously read and finds that data has been modified by
--                      another transaction (that committed since the initial read).
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED; -- Session A
UPDATE accounts SET name = 'Anne' WHERE name = 'Alice'; -- Session A
BEGIN  TRANSACTION ISOLATION LEVEL READ COMMITTED; -- Session B
SELECT * FROM accounts; -- Session B -> name = Alice
COMMIT; -- Session A -> name = Anne
SELECT * FROM accounts; -- Session B -> Session B can see name = Anne
ROLLBACK; -- Session B

BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED; -- Session A
BEGIN  TRANSACTION ISOLATION LEVEL REPEATABLE READ; -- Session B
SELECT * FROM accounts; -- Session B -> name = Bob
UPDATE accounts SET name = 'Maria' WHERE name = 'Bob'; -- Session A
SELECT * FROM accounts; -- Session B -> name = Bob
COMMIT; -- Session A -> name = Maria
SELECT * FROM accounts; -- Session B -> name = Bob; Nonrepeatable read not possible, Session B can't see name = Maria
ROLLBACK; -- Session B


--  Phantom read: A transaction re-executes a query returning a set of rows that satisfy a search condition and finds
--                that the set of rows satisfying the condition has changed due to another recently-committed
--                transaction.
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED; -- Session A
BEGIN  TRANSACTION ISOLATION LEVEL READ COMMITTED; -- Session B
SELECT * FROM accounts WHERE name = 'Maria'; -- Session B -> name = Maria; 1 row
UPDATE accounts SET name = 'Bob' WHERE name = 'Maria'; -- Session A
COMMIT; -- Session A -> name = Bob
SELECT * FROM accounts WHERE name = 'Maria'; -- Session B -> Phantom read allowed; name = Bob, 0 rows
ROLLBACK; -- Session B

-- Serialization Anomaly: The result of successfully committing a group of transactions is inconsistent with all
--                        possible orderings of running those transactions one at a time.

-- insert initial data
TRUNCATE TABLE accounts;
INSERT INTO accounts (name, balance) VALUES ('Alice', 1000);
INSERT INTO accounts (name, balance) VALUES ('Bob', 500);

BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED; -- Session A
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED; -- Session B
SELECT balance FROM accounts WHERE name = 'Alice'; -- Session A = 1000
SELECT balance FROM accounts WHERE name = 'Alice'; -- Session B = 1000
UPDATE accounts SET balance = 1000 - 700 WHERE name = 'Alice'; -- Session A; balance = 300
UPDATE accounts SET balance = 1000 - 100 WHERE name = 'Alice'; -- Session B; balance = 900
COMMIT; -- Session A
COMMIT; -- Session B
SELECT balance FROM accounts WHERE name = 'Alice'; -- Session A; balance = 900 !! Final balance is incorrect
SELECT balance FROM accounts WHERE name = 'Alice'; -- Session B; balance = 900 !! Final balance is incorrect

-- insert initial data
TRUNCATE TABLE accounts;
INSERT INTO accounts (name, balance) VALUES ('Alice', 1000);
INSERT INTO accounts (name, balance) VALUES ('Bob', 500);

BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE; -- Session A
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE; -- Session B
SELECT balance FROM accounts WHERE name = 'Alice'; -- Session A = 1000
SELECT balance FROM accounts WHERE name = 'Alice'; -- Session B = 1000
UPDATE accounts SET balance = 1000 - 700 WHERE name = 'Alice'; -- Session A; balance = 300
UPDATE accounts SET balance = 1000 - 100 WHERE name = 'Alice'; -- Session B; balance = 900
COMMIT; -- Session A [40001] ERROR: could not serialize access due to concurrent update
COMMIT; -- Session B
SELECT balance FROM accounts WHERE name = 'Alice'; -- Session A; balance = 300
SELECT balance FROM accounts WHERE name = 'Alice'; -- Session B; [25P02] ERROR: current transaction is aborted, commands ignored until end of transaction block

