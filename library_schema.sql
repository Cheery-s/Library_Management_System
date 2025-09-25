-- =====================================================
--  Library Management System Database Schema
-- =====================================================

CREATE DATABASE library_management_system;
USE library_management_system;

-- =====================================================
-- TABLE: categories
-- =====================================================
CREATE TABLE categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLE: publishers
-- =====================================================
CREATE TABLE publishers (
    publisher_id INT PRIMARY KEY AUTO_INCREMENT,
    publisher_name VARCHAR(150) NOT NULL,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    website VARCHAR(100),
    established_year YEAR,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLE: authors
-- =====================================================
CREATE TABLE authors (
    author_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE,
    nationality VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    biography TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLE: books
-- =====================================================
CREATE TABLE books (
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    isbn VARCHAR(20) NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    publication_date DATE,
    pages INT CHECK (pages > 0),
    language VARCHAR(50) DEFAULT 'English',
    edition VARCHAR(50),
    summary TEXT,
    total_copies INT NOT NULL DEFAULT 1 CHECK (total_copies > 0),
    available_copies INT NOT NULL DEFAULT 1 CHECK (available_copies >= 0),
    category_id INT,
    publisher_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign Key Constraints
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
    FOREIGN KEY (publisher_id) REFERENCES publishers(publisher_id) ON DELETE SET NULL,
    
    -- Check constraint to ensure available copies don't exceed total copies
    CONSTRAINT chk_available_copies CHECK (available_copies <= total_copies)
);

-- =====================================================
-- TABLE: book_authors (Many-to-Many relationship)
-- =====================================================
CREATE TABLE book_authors (
    book_id INT,
    author_id INT,
    author_role ENUM('Primary Author', 'Co-Author', 'Editor', 'Translator') DEFAULT 'Primary Author',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Composite Primary Key
    PRIMARY KEY (book_id, author_id),
    
    -- Foreign Key Constraints
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE CASCADE
);

-- =====================================================
-- TABLE: member_types
-- =====================================================
CREATE TABLE member_types (
    type_id INT PRIMARY KEY AUTO_INCREMENT,
    type_name VARCHAR(50) NOT NULL UNIQUE,
    max_books_allowed INT NOT NULL DEFAULT 3,
    loan_period_days INT NOT NULL DEFAULT 14,
    fine_per_day DECIMAL(5,2) NOT NULL DEFAULT 0.50,
    membership_fee DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    description TEXT
);

-- =====================================================
-- TABLE: members
-- =====================================================
CREATE TABLE members (
    member_id INT PRIMARY KEY AUTO_INCREMENT,
    member_number VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    date_of_birth DATE NOT NULL,
    membership_start_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    membership_end_date DATE,
    type_id INT NOT NULL,
    status ENUM('Active', 'Suspended', 'Expired', 'Cancelled') DEFAULT 'Active',
    total_fines DECIMAL(8,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign Key Constraints
    FOREIGN KEY (type_id) REFERENCES member_types(type_id),
    
    -- Check constraints
    CONSTRAINT chk_membership_dates CHECK (membership_end_date IS NULL OR membership_end_date > membership_start_date),
    CONSTRAINT chk_birth_date CHECK (date_of_birth <= membership_start_date)
);

-- =====================================================
-- TABLE: staff
-- =====================================================
CREATE TABLE staff (
    staff_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    position VARCHAR(100) NOT NULL,
    hire_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    salary DECIMAL(10,2),
    status ENUM('Active', 'On Leave', 'Terminated') DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLE: transactions
-- =====================================================
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    staff_id INT NOT NULL,
    transaction_type ENUM('Borrow', 'Return', 'Renew') NOT NULL,
    transaction_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    due_date DATE,
    return_date DATE,
    fine_amount DECIMAL(8,2) DEFAULT 0.00,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Key Constraints
    FOREIGN KEY (member_id) REFERENCES members(member_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
    
    -- Check constraints
    CONSTRAINT chk_return_after_borrow CHECK (return_date IS NULL OR return_date >= transaction_date),
    CONSTRAINT chk_due_after_transaction CHECK (due_date IS NULL OR due_date >= transaction_date)
);

-- =====================================================
-- TABLE: reservations
-- =====================================================
CREATE TABLE reservations (
    reservation_id INT PRIMARY KEY AUTO_INCREMENT,
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    reservation_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    expiry_date DATE NOT NULL,
    status ENUM('Active', 'Fulfilled', 'Cancelled', 'Expired') DEFAULT 'Active',
    priority_number INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign Key Constraints
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    
    -- Ensure expiry date is after reservation date
    CONSTRAINT chk_expiry_after_reservation CHECK (expiry_date > reservation_date)
);

-- =====================================================
-- TRIGGERS for automatic inventory management
-- =====================================================

-- Decrease available copies when borrowed
DELIMITER $$
CREATE TRIGGER borrow_book
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
  IF NEW.transaction_type = 'Borrow' THEN
    UPDATE books 
    SET available_copies = available_copies - 1
    WHERE book_id = NEW.book_id AND available_copies > 0;
  END IF;
END$$
DELIMITER ;

-- Increase available copies when returned
DELIMITER $$
CREATE TRIGGER return_book
AFTER UPDATE ON transactions
FOR EACH ROW
BEGIN
  IF NEW.transaction_type = 'Return' AND NEW.return_date IS NOT NULL THEN
    UPDATE books 
    SET available_copies = available_copies + 1
    WHERE book_id = NEW.book_id;
  END IF;
END$$
DELIMITER ;

-- =====================================================
-- INDEXES for better query performance
-- =====================================================
CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_books_isbn ON books(isbn);
CREATE INDEX idx_members_email ON members(email);
CREATE INDEX idx_members_member_number ON members(member_number);
CREATE INDEX idx_transactions_member_date ON transactions(member_id, transaction_date);
CREATE INDEX idx_transactions_book_date ON transactions(book_id, transaction_date);
CREATE INDEX idx_authors_name ON authors(last_name, first_name);

-- =====================================================
-- SAMPLE DATA INSERTION (CORRECTED ORDER)
-- =====================================================

-- 1. Insert Categories FIRST (no dependencies)
INSERT INTO categories (category_name, description) VALUES
('Fiction', 'Novels, short stories, and other fictional works'),
('Non-Fiction', 'Factual books including biographies, history, science'),
('Science Fiction', 'Science fiction and fantasy novels'),
('Mystery & Thriller', 'Mystery, thriller, and suspense novels'),
('Romance', 'Romantic fiction and related genres'),
('Children', 'Books suitable for children and young readers'),
('Academic', 'Textbooks and academic reference materials'),
('Biography', 'Life stories and autobiographies'),
('History', 'Historical books and documentaries'),
('Technology', 'Computer science, programming, and technology books');

-- 2. Insert Publishers (no dependencies)
INSERT INTO publishers (publisher_name, address, phone, email, website, established_year) VALUES
('Penguin Random House', '1745 Broadway, New York, NY 10019', '+1-212-782-9000', 'info@penguinrandomhouse.com', 'www.penguinrandomhouse.com', 1927),
('HarperCollins', '195 Broadway, New York, NY 10007', '+1-212-207-7000', 'info@harpercollins.com', 'www.harpercollins.com', 1989),
('Simon & Schuster', '1230 Avenue of the Americas, New York, NY 10020', '+1-212-698-7000', 'info@simonandschuster.com', 'www.simonandschuster.com', 1924),
('Macmillan', '120 Broadway, New York, NY 10271', '+1-646-307-5151', 'info@macmillan.com', 'www.macmillan.com', 1943),
('Oxford University Press', 'Great Clarendon Street, Oxford OX2 6DP, UK', '+44-1865-556767', 'enquiry@oup.com', 'www.oup.com', 1986);

-- 3. Insert Authors (no dependencies)
INSERT INTO authors (first_name, last_name, birth_date, nationality, email, biography) VALUES
('George', 'Orwell', '1903-06-25', 'British', 'george.orwell@classic.lit', 'English novelist, essayist, journalist and critic famous for Animal Farm and 1984'),
('Jane', 'Austen', '1775-12-16', 'British', 'jane.austen@classic.lit', 'English novelist known for her wit, social commentary and timeless romance novels'),
('Agatha', 'Christie', '1890-09-15', 'British', 'agatha.christie@mystery.lit', 'English writer known for her detective novels featuring Hercule Poirot and Miss Marple'),
('J.K.', 'Rowling', '1965-07-31', 'British', 'jk.rowling@modern.lit', 'British author best known for the Harry Potter series'),
('Stephen', 'King', '1947-09-21', 'American', 'stephen.king@horror.lit', 'American author known for his horror, supernatural fiction, suspense, and fantasy novels');

-- 4. Insert Member Types (no dependencies)
INSERT INTO member_types (type_name, max_books_allowed, loan_period_days, fine_per_day, membership_fee, description) VALUES
('Standard', 3, 14, 0.50, 25.00, 'Regular adult membership'),
('Premium', 5, 21, 0.25, 50.00, 'Premium membership with extended privileges'),
('Student', 4, 14, 0.25, 10.00, 'Discounted membership for students'),
('Senior', 3, 21, 0.25, 15.00, 'Special rates for senior citizens'),
('Child', 2, 14, 0.00, 0.00, 'Free membership for children under 12');

-- 5. Insert Books (depends on categories and publishers)
INSERT INTO books (isbn, title, publication_date, pages, category_id, publisher_id, total_copies, available_copies, summary) VALUES
('978-0-452-28423-4', '1984', '1949-06-08', 328, 1, 1, 5, 5, 'A dystopian social science fiction novel about totalitarian control'),
('978-0-14-143951-8', 'Pride and Prejudice', '1813-01-28', 432, 5, 1, 3, 3, 'A romantic novel about manners, marriage, and money in Georgian England'),
('978-0-06-207348-4', 'Murder on the Orient Express', '1934-01-01', 256, 4, 2, 4, 4, 'A detective novel featuring Hercule Poirot solving a murder on a train'),
('978-0-7475-3269-9', 'Harry Potter and the Philosophers Stone', '1997-06-26', 223, 3, 3, 8, 8, 'The first novel in the Harry Potter series about a young wizard'),
('978-0-385-12167-9', 'The Shining', '1977-01-28', 447, 4, 4, 2, 2, 'A horror novel about a family isolated in a haunted hotel');

-- 6. Link Books with Authors (depends on books and authors)
INSERT INTO book_authors (book_id, author_id, author_role) VALUES
(1, 1, 'Primary Author'),  -- 1984 by George Orwell
(2, 2, 'Primary Author'),  -- Pride and Prejudice by Jane Austen
(3, 3, 'Primary Author'),  -- Murder on the Orient Express by Agatha Christie
(4, 4, 'Primary Author'),  -- Harry Potter by J.K. Rowling
(5, 5, 'Primary Author');  -- The Shining by Stephen King

-- 7. Insert Members (depends on member_types)
INSERT INTO members (member_number, first_name, last_name, email, phone, address, date_of_birth, type_id) VALUES
('M001', 'John', 'Doe', 'john.doe@email.com', '+1-555-1001', '123 Main St, Anytown, ST 12345', '1985-03-15', 1),
('M002', 'Jane', 'Smith', 'jane.smith@email.com', '+1-555-1002', '456 Oak Ave, Somewhere, ST 67890', '1992-07-22', 2),
('M003', 'Bob', 'Wilson', 'bob.wilson@email.com', '+1-555-1003', '789 Pine Rd, Elsewhere, ST 54321', '1978-11-08', 1),
('M004', 'Alice', 'Brown', 'alice.brown@email.com', '+1-555-1004', '321 Elm St, Nowhere, ST 98765', '2005-12-03', 5);

-- 8. Insert Staff (no dependencies)
INSERT INTO staff (employee_id, first_name, last_name, email, phone, position, hire_date, salary) VALUES
('LIB001', 'Sarah', 'Johnson', 'sarah.johnson@library.org', '+1-555-0101', 'Head Librarian', '2020-01-15', 55000.00),
('LIB002', 'Michael', 'Chen', 'michael.chen@library.org', '+1-555-0102', 'Assistant Librarian', '2021-03-22', 40000.00),
('LIB003', 'Emily', 'Davis', 'emily.davis@library.org', '+1-555-0103', 'Circulation Clerk', '2022-06-10', 32000.00);

-- 9. Insert Transactions (depends on members, books, and staff)
INSERT INTO transactions (member_id, book_id, staff_id, transaction_type, transaction_date, due_date) VALUES
(1, 1, 1, 'Borrow', '2024-01-15', '2024-01-29'),  -- John Doe borrows 1984
(2, 2, 2, 'Borrow', '2024-01-16', '2024-02-06'),  -- Jane Smith borrows Pride and Prejudice  
(3, 3, 1, 'Borrow', '2024-01-17', '2024-01-31'),  -- Bob Wilson borrows Murder on the Orient Express
(4, 4, 3, 'Borrow', '2024-01-18', '2024-02-01');  -- Alice Brown borrows Harry Potter

-- 10. Insert Reservations (depends on members and books)
INSERT INTO reservations (member_id, book_id, reservation_date, expiry_date, status, priority_number) VALUES
(1, 5, '2024-01-20', '2024-01-30', 'Active', 1),       -- John Doe reserved "The Shining"
(2, 1, '2024-01-21', '2024-01-31', 'Active', 2),       -- Jane Smith reserved "1984" (when John returns it)
(3, 4, '2024-01-22', '2024-02-01', 'Cancelled', 3),    -- Bob Wilson reserved HP, then cancelled
(4, 2, '2024-01-23', '2024-02-02', 'Fulfilled', 4);    -- Alice Brown reserved Pride & Prejudice

-- =====================================================
-- USEFUL VIEWS for common queries
-- =====================================================

-- View: Currently borrowed books with member details
CREATE VIEW currently_borrowed_books AS
SELECT 
    t.transaction_id,
    m.member_number,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    b.title,
    b.isbn,
    t.transaction_date,
    t.due_date,
    CASE 
        WHEN t.due_date < CURRENT_DATE THEN DATEDIFF(CURRENT_DATE, t.due_date)
        ELSE 0 
    END AS days_overdue
FROM transactions t
JOIN members m ON t.member_id = m.member_id
JOIN books b ON t.book_id = b.book_id
WHERE t.transaction_type = 'Borrow' 
AND t.return_date IS NULL;

-- View: Book catalog with author information
CREATE VIEW book_catalog AS
SELECT 
    b.book_id,
    b.isbn,
    b.title,
    GROUP_CONCAT(CONCAT(a.first_name, ' ', a.last_name) SEPARATOR ', ') AS authors,
    c.category_name,
    p.publisher_name,
    b.publication_date,
    b.pages,
    b.total_copies,
    b.available_copies
FROM books b
LEFT JOIN book_authors ba ON b.book_id = ba.book_id
LEFT JOIN authors a ON ba.author_id = a.author_id
LEFT JOIN categories c ON b.category_id = c.category_id
LEFT JOIN publishers p ON b.publisher_id = p.publisher_id
GROUP BY b.book_id;

-- View: Fine Due calculator
CREATE VIEW fines_due AS
SELECT 
    t.transaction_id,
    m.member_number,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    b.title,
    t.due_date,
    CASE 
        WHEN t.due_date < CURRENT_DATE AND t.return_date IS NULL 
        THEN DATEDIFF(CURRENT_DATE, t.due_date) * mt.fine_per_day
        ELSE 0 
    END AS fine_due
FROM transactions t
JOIN members m ON t.member_id = m.member_id
JOIN books b ON t.book_id = b.book_id
JOIN member_types mt ON m.type_id = mt.type_id
WHERE t.transaction_type = 'Borrow' AND t.return_date IS NULL;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
-- Run these to verify everything worked correctly

-- Check table counts
SELECT 'Categories' as table_name, COUNT(*) as record_count FROM categories
UNION ALL
SELECT 'Publishers', COUNT(*) FROM publishers
UNION ALL
SELECT 'Authors', COUNT(*) FROM authors
UNION ALL
SELECT 'Books', COUNT(*) FROM books
UNION ALL
SELECT 'Members', COUNT(*) FROM members
UNION ALL
SELECT 'Staff', COUNT(*) FROM staff
UNION ALL
SELECT 'Transactions', COUNT(*) FROM transactions
UNION ALL
SELECT 'Reservations', COUNT(*) FROM reservations;

-- Check all views work
-- SELECT * FROM book_catalog;
-- SELECT * FROM currently_borrowed_books;
-- SELECT * FROM fines_due;

-- =====================================================
-- End of Library Management System Schema
-- =====================================================
