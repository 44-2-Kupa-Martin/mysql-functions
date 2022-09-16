DROP FUNCTION IF EXISTS f_Subsidy;

CREATE FUNCTION f_Subsidy(
    salary DECIMAL(65, 2)
) RETURNS DECIMAL(65, 2) DETERMINISTIC
RETURN salary*(0.07);

DROP FUNCTION IF EXISTS f_ComputeHealth;

CREATE FUNCTION f_ComputeHealth(
    salary DECIMAL(65, 2)
) RETURNS DECIMAL(65, 2) DETERMINISTIC
RETURN salary*(0.04);

DROP FUNCTION IF EXISTS f_ComputePension;

CREATE FUNCTION f_ComputePension(
    salary DECIMAL(65, 2)
) RETURNS DECIMAL(65, 2) DETERMINISTIC
RETURN salary*(0.04);

DROP FUNCTION IF EXISTS f_ComputeBonus;

CREATE FUNCTION f_ComputeBonus(
    salary DECIMAL(65, 2)
) RETURNS DECIMAL(65, 2) DETERMINISTIC
RETURN salary*(0.08);

DROP FUNCTION IF EXISTS f_ComputeFinalSalary;

CREATE FUNCTION f_ComputeFinalSalary(
    salary DECIMAL(65, 2)
) RETURNS DECIMAL(65, 2) DETERMINISTIC
RETURN salary-f_ComputeHealth(salary)-f_ComputePension(salary)+f_ComputeBonus(salary)+f_Subsidy(salary);



DROP PROCEDURE IF EXISTS usp_InsertSalaryData;

DELIMITER $$

CREATE PROCEDURE usp_InsertSalaryData()
main:BEGIN
    DECLARE done INT(1) DEFAULT FALSE;
    DECLARE columns INT(1);
    DECLARE cod INT;
    DECLARE salary DECIMAL(65,2);

    DECLARE cur_empleado CURSOR FOR 
        SELECT codemp, salario FROM empleado;

    DECLARE CONTINUE HANDLER FOR NOT FOUND 
        SET done= TRUE;

    -- Check if the table should be modified. (Honestly, this shouldnt be here but whatever)
    SELECT COUNT(*) INTO columns FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA LIKE "empleados" AND TABLE_NAME LIKE "empleado" AND COLUMN_NAME IN ('subsidio', 'salud', 'pension', 'bono', 'salario_final');
    IF (columns != 5) THEN
        ALTER TABLE empleado
            ADD COLUMN subsidio DECIMAL(65, 2),
            ADD COLUMN salud DECIMAL(65, 2),
            ADD COLUMN pension DECIMAL(65, 2),
            ADD COLUMN bono DECIMAL(65, 2),
            ADD COLUMN salario_final DECIMAL(65, 2)
        ;
    END IF;

    -- For each employee, update their salary
    OPEN cur_empleado;

    for_each: LOOP
        FETCH cur_empleado INTO cod, salary;
        IF done THEN
            LEAVE for_each;
        END IF;
        UPDATE empleado SET 
            subsidio= f_Subsidy(salary), 
            salud= f_ComputeHealth(salary), 
            pension= f_ComputePension(salary), 
            bono= f_ComputeBonus(salary), 
            salario_final= f_ComputeFinalSalary(salary)
        WHERE
            codemp = cod    
        ;
    END LOOP;

    CLOSE cur_empleado;
END main$$

DELIMITER ;
