-- Table: employee
-- Purpose: Stores core employee information, aligned with HR schema's EMPLOYEES table, with constraints to ensure data integrity.
CREATE TABLE employee (
    employee_id    NUMBER PRIMARY KEY,
    first_name     VARCHAR2(50) NOT NULL,
    last_name      VARCHAR2(50) NOT NULL,
    email          VARCHAR2(100) UNIQUE NOT NULL,
    phone_number   VARCHAR2(20) UNIQUE NOT NULL,
    hire_date      DATE NOT NULL,
    job_id         VARCHAR2(10) NOT NULL,
    salary         NUMBER(10, 2) CHECK ( salary >= 0 ),
    commission_pct NUMBER(3, 2) CHECK ( commission_pct BETWEEN 0 AND 1 ),
    manager_id     NUMBER(6),
    department_id  NUMBER(4),
    CONSTRAINT fk_job_id FOREIGN KEY ( job_id )
        REFERENCES jobs ( job_id )
            ON DELETE CASCADE,
    CONSTRAINT fk_manager_id FOREIGN KEY ( manager_id )
        REFERENCES employee ( employee_id )
            ON DELETE CASCADE,
    CONSTRAINT fk_department_id FOREIGN KEY ( department_id )
        REFERENCES departments ( department_id )
            ON DELETE CASCADE
);

-- Table: salary_history
-- Purpose: Tracks salary changes for employees, including old and new salary values, with audit fields for tracking updates.
CREATE TABLE salary_history (
    employee_id NUMBER,
    old_salary  NUMBER DEFAULT NULL,
    new_salary  NUMBER NOT NULL,
    update_by   VARCHAR2(30) DEFAULT user,
    update_date DATE DEFAULT sysdate,
    CONSTRAINT emp_id_fk FOREIGN KEY ( employee_id )
        REFERENCES employee ( employee_id )
            ON DELETE CASCADE
);

-- Table: deletion_logs
-- Purpose: Logs details of deleted employees for auditing purposes, including department and salary at the time of deletion.
CREATE TABLE deletion_logs (
    employee_id   NUMBER,
    department_id NUMBER,
    salary        NUMBER,
    deleted_by    VARCHAR2(30) DEFAULT user,
    deleted_date  DATE DEFAULT sysdate,
    CONSTRAINT emp_id_fk_dlogs FOREIGN KEY ( employee_id )
        REFERENCES employee ( employee_id )
            ON DELETE CASCADE,
    CONSTRAINT dept_id_fk_dlogs FOREIGN KEY ( department_id )
        REFERENCES departments ( department_id )
            ON DELETE CASCADE
);

ALTER TABLE deletion_logs
DROP CONSTRAINT emp_id_fk_dlogs;

-- Table: transfer_history
-- Purpose: Records employee transfers between departments and managers, with audit fields for tracking transfer details.
CREATE TABLE transfer_history (
    transfer_id    NUMBER PRIMARY KEY,
    employee_id    NUMBER NOT NULL,
    old_department NUMBER,
    new_department NUMBER,
    old_manager    NUMBER,
    new_manager    NUMBER,
    transferred_by VARCHAR2(30) DEFAULT user,
    transfer_date  DATE DEFAULT sysdate,
    CONSTRAINT fk_emp_transfer FOREIGN KEY ( employee_id )
        REFERENCES employee ( employee_id )
            ON DELETE CASCADE,
    CONSTRAINT fk_old_dept_transfer FOREIGN KEY ( old_department )
        REFERENCES departments ( department_id )
            ON DELETE CASCADE,
    CONSTRAINT fk_new_dept_transfer FOREIGN KEY ( new_department )
        REFERENCES departments ( department_id )
            ON DELETE CASCADE,
    CONSTRAINT fk_old_mgr_transfer FOREIGN KEY ( old_manager )
        REFERENCES employee ( employee_id )
            ON DELETE CASCADE,
    CONSTRAINT fk_new_mgr_transfer FOREIGN KEY ( new_manager )
        REFERENCES employee ( employee_id )
            ON DELETE CASCADE
);

-- Sequences
-- Purpose: Generate unique identifiers for  transfer_id.
CREATE SEQUENCE trans_id_seq START WITH 1 INCREMENT BY 1;

-- Indexes
-- Purpose: Improve query performance for job_id and department_id lookups in employee table.
CREATE INDEX idx_employee_job_id ON employee(job_id);
CREATE INDEX dept_idx ON employee(department_id);
/

-- Trigger: delete_employee_trig
-- Purpose: Automatically logs employee deletion details to deletion_logs table after a delete operation.
CREATE OR REPLACE TRIGGER delete_employee_trig BEFORE
    DELETE ON employee
    FOR EACH ROW
BEGIN
    employee_audit_pkg.log_employee_deletion(
                      p_emp_id => :old.employee_id,
                      p_dept_id => :old.department_id,
                      p_salary => :old.salary);
END delete_employee_trig;
/


-- Trigger: change_salary_trig
-- Purpose: Validates salary against job's salary range and logs salary changes to salary_history before insert or update.
CREATE OR REPLACE TRIGGER change_salary_trig
AFTER INSERT OR UPDATE OF salary ON employee
FOR EACH ROW
DECLARE
    v_min_salary jobs.min_salary%TYPE;
    v_max_salary jobs.max_salary%TYPE;
BEGIN
    -- Validate salary against job's salary range
    SELECT min_salary, max_salary
    INTO v_min_salary, v_max_salary
    FROM jobs
    WHERE job_id = :new.job_id;
    
    IF :new.salary < v_min_salary OR :new.salary > v_max_salary THEN
        RAISE_APPLICATION_ERROR(-20001, 'Salary must be between ' || v_min_salary || ' and ' || v_max_salary || ' for job ' || :new.job_id);
    END IF;

    -- Log salary changes
    IF INSERTING THEN
        employee_audit_pkg.log_salary_change(
            p_employee_id => :new.employee_id,
            p_old_salary => NULL,
            p_new_salary => :new.salary
        );
    ELSIF UPDATING AND :old.salary <> :new.salary THEN
        employee_audit_pkg.log_salary_change(
            p_employee_id => :new.employee_id,
            p_old_salary => :old.salary,
            p_new_salary => :new.salary
        );
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Invalid job_id: ' || :new.job_id);
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Error in salary validation: ' || SQLERRM);
END change_salary_trig;
/

-- Package: employee_audit_pkg
-- Purpose: Provides procedures for auditing employee-related operations (salary changes, deletions, transfers).
CREATE OR REPLACE PACKAGE employee_audit_pkg AS
    PROCEDURE log_salary_change (
        p_employee_id employee.employee_id%TYPE,
        p_old_salary  employee.salary%TYPE,
        p_new_salary  employee.salary%TYPE
    );

    PROCEDURE log_employee_deletion (
        p_emp_id  employee.employee_id%TYPE,
        p_dept_id departments.department_id%TYPE,
        p_salary  employee.salary%TYPE
    );

    PROCEDURE log_transfer (
        p_emp_id   employee.employee_id%TYPE,
        p_old_dept employee.department_id%TYPE,
        p_new_dept employee.department_id%TYPE,
        p_old_mgr  employee.manager_id%TYPE,
        p_new_mgr  employee.manager_id%TYPE
    );

END employee_audit_pkg;

-- Package Body: employee_audit_pkg
-- Purpose: Implements audit procedures for logging salary changes, deletions, and transfers to respective tables.
CREATE OR REPLACE PACKAGE BODY employee_audit_pkg AS

    PROCEDURE log_salary_change (
        p_employee_id employee.employee_id%TYPE,
        p_old_salary  employee.salary%TYPE,
        p_new_salary  employee.salary%TYPE
    ) AS
    BEGIN
        INSERT INTO salary_history (
            employee_id,
            old_salary,
            new_salary
        ) VALUES (
            p_employee_id,
            p_old_salary,
            p_new_salary
        );
     Exception 
     WHEN OTHERS THEN
            dbms_output.put_line('Failed to log salary change: ' || SQLERRM);

    END log_salary_change;

    PROCEDURE log_employee_deletion (
        p_emp_id  employee.employee_id%TYPE,
        p_dept_id departments.department_id%TYPE,
        p_salary  employee.salary%TYPE
    ) AS
    BEGIN
        INSERT INTO deletion_logs (
            employee_id,
            department_id,
            salary
        ) VALUES (
            p_emp_id,
            p_dept_id,
            p_salary
        );
        
     Exception 
     WHEN OTHERS THEN
            dbms_output.put_line('Failed to log deletion: ' || SQLERRM);

    END log_employee_deletion;

    PROCEDURE log_transfer (
        p_emp_id   employee.employee_id%TYPE,
        p_old_dept employee.department_id%TYPE,
        p_new_dept employee.department_id%TYPE,
        p_old_mgr  employee.manager_id%TYPE,
        p_new_mgr  employee.manager_id%TYPE
    ) AS
    BEGIN
        INSERT INTO transfer_history (
            transfer_id,
            employee_id,
            old_department,
            new_department,
            old_manager,
            new_manager
        ) VALUES (
            trans_id_seq.NEXTVAL,
            p_emp_id,
            p_old_dept,
            p_new_dept,
            p_old_mgr,
            p_new_mgr
        );

        IF SQL%rowcount > 0 THEN
            dbms_output.put_line('Data updated successfully.');
        ELSE
            raise_application_error('The employee isn''t found.', -20004);
        END IF;
        
             Exception 
     WHEN OTHERS THEN
            dbms_output.put_line('Failed to log transfer: ' || SQLERRM);

    END log_transfer;

END employee_audit_pkg;
/

-- Package: employee_management_pkg
-- Purpose: Provides procedures and functions for managing employee data (add, update, delete, transfer, and retrieve full name).
CREATE OR REPLACE PACKAGE employee_management_pkg AS
--procedure that insert new employee values into employee table 
    PROCEDURE add_employee (
        p_first_name     employee.first_name%TYPE,
        p_last_name      employee.last_name%TYPE,
        p_email          employee.email%TYPE,
        p_phone_number   employee.phone_number%TYPE,
        p_hire_date      employee.hire_date%TYPE,
        p_job_id         employee.job_id%TYPE,
        p_salary         employee.salary%TYPE,
        p_commission_pct employee.commission_pct%TYPE,
        p_manager_id     employee.manager_id%TYPE,
        p_department_id  employee.department_id%TYPE
    );

    PROCEDURE transfer_employee (
        p_emp_id      employee.employee_id%TYPE,
        p_old_dept_id employee.department_id%TYPE,
        p_new_dept_id employee.department_id%TYPE,
        p_old_mgr_id  employee.manager_id%TYPE,
        p_new_mgr_id  employee.manager_id%TYPE
    );

    PROCEDURE update_employee (
        p_emp_id      employee.employee_id%TYPE,
        p_column_name VARCHAR2,
        p_new_value   VARCHAR2
    );

    PROCEDURE delete_employee (
        p_emp_id employee.employee_id%TYPE
    );
    
    FUNCTION get_employee_fullname(
        p_emp_id employee.employee_id%TYPE
    ) return varchar2;
    

END employee_management_pkg;

/
-- Package Body: employee_management_pkg
-- Purpose: Implements employee management operations, including validation and dynamic updates.
CREATE OR REPLACE PACKAGE BODY employee_management_pkg AS
    emp_id employee.employee_id%type:=100;
--procedure's body that insert new employee values into employee table 
    PROCEDURE add_employee (
        p_first_name     employee.first_name%TYPE,
        p_last_name      employee.last_name%TYPE,
        p_email          employee.email%TYPE,
        p_phone_number   employee.phone_number%TYPE,
        p_hire_date      employee.hire_date%TYPE,
        p_job_id         employee.job_id%TYPE,
        p_salary         employee.salary%TYPE,
        p_commission_pct employee.commission_pct%TYPE,
        p_manager_id     employee.manager_id%TYPE,
        p_department_id  employee.department_id%TYPE
    ) AS

        foreign_key_exception EXCEPTION;
        PRAGMA exception_init ( foreign_key_exception, -2991 );
    BEGIN
    
            INSERT INTO employee VALUES (
                emp_id,
                p_first_name,
                p_last_name,
                p_email,
                p_phone_number,
                p_hire_date,
                p_job_id,
                p_salary,
                p_commission_pct,
                p_manager_id,
                p_department_id
            );
            
       dbms_output.put_line('Employee inserted successfully with ID: ' || emp_id);
       emp_id:=emp_id+1;


    EXCEPTION
        WHEN dup_val_on_index THEN
            dbms_output.put_line('The employee is already found.');
        WHEN foreign_key_exception THEN
            dbms_output.put_line('INVALID DATA : Check the job id or department id you entered.');
        WHEN OTHERS THEN
            dbms_output.put_line('Unexpected error : ' || sqlerrm);
    END add_employee;

    PROCEDURE transfer_employee (
        p_emp_id      employee.employee_id%TYPE,
        p_old_dept_id employee.department_id%TYPE,
        p_new_dept_id employee.department_id%TYPE,
        p_old_mgr_id  employee.manager_id%TYPE,
        p_new_mgr_id  employee.manager_id%TYPE
    ) AS
        foreign_key_exception EXCEPTION;
        PRAGMA exception_init ( foreign_key_exception, -2991 );
    BEGIN
        UPDATE employee
        SET
            department_id = p_new_dept_id,
            manager_id = p_new_mgr_id
        WHERE
            employee_id = p_emp_id;
            
        IF SQL%rowcount > 0 THEN
                dbms_output.put_line('The employee transfered successfully.');
        ELSE
                raise_application_error(-20004, 'The employee isn''t found.');
        END IF;
        
        employee_audit_pkg.log_transfer(p_emp_id, p_old_dept_id, p_new_dept_id, p_old_mgr_id, p_new_mgr_id);
    EXCEPTION
        WHEN foreign_key_exception THEN
            dbms_output.put_line('You entered a wrong department id or employee id or manager id, please rewrite a valid data');
        WHEN OTHERS THEN
            dbms_output.put_line('Unexpected error : ' || sqlerrm);
    END transfer_employee;

    PROCEDURE update_employee (
        p_emp_id      employee.employee_id%TYPE,
        p_column_name VARCHAR2,
        p_new_value   VARCHAR2
    ) AS
       TYPE allowed_columns_t IS TABLE OF VARCHAR2(30);
        allowed_columns allowed_columns_t := allowed_columns_t(
            'FIRST_NAME', 'LAST_NAME', 'EMAIL', 'PHONE_NUMBER', 'HIRE_DATE',
            'JOB_ID', 'SALARY', 'COMMISSION_PCT', 'MANAGER_ID', 'DEPARTMENT_ID'
        );
        v_column_found BOOLEAN := FALSE;
        invalid_column EXCEPTION;
        invalid_data_type EXCEPTION;
        PRAGMA exception_init ( invalid_column, -904 );
        PRAGMA exception_init ( invalid_data_type, -1722 );
        v_sql VARCHAR(300);

    BEGIN
         -- Check if column is allowed
        FOR i IN 1..allowed_columns.COUNT LOOP
            IF UPPER(p_column_name) = allowed_columns(i) THEN
                v_column_found := TRUE;
                EXIT;
            END IF;
        END LOOP;

        IF NOT v_column_found THEN
            RAISE_APPLICATION_ERROR(-20011, 'Column ' || p_column_name || ' is not allowed for update');
        END IF;
        
            
        IF p_new_value IS NULL OR p_new_value = '' OR p_new_value = ' ' THEN
            raise_application_error(-20003, 'Cannot update column '
                                            || p_column_name
                                            || ' to NULL.');       
        end if ;
         
            v_sql := 'update employee set '
                     || dbms_assert.simple_sql_name(p_column_name)
                     || ' =:1 where employee_id=:2';
            EXECUTE IMMEDIATE v_sql
                USING p_new_value, p_emp_id;
            IF SQL%rowcount > 0 THEN
                dbms_output.put_line('Data updated successfully.');
            ELSE
                raise_application_error(-20004, 'The employee isn''t found.');
            END IF;
      
    EXCEPTION
        WHEN invalid_column THEN
            dbms_output.put_line('Invalid column: '
                                 || p_column_name
                                 || ' not found.');
        WHEN invalid_data_type THEN
            dbms_output.put_line('The value you entered ('
                                 || p_new_value
                                 || ') has''t the same datatype of the column('
                                 || p_column_name
                                 || ')');
        WHEN OTHERS THEN
            dbms_output.put_line('Unexpected error ' || sqlerrm);
    END update_employee;

    PROCEDURE delete_employee (
        p_emp_id employee.employee_id%TYPE
    ) AS
    BEGIN
        DELETE FROM employee
        WHERE
            employee_id = p_emp_id;

        IF SQL%rowcount > 0 THEN
            dbms_output.put_line('Employee deleted successfully.');
        ELSE
            raise_application_error(-20004, 'The employee isn''t found.');
        END IF;

    END delete_employee;
    
   FUNCTION get_employee_fullname(
        p_emp_id employee.employee_id%TYPE
    ) return varchar2 
    AS
       v_full_name VARCHAR2(80);
    BEGIN
        SELECT first_name || ' ' || last_name
        INTO v_full_name
        FROM employee
        WHERE employee_id = p_emp_id;
        
    RETURN v_full_name;           
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Employee not found for ID: ' || p_emp_id);
            RETURN NULL;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error retrieving employee name: ' || SQLERRM);
            RAISE;
            
    
    END get_employee_fullname;
    
END employee_management_pkg;

/
-----------------------------------------------------------------------------------
