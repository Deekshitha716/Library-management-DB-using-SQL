/*
Q13. Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). 
Display the member's_id, member's name, book title, issue date, and days overdue.

Tables to join: members + books + issued_status + return_status    */
UPDATE return_status 
SET return_date = NULL
WHERE  return_id IN ('RS107', 'RS111', 'RS118');
select * from issued_status;

SELECT member_id, member_name, book_title, issued_date, return_date, CURRENT_DATE - issued_date AS over_due_days
FROM members AS m 
JOIN issued_status AS i
ON i.issued_member_id = m.member_id

JOIN books AS b 
ON b.isbn = i.issued_book_isbn

LEFT JOIN return_status AS r
ON r.issued_id = i.issued_id	#Show me all issued books, even if there is no return record
WHERE return_date IS NULL
AND
CURRENT_DATE() - issued_date > 30;

/*
Q14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
->Parameters are inputs from the user.
->Local variables are values fetched internally from tables.
->The user only returns a book using: issued_id, return_d, and tells about the book_quality
From that: ISBN, Book name must be looked up from the database. 
-> In PL/pgSQL, SELECT INTO assigns query results to variables and does not return output to the client. To display values, RAISE NOTICE or RETURN must be used.*/

ALTER TABLE return_status
ADD COLUMN book_quality VARCHAR(30);
SELECT * FROM return_status;

DELIMITER $$
CREATE PROCEDURE update_book_status(
IN p_return_id VARCHAR(30),
IN p_issued_id VARCHAR(30),
IN p_book_quality VARCHAR(30)
)
BEGIN
DECLARE v_isbn VARCHAR(20);
DECLARE v_book_name VARCHAR(75);

INSERT INTO return_status(return_id, issued_id, return_date, book_quality) VALUES
(p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

SELECT issued_book_isbn, issued_book_name INTO v_isbn, v_book_name 
FROM issued_status
WHERE issued_id = p_issued_id;

UPDATE books
SET status = 'yes'
WHERE isbn = v_isbn;

SELECT CONCAT ('Thank you for returning the book: ', v_book_name) AS message;

END;
$$
DELIMITER ;
CALL update_book_status('RS213', 'IS112', 'Good');


/*
Q15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.*/

SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM return_status;
SELECT * FROM books;

CREATE TABLE performance_report AS
SELECT 
br.branch_id,
br.manager_id,
COUNT(i.issued_id) AS books_issued,
COUNT(r.return_id) AS books_returned,
SUM(bo.rental_price) AS total_revenue
FROM issued_status AS i
JOIN employees AS e
ON e.emp_id = i.issued_emp_id
JOIN branch as br
ON br.branch_id = e.branch_id
LEFT JOIN return_status AS r 
ON r.issued_id = i.issued_id
JOIN books AS bo
ON bo.isbn = i.issued_book_isbn;

SELECT * FROM performance_report;

/*Q16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months. */

SELECT * FROM members; 
SELECT * FROM issued_status;
CREATE TABLE active_members AS 
SELECT member_name FROM members
WHERE member_id IN (
SELECT DISTINCT issued_member_id FROM issued_status
WHERE
issued_date >= DATE '2024-01-01' - INTERVAL 2 MONTH
); 
SELECT * FROM active_members;


/*Q17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch. */

SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT emp_name, COUNT(issued_emp_id), branch_id
FROM employees AS e
JOIN issued_status AS i
ON i.issued_emp_id = e.emp_id
GROUP BY issued_emp_id, branch_id
ORDER BY COUNT(issued_emp_id) DESC
LIMIT 3;


/*Q18: Stored Procedure Objective: 
Create a stored procedure to manage the status of books in a library system. 
Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
The procedure should function as follows: 
The stored procedure should take the book_id as an input parameter. 
The procedure should first check if the book is available (status = 'yes'). 
If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.  */

SELECT * FROM books;
DELIMITER $$
CREATE PROCEDURE status_of_books 
(IN book_id VARCHAR(20) )
BEGIN
DECLARE book_status VARCHAR(5);

SELECT status INTO book_status FROM books
WHERE isbn = book_id;
IF  book_status = 'yes' THEN 
	UPDATE books 
    SET status = 'no'
    WHERE isbn = book_id;
    SELECT 'Book issued successfully.' AS message;
ELSE 
	SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT= 'Error. The book is currently not available.';
END IF;
END$$
DELIMITER ;

CALL status_of_books ('978-0-06-025492-6');
