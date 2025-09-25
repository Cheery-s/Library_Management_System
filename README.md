# Library Management System Database

A comprehensive relational database design for managing library operations including books, members, authors, staff, and transactions. Built with MySQL, this system demonstrates advanced database concepts including normalization, constraints, triggers, views, and complex relationships.

## Table of Contents

- [Project Overview](#project-overview)
- [Database Schema](#database-schema)
- [Features](#features)
- [Installation & Setup](#installation--setup)
- [Database Structure](#database-structure)
- [Relationships](#relationships)
- [Constraints & Validation](#constraints--validation)
- [Sample Data](#sample-data)
- [Views & Queries](#views--queries)
- [Troubleshooting](#troubleshooting)
- [Usage Examples](#usage-examples)
- [Future Enhancements](#future-enhancements)
- [Contributing](#contributing)

## Project Overview

This database system handles all aspects of library management:

**Core Functionality:**
- Book catalog management with multiple copies tracking
- Member registration and management with different membership tiers
- Staff management and transaction processing
- Borrowing, returning, and renewal operations
- Book reservation system with priority queuing
- Automatic fine calculation for overdue books
- Inventory tracking with real-time availability updates

**Technical Features:**
- Fully normalized database design (3NF)
- Comprehensive constraint implementation
- Automated business logic through triggers
- Optimized queries with strategic indexing
- Pre-built views for common operations

## Database Schema

### Entity Relationship Overview

```
Categories ──→ Books ←── Publishers
                │
Authors ←──────┴── Book_Authors (Many-to-Many)
                
Member_Types ──→ Members
                   │
                   ├── Transactions ←── Books
                   │        │
                   │        └── Staff
                   │
                   └── Reservations ←── Books
```

### Core Tables

| Table | Purpose | Key Features |
|-------|---------|--------------|
| `books` | Book catalog and inventory | ISBN validation, copy tracking |
| `authors` | Author information | Biographical data, unique emails |
| `members` | Library member records | Membership tiers, status tracking |
| `staff` | Employee management | Role-based access, salary tracking |
| `transactions` | Borrowing/returning records | Complete audit trail, fine calculation |
| `categories` | Book classification | Genre-based organization |
| `publishers` | Publishing house data | Contact and historical information |
| `reservations` | Book reservation queue | Priority-based system |

## Features

### Advanced Database Features

**Constraint Implementation:**
- Primary keys with auto-increment on all tables
- Foreign keys with appropriate CASCADE/SET NULL actions
- Unique constraints on critical fields (ISBN, email, member numbers)
- Check constraints for data validation
- NOT NULL enforcement on required fields

**Automated Business Logic:**
- Triggers for automatic inventory updates
- Real-time available copy tracking
- Reservation expiry management
- Fine calculation automation

**Performance Optimization:**
- Strategic indexes on frequently queried columns
- Composite indexes for multi-column searches
- Optimized views for complex queries

### Business Logic Features

**Membership Management:**
- Five membership tiers with different privileges
- Configurable borrowing limits and loan periods
- Automatic fine calculation based on membership type
- Status tracking (Active, Suspended, Expired, Cancelled)

**Inventory Control:**
- Multi-copy book management
- Real-time availability tracking
- Automatic updates on borrow/return operations
- Reservation queue with priority system

**Transaction Tracking:**
- Complete audit trail for all book movements
- Support for Borrow, Return, and Renew operations
- Fine calculation and tracking
- Staff accountability for all transactions

## Installation & Setup

### Prerequisites

- MySQL 8.0 or higher (recommended)
- MySQL Workbench (optional, for GUI management)
- Command line access to MySQL

### Quick Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Cheery-s/Library_Management_System.git
   cd library-management-system
   ```

2. **Create the database:**
   ```bash
   mysql -u root -p < library_schema.sql
   ```

3. **Verify installation:**
   ```sql
   USE library_management_system;
   SHOW TABLES;
   ```

### Step-by-Step Setup

1. **Start MySQL service:**
   ```bash
   # On Windows
   net start mysql
   
   # On macOS/Linux
   sudo service mysql start
   ```

2. **Connect to MySQL:**
   ```bash
   mysql -u root -p
   ```

3. **Run the schema:**
   ```sql
   source /path/to/library_schema.sql
   ```

4. **Verify table creation:**
   ```sql
   SELECT table_name, table_rows 
   FROM information_schema.tables 
   WHERE table_schema = 'library_management_system';
   ```

## Database Structure

### Table Specifications

#### Books Table
```sql
CREATE TABLE books (
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    isbn VARCHAR(20) NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    publication_date DATE,
    pages INT CHECK (pages > 0),
    total_copies INT NOT NULL DEFAULT 1 CHECK (total_copies > 0),
    available_copies INT NOT NULL DEFAULT 1 CHECK (available_copies >= 0),
    category_id INT,
    publisher_id INT,
    FOREIGN KEY (category_id) REFERENCES categories(category_id),
    FOREIGN KEY (publisher_id) REFERENCES publishers(publisher_id)
);
```

#### Members Table
```sql
CREATE TABLE members (
    member_id INT PRIMARY KEY AUTO_INCREMENT,
    member_number VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    type_id INT NOT NULL,
    status ENUM('Active', 'Suspended', 'Expired', 'Cancelled') DEFAULT 'Active',
    FOREIGN KEY (type_id) REFERENCES member_types(type_id)
);
```

#### Transactions Table
```sql
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
    FOREIGN KEY (member_id) REFERENCES members(member_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);
```

## Relationships

### One-to-Many Relationships

**Categories → Books**
- One category can contain many books
- Books can exist without a category (NULL allowed)
- Deleting a category sets book category_id to NULL

**Members → Transactions**
- One member can have many transactions
- Each transaction belongs to exactly one member
- Complete transaction history maintained

**Member Types → Members**
- One membership type applies to many members
- Defines borrowing limits and privileges
- Cannot delete member type while members exist

### Many-to-Many Relationships

**Books ↔ Authors (via book_authors)**
- One book can have multiple authors
- One author can write multiple books
- Junction table stores author roles (Primary Author, Co-Author, Editor, Translator)

### Complex Relationships

**Transaction Management:**
```sql
-- A transaction connects three entities:
member_id → members table (who borrowed)
book_id → books table (what was borrowed)
staff_id → staff table (who processed the transaction)
```

## Constraints & Validation

### Data Integrity Rules

**Books Table:**
- ISBN must be unique and not null
- Available copies cannot exceed total copies
- Page count must be positive
- Both copy counts must be positive numbers

**Members Table:**
- Email addresses must be unique
- Member numbers must be unique
- Membership end date must be after start date (if specified)

**Transactions Table:**
- Return date cannot be before transaction date
- Due date must be after or equal to transaction date
- All foreign key references must exist

### Automatic Validation

**Triggers:**
```sql
-- Automatically decrease available copies when book is borrowed
CREATE TRIGGER borrow_book
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
  IF NEW.transaction_type = 'Borrow' THEN
    UPDATE books 
    SET available_copies = available_copies - 1
    WHERE book_id = NEW.book_id AND available_copies > 0;
  END IF;
END
```

## Sample Data

The database comes pre-populated with realistic test data:

**10 Categories:** Fiction, Non-Fiction, Science Fiction, Mystery & Thriller, Romance, Children, Academic, Biography, History, Technology

**5 Publishers:** Penguin Random House, HarperCollins, Simon & Schuster, Macmillan, Oxford University Press

**5 Authors:** George Orwell, Jane Austen, Agatha Christie, J.K. Rowling, Stephen King

**5 Books:** 1984, Pride and Prejudice, Murder on the Orient Express, Harry Potter and the Philosopher's Stone, The Shining

**5 Member Types:** Standard, Premium, Student, Senior, Child

**4 Sample Members and Staff:** With realistic contact information and membership details

**Active Transactions:** Sample borrowing records with due dates

## Views & Queries

### Pre-built Views

#### Currently Borrowed Books
```sql
CREATE VIEW currently_borrowed_books AS
SELECT 
    t.transaction_id,
    m.member_number,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    b.title,
    t.due_date,
    DATEDIFF(CURRENT_DATE, t.due_date) AS days_overdue
FROM transactions t
JOIN members m ON t.member_id = m.member_id
JOIN books b ON t.book_id = b.book_id
WHERE t.transaction_type = 'Borrow' AND t.return_date IS NULL;
```

#### Book Catalog with Authors
```sql
CREATE VIEW book_catalog AS
SELECT 
    b.book_id,
    b.title,
    GROUP_CONCAT(CONCAT(a.first_name, ' ', a.last_name) SEPARATOR ', ') AS authors,
    c.category_name,
    b.available_copies,
    b.total_copies
FROM books b
LEFT JOIN book_authors ba ON b.book_id = ba.book_id
LEFT JOIN authors a ON ba.author_id = a.author_id
LEFT JOIN categories c ON b.category_id = c.category_id
GROUP BY b.book_id;
```

#### Fine Calculator
```sql
CREATE VIEW fines_due AS
SELECT 
    m.member_number,
    b.title,
    CASE 
        WHEN t.due_date < CURRENT_DATE AND t.return_date IS NULL 
        THEN DATEDIFF(CURRENT_DATE, t.due_date) * mt.fine_per_day
        ELSE 0 
    END AS fine_due
FROM transactions t
JOIN members m ON t.member_id = m.member_id
JOIN books b ON t.book_id = b.book_id
JOIN member_types mt ON m.type_id = mt.type_id;
```

### Useful Queries

**Find available books by category:**
```sql
SELECT b.title, b.available_copies 
FROM books b 
JOIN categories c ON b.category_id = c.category_id 
WHERE c.category_name = 'Fiction' AND b.available_copies > 0;
```

**Member borrowing history:**
```sql
SELECT m.member_number, b.title, t.transaction_date, t.return_date
FROM transactions t
JOIN members m ON t.member_id = m.member_id
JOIN books b ON t.book_id = b.book_id
WHERE m.member_number = 'M001'
ORDER BY t.transaction_date DESC;
```

**Books by author:**
```sql
SELECT b.title, b.publication_date
FROM books b
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
WHERE CONCAT(a.first_name, ' ', a.last_name) = 'George Orwell';
```

## Troubleshooting

### Common Issues and Solutions

#### Error Code 1062: Duplicate Entry
**Problem:** Trying to insert duplicate values in unique fields
```
Error Code: 1062. Duplicate entry 'Fiction' for key 'categories.category_name'
```

**Solution:** 
- Use `DROP DATABASE IF EXISTS` for clean starts
- Check for existing data before inserting
- Use `INSERT IGNORE` to skip duplicates

#### Error Code 1452: Foreign Key Constraint Failure
**Problem:** Referencing non-existent parent records
```
Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails
```

**Solution:**
- Ensure parent records exist before inserting child records
- Follow correct insertion order: Categories → Publishers → Authors → Books → Members → Transactions
- Verify foreign key values with SELECT queries

#### Error Code 3814: CHECK Constraint Function Restrictions
**Problem:** Using restricted functions in CHECK constraints
```
Error Code: 3814. An expression of a check constraint contains disallowed function: curdate
```

**Solution:**
- Remove problematic CHECK constraints
- Use triggers for complex validation
- Handle date validation at application level

### Debugging Queries

**Check table relationships:**
```sql
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'library_management_system'
AND REFERENCED_TABLE_NAME IS NOT NULL;
```

**Verify data counts:**
```sql
SELECT 'Books' as table_name, COUNT(*) as records FROM books
UNION ALL SELECT 'Members', COUNT(*) FROM members
UNION ALL SELECT 'Transactions', COUNT(*) FROM transactions;
```

## Usage Examples

### Basic Operations

**Add a new book:**
```sql
INSERT INTO books (isbn, title, publication_date, pages, category_id, publisher_id, total_copies, available_copies)
VALUES ('978-0-123-45678-9', 'New Book Title', '2024-01-01', 300, 1, 1, 3, 3);
```

**Register a new member:**
```sql
INSERT INTO members (member_number, first_name, last_name, email, date_of_birth, type_id)
VALUES ('M005', 'New', 'Member', 'new.member@email.com', '1990-01-01', 1);
```

**Process a book loan:**
```sql
INSERT INTO transactions (member_id, book_id, staff_id, transaction_type, due_date)
VALUES (1, 1, 1, 'Borrow', DATE_ADD(CURRENT_DATE, INTERVAL 14 DAY));
```

### Advanced Queries

**Most popular books:**
```sql
SELECT b.title, COUNT(t.transaction_id) as borrow_count
FROM books b
LEFT JOIN transactions t ON b.book_id = t.book_id
WHERE t.transaction_type = 'Borrow'
GROUP BY b.book_id
ORDER BY borrow_count DESC
LIMIT 10;
```

**Members with overdue books:**
```sql
SELECT DISTINCT m.member_number, m.first_name, m.last_name, m.email
FROM members m
JOIN transactions t ON m.member_id = t.member_id
WHERE t.due_date < CURRENT_DATE 
AND t.return_date IS NULL 
AND t.transaction_type = 'Borrow';
```

## Future Enhancements

### Planned Features

**Digital Resources:**
- E-book and audiobook support
- Digital media lending
- Online access tracking

**Enhanced Member Services:**
- Reading history and recommendations
- Book review and rating system
- Email notifications for due dates and reservations

**Advanced Reporting:**
- Usage statistics and analytics
- Popular books and authors tracking
- Member activity reports
- Financial reporting (fines, fees)

**Integration Capabilities:**
- REST API development
- Mobile application support
- Third-party library system integration
- RFID/barcode scanning support

### Technical Improvements

**Performance:**
- Query optimization
- Partitioning for large datasets
- Caching strategies
- Archive old transactions

**Security:**
- User authentication system
- Role-based access control
- Data encryption
- Audit logging

## Contributing

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make changes and test thoroughly
4. Submit a pull request with detailed description

### Coding Standards

- Use consistent naming conventions
- Add comments for complex queries
- Include test data for new features
- Update documentation for schema changes

### Testing Guidelines

- Test all constraints and relationships
- Verify foreign key integrity
- Test edge cases and error conditions
- Performance test with large datasets

## Database Statistics

**Current Schema Stats:**
- 9 tables with proper relationships
- 15+ constraints ensuring data integrity
- 7 indexes for optimized performance
- 3 automated triggers for business logic
- 3 pre-built views for common queries
- 50+ sample records for testing

**Supported Operations:**
- Complete CRUD operations on all entities
- Complex queries across multiple tables
- Automated inventory management
- Real-time availability tracking
- Fine calculation and member management


## Support

For questions, issues, or contributions:
- Create an issue in the GitHub repository
- Email: [jinaduserifat@gmail.com]
- Documentation: Check this README and inline SQL comments

---

**Note:** This database design follows industry best practices for relational database systems and is suitable for both educational purposes and real-world library management applications. The system demonstrates advanced database concepts while maintaining simplicity and reliability.# Library_Management_System
