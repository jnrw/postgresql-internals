-- create tables
CREATE TABLE IF NOT EXISTS accounts  (
    id BIGINT PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    name VARCHAR(255) NOT NULL CHECK (name <> ''),
    balance DECIMAL(15, 2) DEFAULT 0.00 CHECK (balance >= 0.00)
);

-- insert initial data
INSERT INTO accounts (name, balance) VALUES ('Alice', 1000);
INSERT INTO accounts (name, balance) VALUES ('Bob', 500);

-- commands
BEGIN; -- session A
UPDATE accounts SET balance = balance - 100 WHERE name = 'Alice'; -- session A
SELECT * FROM accounts; -- session B
UPDATE accounts SET balance = balance + 100 WHERE name = 'Bob'; -- session A
COMMIT; -- session A

BEGIN; -- session A
UPDATE accounts SET balance = balance - 100 WHERE name = 'Alice'; -- session A
SELECT * FROM accounts; -- session B
UPDATE accounts SET balance = balance + 100 WHERE name = 'Bob'; -- session A
SELECT pid, virtualxid, transactionid, locktype, mode, * FROM pg_locks WHERE pid = pg_backend_pid(); --session A
ROLLBACK; -- session A
