--Test Cases

--1- Add an Employee successfully 
BEGIN
    employee_management_pkg.add_employee(
        p_first_name     => 'John',
        p_last_name      => 'Doe',
        p_email          => 'john.doe@example.com',
        p_phone_number   => '1234567890',
        p_hire_date      => TO_DATE('2025-04-24', 'YYYY-MM-DD'),
        p_job_id         => 'IT_PROG',
        p_salary         => 5000,
        p_commission_pct => NULL,
        p_manager_id     => NULL,
        p_department_id  => 10
    );
END;
/
-- Verify data
SELECT * FROM employee WHERE email = 'john.doe@example.com';

SELECT * FROM salary_history ;


--------------------------------------------------------------------------------
--2-Adding an employee with invalid data (duplicate email)
BEGIN
    employee_management_pkg.add_employee(
        p_first_name     => 'Jane',
        p_last_name      => 'Smith',
        p_email          => 'john.doe@example.com', -- Duplicate email
        p_phone_number   => '0987654321',
        p_hire_date      => TO_DATE('2025-04-24', 'YYYY-MM-DD'),
        p_job_id         => 'SA_REP',
        p_salary         => 7000,
        p_commission_pct => 0.1,
        p_manager_id     => NULL,
        p_department_id  => 20
    );
END;
/
-- Verify no new data
SELECT * FROM employee WHERE email = 'john.doe@example.com';



--------------------------------------------------------------------------------
--3-Adding an employee with an invalid job_id
BEGIN
    employee_management_pkg.add_employee(
        p_first_name     => 'Alice',
        p_last_name      => 'Brown',
        p_email          => 'alice.brown@example.com',
        p_phone_number   => '1112223333',
        p_hire_date      => TO_DATE('2025-04-24', 'YYYY-MM-DD'),
        p_job_id         => 'INVAL_JOB', -- Invalid job_id
        p_salary         => 6000,
        p_commission_pct => NULL,
        p_manager_id     => NULL,
        p_department_id  => 10
    );
END;
/

--------------------------------------------------------------------------------
--4- Employee Salary Update (Success)
BEGIN
    employee_management_pkg.update_employee(
        p_emp_id      => 100,
        p_column_name => 'SALARY',
        p_new_value   => '6000'
    );
END;
/
-- Verify data
SELECT * FROM employee WHERE employee_id = 100;

SELECT * FROM salary_history WHERE employee_id = 100;


--------------------------------------------------------------------------------
--5-Salary update with out-of-band value
BEGIN
    employee_management_pkg.update_employee(
        p_emp_id      => 100,
        p_column_name => 'SALARY',
        p_new_value   => '15000' -- Exceeds max_salary for IT_PROG
    );
END;
/
-- Verify no changes
SELECT salary FROM employee WHERE employee_id = 100;
SELECT * FROM salary_history WHERE employee_id = 100;


--------------------------------------------------------------------------------
--6-Updating an impermissible column (such as employee_id)
BEGIN
    employee_management_pkg.update_employee(
        p_emp_id      => 100,
        p_column_name => 'EMPLOYEE_ID',
        p_new_value   => '101'
    );
END;
/

--------------------------------------------------------------------------------
--7-Updating a non-existent employee
BEGIN
    employee_management_pkg.update_employee(
        p_emp_id      => 999,
        p_column_name => 'FIRST_NAME',
        p_new_value   => 'Bob'
    );
END;
/

--------------------------------------------------------------------------------
--8. Moving an employee between departments (Success)
BEGIN
    employee_management_pkg.transfer_employee(
        p_emp_id      => 100,
        p_old_dept_id => 10,
        p_new_dept_id => 20,
        p_old_mgr_id  => NULL,
        p_new_mgr_id  => NULL
    );
END;
/
-- Verify data
SELECT department_id FROM employee WHERE employee_id = 100;
SELECT * FROM transfer_history WHERE employee_id = 100;



--------------------------------------------------------------------------------
--9. Moving an employee with an invalid department_id
BEGIN
    employee_management_pkg.transfer_employee(
        p_emp_id      => 100,
        p_old_dept_id => 20,
        p_new_dept_id => 999, -- Invalid department_id
        p_old_mgr_id  => NULL,
        p_new_mgr_id  => NULL
    );
END;
/


--------------------------------------------------------------------------------
--10. Delete Employee (Success)
BEGIN
    employee_management_pkg.delete_employee(p_emp_id => 100);
END;
/
-- Verify data
SELECT * FROM employee WHERE employee_id = 100;
SELECT * FROM deletion_logs WHERE employee_id = 100;



--------------------------------------------------------------------------------
--11. Delete a non-existent employee
BEGIN
    employee_management_pkg.delete_employee(p_emp_id => 999);
END;
/
-- Verify data
SELECT * FROM employee WHERE employee_id = 100;
SELECT * FROM deletion_logs WHERE employee_id = 100;



--------------------------------------------------------------------------------
--12. Retrieve Employee Name (Success)
-- First, add a new employee for testing
BEGIN
    employee_management_pkg.add_employee(
        p_first_name     => 'Mary',
        p_last_name      => 'Johnson',
        p_email          => 'mary.johnson@example.com',
        p_phone_number   => '4445556666',
        p_hire_date      => TO_DATE('2025-04-24', 'YYYY-MM-DD'),
        p_job_id         => 'SA_REP',
        p_salary         => 8000,
        p_commission_pct => 0.2,
        p_manager_id     => NULL,
        p_department_id  => 20
    );
END;
/
-- Test get_employee_fullname
DECLARE
    v_full_name VARCHAR2(80);
BEGIN
    v_full_name := employee_management_pkg.get_employee_fullname(101);
    DBMS_OUTPUT.PUT_LINE('Full Name: ' || v_full_name);
END;
/



--------------------------------------------------------------------------------
--13. Retrieve a non-existent employee name

BEGIN
    DBMS_OUTPUT.PUT_LINE('Full Name: ' || employee_management_pkg.get_employee_fullname(1002));
END;
/


--------------------------------------------------------------------------------
-- 14.Add multiple employees for performance test
SET SERVEROUTPUT ON;
BEGIN
    FOR i IN 1..100 LOOP
        BEGIN
            employee_management_pkg.add_employee(
                p_first_name     => 'Employee' || i,
                p_last_name      => 'Test',
                p_email          => 'emp' || i || '@example.com',
                p_phone_number   => '555' || LPAD(i, 7, '0'),
                p_hire_date      => TO_DATE('2025-04-24', 'YYYY-MM-DD'),
                p_job_id         => CASE WHEN MOD(i, 2) = 0 THEN 'IT_PROG' ELSE 'SA_REP' END,
                p_salary         => 6000 + (i*2),
                p_commission_pct => NULL,
                p_manager_id     => NULL,
                p_department_id  => CASE WHEN MOD(i, 2) = 0 THEN 10 ELSE 20 END
            );
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                DBMS_OUTPUT.PUT_LINE('Duplicate for i = ' || i || ': Employee already found.');
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error for i = ' || i || ': ' || SQLERRM);
        END;
    END LOOP;
    COMMIT;
END;
/



-- Test query performance
SELECT employee_id, first_name, last_name
FROM employee
WHERE job_id = 'IT_PROG' AND department_id = 10;


--------------------------------------------------------------------------------
--15. Batch Operations Test
-- Batch update salaries
UPDATE employee
SET salary = salary + 100
WHERE department_id = 10;


-- Verify salary_history
SELECT * FROM salary_history WHERE employee_id IN (SELECT employee_id FROM employee WHERE department_id = 10);
-- Batch delete
DELETE FROM employee WHERE department_id = 20;
-- Verify deletion_logs
SELECT * FROM deletion_logs WHERE department_id = 20;

