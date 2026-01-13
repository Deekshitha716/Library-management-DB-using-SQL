CREATE TABLE branch(
branch_id VARCHAR(10) PRIMARY KEY,
manager_id	VARCHAR(10),
branch_address VARCHAR(30),
contact_no VARCHAR(30)
);

CREATE TABLE employees(
emp_id VARCHAR(10) PRIMARY KEY,
emp_name VARCHAR(30),	
position VARCHAR(15),
salary INT,
branch_id VARCHAR(15)
);

CREATE TABLE books(
isbn VARCHAR(20) PRIMARY KEY,	
book_title VARCHAR(75),
category VARCHAR(20),
rental_price FLOAT,	
status VARCHAR(5),
author VARCHAR(30),
publisher VARCHAR(30)
);

CREATE TABLE members(
member_id VARCHAR(10) PRIMARY KEY,	
member_name VARCHAR(20),	
member_address VARCHAR(30),
reg_date DATE
);

CREATE TABLE issued_status(
issued_id  VARCHAR(10) PRIMARY KEY,	
issued_member_id VARCHAR(10),
issued_book_name VARCHAR(75),
issued_date DATE,	
issued_book_isbn VARCHAR(30),
issued_emp_id VARCHAR(15)
);

CREATE TABLE return_status(
return_id VARCHAR(20) PRIMARY KEY,
issued_id VARCHAR(20),
return_book_name VARCHAR(50),
return_date	DATE,
return_book_isbn VARCHAR(20)
);

SELECT * FROM return_status;
SELECT COUNT(*) FROM return_status;

#FOREIGN KEYS
ALTER TABLE issued_status
DROP FOREIGN KEY fk_members;
ALTER TABLE issued_status
ADD CONSTRAINT fk_members
FOREIGN KEY (issued_member_id)
REFERENCES members(member_id);

ALTER TABLE issued_status
ADD CONSTRAINT fk_isbn
FOREIGN KEY (issued_book_isbn)
REFERENCES books(isbn);

ALTER TABLE issued_status
ADD CONSTRAINT fk_emp_id
FOREIGN KEY (issued_emp_id)
REFERENCES employees(emp_id);

ALTER TABLE return_status
ADD CONSTRAINT fk_issued_id
FOREIGN KEY (issued_id)
REFERENCES issued_status(issued_id);

SELECT issued_id
FROM return_status
WHERE issued_id NOT IN(
SELECT issued_id FROM issued_status
);

DELETE FROM return_address
WHERE issued_id NOT IN(
SELECT issued_id FROM issued_status
);

ALTER TABLE employees
ADD CONSTRAINT fk_branch_id
FOREIGN KEY (branch_id)
REFERENCES branch(branch_id);

#TASKS:
#Q1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO books
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;

 #Q2. Update an Existing Member's Address
 UPDATE members
 SET member_address = '798 Oak Street'
 WHERE member_id = 'C101';
 
 SELECT * FROM members;
 
 #Q3. Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
DELETE FROM issued_status
WHERE issued_id = 'IS121';
SELECT * FROM issued_status;

 #Q4. Retrieve All Books Issued by a Specific Employee 
 -- Objective: Select all books issued by the employee with emp_id = 'E101'.
 SELECT * FROM issued_status
 WHERE issued_emp_id = 'E101';
 
 #Q5. List Members Who Have Issued More Than One Book 
 -- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT issued_member_id   #, COUNT(issued_id)
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(issued_id)>1;

#OR
SELECT issued_member_id , member_name 
FROM issued_status AS ist
JOIN members AS mem
ON ist.issued_member_id = mem.member_id 
GROUP BY issued_member_id, member_name
HAVING COUNT(ist.issued_id)>1;

-- CTAS
#Q6. Create Summary Tables: Use CTAS to generate new tables based on query results - each book and total book_issued_cnt**
CREATE TABLE book_issued_count AS
SELECT isbn, book_title, COUNT(issued_id) AS total_book_issued_cnt
FROM books 
JOIN issued_status
ON books.isbn = issued_status.issued_book_isbn
GROUP BY isbn, issued_book_isbn;

SELECT * FROM book_issued_count;

#Q7. Retrieve All Books in a Specific Category
SELECT category, COUNT(isbn)
FROM books
GROUP BY category;

SELECT * FROM books
WHERE category = 'History';

 #Q8. Find Total Rental Income by Category
 #This method will select all the books including the ones that were never published. So it does not give the demand of the book.
 SELECT category, SUM(rental_price), COUNT(*)
 FROM books
GROUP BY category;

 #This method will select only the books that were published. So it gives the demand of the book. and the revenue it earned.
 SELECT category, SUM(rental_price), COUNT(*)
 FROM books AS b
 JOIN issued_id AS i
 ON b.isbn = i.issued_book_isbn
 GROUP BY category;

#Q9. List Members Who Registered in the Last 180 Days
INSERT INTO members VALUES 
('C120', 'Aaron', '124 Caesar St', CURRENT_DATE),
('C121', 'Flynn', '210 Caesar St', '2025-10-10');
SELECT * FROM members
WHERE reg_date >= CURRENT_DATE() - INTERVAL 180 DAY;

#Q10. List Employees with Their Branch Manager's Name and their branch details:
#Managers and employees are NOT different types of rows.
#A manager is just an employee whose emp_id is stored in branch.manager_id
#Same table + multiple roles → multiple aliases

SELECT * FROM branch;
SELECT e2.emp_name AS manager, e1.emp_name AS employee, manager_id
FROM employees AS e1
JOIN branch AS b
ON e1.branch_id = b.branch_id   #for normal employees
JOIN employees AS e2
ON b.manager_id	= e2.emp_id;	#for manager;
 

#Q11. Create a Table of Books with Rental Price Above a Certain Threshold 7USD
SELECT * FROM books;
CREATE TABLE books_rp_gt_7 AS 
SELECT book_title, rental_price
FROM books 
WHERE rental_price > '7';

SELECT * FROM books_rp_gt_7;


#Q12. Retrieve the List of Books Not Yet Returned
SELECT * FROM issued_status;
SELECT * FROM return_status;

#LEFT JOIN preserves all rows from the issued table, allowing unmatched rows (unreturned books) to appear as NULL in the return table, which can then be filtered.
SELECT DISTINCT issued_book_name
FROM issued_status AS i
LEFT JOIN return_status AS r
ON i.issued_id = r.return_id
WHERE return_id IS NULL
GROUP BY issued_book_name;