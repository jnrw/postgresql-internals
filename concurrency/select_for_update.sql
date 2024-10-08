-- create tables
CREATE TABLE IF NOT EXISTS accounts  (
    id BIGINT PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    name VARCHAR(255) NOT NULL CHECK (name <> ''),
    balance DECIMAL(15, 2) DEFAULT 0.00 CHECK (balance >= 0.00)
);

-- insert initial data
INSERT INTO accounts (name, balance) VALUES ('Alice', 1000);
INSERT INTO accounts (name, balance) VALUES ('Bob', 500);

BEGIN; -- Session A
BEGIN; -- Session B
SELECT * FROM accounts WHERE name IN ('Alice', 'Bob') FOR UPDATE; -- Session A
SELECT * FROM accounts WHERE name IN ('Alice', 'Bob') FOR UPDATE; -- Session B -> Waiting
UPDATE accounts SET balance = balance - 100 WHERE name = 'Alice'; -- Session A balance = 900
UPDATE accounts SET balance = balance + 100 WHERE name = 'Bob'; -- Session A balance = 600
COMMIT; -- Session A -> Select for update completed and session B released to continue
UPDATE accounts SET balance = balance - 50 WHERE name = 'Bob'; -- Session B balance = 550
UPDATE accounts SET balance = balance + 50 WHERE name = 'Alice'; -- Session B balance = 950
COMMIT; -- Session B -> Select for update completed
