# Employee Management System

## Overview
The Employee Management System is a comprehensive database application developed using Oracle PL/SQL to streamline human resource operations.
It enables efficient management of employee records, including personal details, salaries, department assignments, and audit logs for tracking changes and deletions.
The system ensures data integrity, enforces business rules, and provides a reliable solution for HR departments to handle employee-related tasks securely.

This project showcases advanced database design, PL/SQL programming, and robust error handling — serving as a practical example for developers interested in Oracle database development or HR management systems.

## Contents
- [Database Structure](#database-structure)
- [PL/SQL Components](#plsql-components)
- [Functionality](#functionality)
- [Key Achievements](#key-achievements)
- [Setup Instructions](#setup-instructions)
- [Testing](#testing)
- [Challenges and Solutions](#challenges-and-solutions)
- [Future Improvements](#future-improvements)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## Database Structure
The system is built on a relational database with six core tables:

### Employees Table
- Stores personal and professional details of employees, such as ID, name, email, phone number, hire date, job role, salary, and department.

### Departments Table
- Contains information about organizational departments, including department ID and name.

### Jobs Table
- Defines job roles, including job ID, title, and acceptable salary ranges (minimum and maximum).

### Salary History Table
- Logs changes to employee salaries, tracking old and new salary values, change date, and the user who made the change.

### Transfer History Table
- Records employee transfers between departments, capturing the old and new department, transfer date, and responsible user.

### Deletion Logs Table
- Maintains a record of deleted employee data, including employee ID, department, salary, deletion date, and the user who performed the deletion.

## PL/SQL Components

### Packages
- A primary package manages core operations like adding, updating, retrieving, and deleting employee records.
- An audit package handles logging of changes and deletions for compliance and tracking purposes.

### Triggers
- A salary validation trigger ensures salaries fall within the acceptable range for each job role.
- A deletion trigger automatically logs deleted employee details into the audit table.

## Functionality

### Employee Management
- Add Employees: Create new employee records with full details.
- Update Employees: Modify existing employee information, such as salary or department assignments.
- Delete Employees: Remove employee records, with automatic logging for auditing.
- Retrieve Employee Data: Query employee details, even handling cases of non-existent IDs with error feedback.

### Salary Management
- Validates salaries against predefined job-specific ranges.
- Tracks all salary changes in a history table.

### Department Transfers
- Manages employee transfers between departments.
- Logs old and new departments, transfer dates, and responsible users.

### Audit and Compliance
- Logs all deletions with details like salary, department, and deletion timestamp.
- Maintains a comprehensive audit trail for salary changes and department transfers.

### Error Handling
- Handles errors such as duplicate emails, invalid job roles, and salary violations.
- Provides meaningful, user-friendly error messages.

### Performance
- Supports bulk operations, such as adding multiple employees at once.
- Maintains fast query performance and ensures data integrity with constraints and triggers.

## Key Achievements
- Successfully implemented a fully functional HR system with six interconnected tables and robust PL/SQL logic.
- Resolved complex database issues like the mutating table error during deletion logging.
- Validated system reliability through 13 test cases covering scenarios like bulk inserts, salary updates, and error handling.
- Achieved high performance, with operations like employee addition and salary validation completing in milliseconds.

## Setup Instructions

### Prerequisites
- Oracle Database (11g or later).
- Oracle SQL Developer or another SQL client (e.g., SQL\*Plus).
- Schema with permissions to create tables, triggers, and packages.

### Installation
1. Clone the repository from GitHub.
2. Execute the SQL scripts provided to create tables, triggers, and packages.
3. Insert sample data to test the system.

### Configuration
- Ensure the schema user has necessary privileges (e.g., CREATE TABLE, CREATE TRIGGER, CREATE PACKAGE).
- Enable DBMS Output in your SQL client to view test outputs.

## Testing
The system was rigorously tested with 13 different test cases, including:
- Adding new employees with valid and invalid data.
- Updating salaries and verifying history logging.
- Transferring employees between departments.
- Deleting employees and checking audit logs.
- Retrieving details for non-existent employees.
- Performing bulk inserts (e.g., 100 employees) to test system performance.
- Handling edge cases like duplicate records, invalid job roles, and salary violations.

> ✅ All test cases passed successfully, confirming the system’s stability and accuracy.

## Challenges and Solutions

### Mutating Table Issue
- Challenge: Occurred during deletion logging due to a foreign key constraint.
- Solution: Removed the constraint, allowing seamless audit logging.

### Salary Validation
- Ensured salaries comply with job-specific ranges, preventing invalid updates.

### Bulk Operations
- Addressed performance issues by optimizing constraints and reference validations.

## Future Improvements
- Add user authentication to secure sensitive operations.
- Implement reporting features, such as department-wise salary summaries.
- Enhance performance by creating indexes on frequently queried fields.
- Extend auditing to include additional operations, like login attempts.

## Contributing
Contributions are welcome!
To contribute:
1. Fork the repository.
2. Create a feature branch.
3. Submit a pull request with your changes.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact
For questions or feedback:
- Email: [your-email@example.com]
- LinkedIn: [your-linkedin-profile]

Thank you for exploring the Employee Management System! 🚀
