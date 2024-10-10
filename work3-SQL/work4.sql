use employee_management;

# 11. 计算所有员工的工资总和。
SELECT SUM(salary) AS 工资总和
FROM employees;

# 12. 查询姓"Smith"的员工信息。
SELECT *
FROM employees 
WHERE last_name = 'Smith';

# 13. 查询即将在半年内到期的项目。
SELECT * 
FROM projects
WHERE end_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 6 MONTH);

# 14. 查询至少参与了两个项目的员工。
SELECT e.*
FROM employees e
JOIN employee_projects ep ON e.emp_id = ep.emp_id
GROUP BY e.emp_id
HAVING COUNT(ep.project_id) >= 2;

# 15. 查询没有参与任何项目的员工。
SELECT e.*
FROM employees e
LEFT JOIN employee_projects ep ON e.emp_id = ep.emp_id
WHERE ep.project_id IS NULL;

# 16. 计算每个项目参与的员工数量。
SELECT project_id, COUNT(emp_id) AS 员工数量
FROM employee_projects
GROUP BY project_id;

# 17. 查询工资第二高的员工信息。
SELECT * 
FROM employees
ORDER BY salary DESC
LIMIT 1 OFFSET 1;

# 18. 查询每个部门工资最高的员工。
WITH ranked_employees AS (
    SELECT e.*,d.dept_name,
           RANK() OVER (PARTITION BY e.dept_id ORDER BY e.salary DESC) AS salary_rank
    FROM employees e
    JOIN departments d ON e.dept_id = d.dept_id
)
SELECT emp_id, first_name, last_name, dept_name, salary
FROM ranked_employees
WHERE salary_rank = 1
ORDER BY dept_name, salary DESC;

# 19. 计算每个部门的工资总和,并按照工资总和降序排列。
SELECT dept_id, SUM(salary) AS total_salary
FROM employees
GROUP BY dept_id
ORDER BY total_salary DESC;

# 20. 查询员工姓名、部门名称和工资。
SELECT e.first_name, e.last_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

# 21. 查询每个员工的上级主管(假设emp_id小的是上级)。
WITH ManagerCandidates AS (
    SELECT 
        emp_id,
        first_name,
        last_name,
        dept_id,
        MIN(emp_id) OVER (PARTITION BY dept_id) AS min_emp_id
    FROM employees
)
SELECT 
    e1.emp_id AS 员工编号,
    CONCAT(e1.first_name, ' ', e1.last_name) AS 员工姓名,
    COALESCE(e2.emp_id, NULL) AS 上级主管编号,
    COALESCE(CONCAT(e2.first_name, ' ', e2.last_name), NULL) AS 上级主管姓名
FROM employees e1
LEFT JOIN ManagerCandidates e2 ON e1.dept_id = e2.dept_id AND e1.emp_id != e2.min_emp_id AND e2.emp_id = e2.min_emp_id
WHERE e1.emp_id != e2.min_emp_id OR e1.emp_id IS NULL;

# 22. 查询所有员工的工作岗位,不要重复。
SELECT DISTINCT job_title 
FROM employees;

# 23. 查询平均工资最高的部门。
SELECT dept_id
FROM employees
GROUP BY dept_id
ORDER BY AVG(salary) DESC
LIMIT 1;

# 24. 查询工资高于其所在部门平均工资的员工。
SELECT e.emp_id, CONCAT(e.first_name," ", e.last_name), e.salary, d.avg_salary
FROM employees e
JOIN (
    SELECT dept_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY dept_id
) d ON e.dept_id = d.dept_id
WHERE e.salary > d.avg_salary;

# 25. 查询每个部门工资前两名的员工。
WITH ranked_employees AS (
    SELECT e.*, DENSE_RANK() OVER (PARTITION BY e.dept_id ORDER BY e.salary DESC) AS salary_rank
    FROM employees e
)
SELECT emp_id, CONCAT(first_name, " ",last_name),salary,dept_id
FROM ranked_employees
WHERE salary_rank <= 2;

# 26. 查询跨部门的项目(参与员工来自不同部门)。
SELECT p.project_id, p.project_name
FROM projects p
JOIN employee_projects ep ON p.project_id = ep.project_id
JOIN employees e ON ep.emp_id = e.emp_id
GROUP BY p.project_id, p.project_name
HAVING COUNT(DISTINCT e.dept_id) > 1;

# 27. 查询每个员工的工作年限,并按工作年限降序排序。
SELECT emp_id, CONCAT(first_name, " ",last_name),
       TIMESTAMPDIFF(YEAR, hire_date, CURDATE()) AS years_of_service
FROM employees
ORDER BY years_of_service DESC;

# 28. 查询本月过生日的员工(假设hire_date是生日)。
SELECT emp_id, CONCAT(first_name, " ",last_name)
FROM employees
WHERE MONTH(hire_date) = MONTH(CURDATE()) AND DAY(hire_date) = DAY(CURDATE());

# 29. 查询即将在90天内到期的项目和负责该项目的员工。
SELECT p.project_id, p.project_name, e.emp_id, CONCAT(e.first_name," ", e.last_name)
FROM projects p
JOIN employee_projects ep ON p.project_id = ep.project_id
JOIN employees e ON ep.emp_id = e.emp_id
WHERE p.end_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 90 DAY);

# 30. 计算每个项目的持续时间(天数)。
SELECT project_id, 
       project_name, 
       TIMESTAMPDIFF(DAY, start_date, end_date) AS duration_days
FROM projects;

# 31. 查询没有进行中项目的部门。
SELECT d.dept_id, d.dept_name
FROM departments d
WHERE NOT EXISTS (
    SELECT 1
    FROM employees e
    JOIN employee_projects ep ON e.emp_id = ep.emp_id
    JOIN projects p ON ep.project_id = p.project_id
    WHERE e.dept_id = d.dept_id AND p.end_date >= CURDATE()
);

# 32. 查询员工数量最多的部门。
SELECT dept_name, num_employees
FROM (
    SELECT departments.dept_name, COUNT(employees.emp_id) AS num_employees
    FROM departments
    LEFT JOIN employees ON departments.dept_id = employees.dept_id
    GROUP BY departments.dept_id
) AS subquery
WHERE num_employees = (
    SELECT MAX(num_employees)
    FROM (
        SELECT COUNT(employees.emp_id) AS num_employees
        FROM departments
        LEFT JOIN employees ON departments.dept_id = employees.dept_id
        GROUP BY departments.dept_id
    ) AS count_query
);

# 33. 查询参与项目最多的部门。
SELECT dept_id,dept_name, num_projects
FROM (
    SELECT departments.dept_id,departments.dept_name, COUNT(DISTINCT employee_projects.project_id) AS num_projects
    FROM departments
    LEFT JOIN employees ON departments.dept_id = employees.dept_id
    LEFT JOIN employee_projects ON employees.emp_id = employee_projects.emp_id
    GROUP BY departments.dept_id, departments.dept_name
) AS dept_project_counts
WHERE num_projects = (
    SELECT MAX(num_projects)
    FROM (
        SELECT COUNT(DISTINCT employee_projects.project_id) AS num_projects
        FROM departments
        LEFT JOIN employees ON departments.dept_id = employees.dept_id
        LEFT JOIN employee_projects ON employees.emp_id = employee_projects.emp_id
        GROUP BY departments.dept_id
    ) AS subquery
);

# 34. 计算每个员工的薪资涨幅(假设每年涨5%)。
SELECT emp_id, CONCAT(first_name," ", last_name), salary,
       salary * (1 + 0.05) AS salary_after_one_year
FROM employees;

# 35. 查询入职时间最长的3名员工。
WITH ranked_employees AS (
    SELECT 
        e.*, 
        DENSE_RANK() OVER (ORDER BY hire_date ASC) AS hire_rank
    FROM employees e
)
SELECT emp_id, CONCAT(first_name, " ", last_name) AS full_name, hire_date
FROM ranked_employees
WHERE hire_rank <= 3
ORDER BY hire_date ASC;

use test;
# 11. 查询C001比C002课程成绩高的学生信息及课程分数。
SELECT s.name, sc1.score AS C001成绩, sc2.score AS C002成绩
FROM student s
JOIN score sc1 ON s.student_id = sc1.student_id AND sc1.course_id = 'C001'
JOIN score sc2 ON s.student_id = sc2.student_id AND sc2.course_id = 'C002'
WHERE sc1.score > sc2.score;

# 12. 统计各科成绩各分数段人数：课程编号，课程名称，[100-85]，[85-70]，[70-60]，[60-0] 及所占百分比
SELECT 
    c.course_id,
    c.course_name,
    COUNT(CASE WHEN sc.score BETWEEN 85 AND 100 THEN 1 END) AS score_100_85,
    COUNT(CASE WHEN sc.score BETWEEN 70 AND 84 THEN 1 END) AS score_85_70,
    COUNT(CASE WHEN sc.score BETWEEN 60 AND 69 THEN 1 END) AS score_70_60,
    COUNT(CASE WHEN sc.score < 60 THEN 1 END) AS score_60_0,
    ROUND(COUNT(CASE WHEN sc.score BETWEEN 85 AND 100 THEN 1 END) / NULLIF(COUNT(sc.score), 0) * 100, 2) AS percent_100_85,
    ROUND(COUNT(CASE WHEN sc.score BETWEEN 70 AND 84 THEN 1 END) / NULLIF(COUNT(sc.score), 0) * 100, 2) AS percent_85_70,
    ROUND(COUNT(CASE WHEN sc.score BETWEEN 60 AND 69 THEN 1 END) / NULLIF(COUNT(sc.score), 0) * 100, 2) AS percent_70_60,
    ROUND(COUNT(CASE WHEN sc.score < 60 THEN 1 END) / NULLIF(COUNT(sc.score), 0) * 100, 2) AS percent_60_0
FROM course c
JOIN score sc ON c.course_id = sc.course_id
GROUP BY c.course_id, c.course_name;

# 13. 查询选择C002课程但没选择C004课程的成绩情况(不存在时显示为 null )。
SELECT s.student_id,s.name, sc.score
FROM student s
JOIN score sc ON s.student_id = sc.student_id AND sc.course_id = 'C002'
LEFT JOIN score sc2 ON s.student_id = sc2.student_id AND sc2.course_id = 'C004'
WHERE sc2.score IS NULL;

# 14. 查询平均分数最高的学生姓名和平均分数。
WITH ranked_students AS (
    SELECT 
        s.name,
        AVG(sc.score) AS average_score,
        DENSE_RANK() OVER (ORDER BY AVG(sc.score) DESC) AS score_rank
    FROM student s
    JOIN score sc ON s.student_id = sc.student_id
    GROUP BY s.name
)
SELECT name, average_score
FROM ranked_students
WHERE score_rank = 1;

# 15. 查询总分最高的前三名学生的姓名和总分。
WITH ranked_students AS (
    SELECT 
        s.name,
        SUM(sc.score) AS total_score,
        DENSE_RANK() OVER (ORDER BY SUM(sc.score) DESC) AS total_rank
    FROM student s
    JOIN score sc ON s.student_id = sc.student_id
    GROUP BY s.student_id
)
SELECT name, total_score
FROM ranked_students
WHERE total_rank <= 3;

# 16. 查询各科成绩最高分、最低分和平均分。要求如下：
# 以如下形式显示：课程 ID，课程 name，最高分，最低分，平均分，及格率，中等率，优良率，优秀率
# 及格为>=60，中等为：70-80，优良为：80-90，优秀为：>=90
# 要求输出课程号和选修人数，查询结果按人数降序排列，若人数相同，按课程号升序排列
SELECT 
    c.course_id,
    c.course_name,
    MAX(sc.score) 最高分,
    MIN(sc.score) 最低分,
    AVG(sc.score) 平均分,
    ROUND(SUM(CASE WHEN sc.score >= 60 THEN 1 ELSE 0 END) / COUNT(sc.score) * 100, 2) 及格率,
    ROUND(SUM(CASE WHEN sc.score BETWEEN 70 AND 80 THEN 1 ELSE 0 END) / COUNT(sc.score) * 100, 2) 中等率,
    ROUND(SUM(CASE WHEN sc.score BETWEEN 80 AND 90 THEN 1 ELSE 0 END) / COUNT(sc.score) * 100, 2) 优良率,
    ROUND(SUM(CASE WHEN sc.score >= 90 THEN 1 ELSE 0 END) / COUNT(sc.score) * 100, 2) 优秀率,
    COUNT(sc.student_id) AS number_of_students
FROM course c
JOIN score sc ON c.course_id = sc.course_id
GROUP BY c.course_id
ORDER BY number_of_students DESC, c.course_id ASC;

# 17. 查询男生和女生的人数。
SELECT gender, COUNT(*) AS number_of_students
FROM student
GROUP BY gender;

# 18. 查询年龄最大的学生姓名。
SELECT name
FROM student
WHERE birth_date = (
    SELECT MIN(birth_date)
    FROM student
);

# 19. 查询年龄最小的教师姓名。
SELECT name
FROM teacher
WHERE birth_date = (
    SELECT MAX(birth_date)
    FROM teacher
);

# 20. 查询学过「张教授」授课的同学的信息。
SELECT s.*
FROM student s
JOIN score sc ON s.student_id = sc.student_id
JOIN course c ON sc.course_id = c.course_id
JOIN teacher t ON c.teacher_id = t.teacher_id
WHERE t.name = '张教授';

# 21. 查询查询至少有一门课与学号为"2021001"的同学所学相同的同学的信息 。
SELECT DISTINCT s.*
FROM student s
JOIN score sc ON s.student_id = sc.student_id
JOIN course c ON sc.course_id = c.course_id
WHERE c.course_id IN (
    SELECT course_id
    FROM score
    WHERE student_id = '2021001'
) AND s.student_id != '2021001';

# 22. 查询每门课程的平均分数，并按平均分数降序排列。
SELECT c.course_id, c.course_name, AVG(sc.score) AS average_score
FROM course c
JOIN score sc ON c.course_id = sc.course_id
GROUP BY c.course_id
ORDER BY average_score DESC;

# 23. 查询学号为"2021001"的学生所有课程的分数。
SELECT c.course_name, sc.score
FROM course c
JOIN score sc ON c.course_id = sc.course_id
WHERE sc.student_id = '2021001';

# 24. 查询所有学生的姓名、选修的课程名称和分数。
SELECT s.name, c.course_name, sc.score
FROM student s
JOIN score sc ON s.student_id = sc.student_id
JOIN course c ON sc.course_id = c.course_id;

# 25. 查询每个教师所教授课程的平均分数。
SELECT t.name, c.course_name, AVG(sc.score) AS average_score
FROM teacher t
JOIN course c ON t.teacher_id = c.teacher_id
JOIN score sc ON c.course_id = sc.course_id
GROUP BY t.teacher_id, c.course_name;

# 26. 查询分数在80到90之间的学生姓名和课程名称。
SELECT s.name, c.course_name
FROM student s
JOIN score sc ON s.student_id = sc.student_id
JOIN course c ON sc.course_id = c.course_id
WHERE sc.score BETWEEN 80 AND 90;

# 27. 查询每个班级的平均分数。
SELECT s.my_class, AVG(sc.score) AS average_score
FROM student s
JOIN score sc ON s.student_id = sc.student_id
GROUP BY s.my_class;

# 28. 查询没学过"王讲师"老师讲授的任一门课程的学生姓名。
SELECT s.name
FROM student s
WHERE NOT EXISTS (
    SELECT 1
    FROM score sc
    JOIN course c ON sc.course_id = c.course_id
    WHERE s.student_id = sc.student_id AND c.teacher_id IN (
        SELECT t.teacher_id
        FROM teacher t
        WHERE t.name = '王讲师'
    )
);

# 29. 查询两门及其以上小于85分的同学的学号，姓名及其平均成绩 。
SELECT s.student_id, s.name, AVG(sc.score) AS average_score
FROM student s
JOIN score sc ON s.student_id = sc.student_id
GROUP BY s.student_id
HAVING COUNT(CASE WHEN sc.score < 85 THEN 1 END) >= 2;

# 30. 查询所有学生的总分并按降序排列。
SELECT s.name, SUM(sc.score) AS total_score
FROM student s
JOIN score sc ON s.student_id = sc.student_id
GROUP BY s.student_id
ORDER BY total_score DESC;

# 31. 查询平均分数超过85分的课程名称。
SELECT c.course_name
FROM course c
JOIN score sc ON c.course_id = sc.course_id
GROUP BY c.course_id
HAVING AVG(sc.score) > 85;

# 32. 查询每个学生的平均成绩排名。
SELECT s.student_id, s.name, 
    AVG(sc.score) AS avg_score, 
    RANK() OVER (ORDER BY AVG(sc.score) DESC) AS avg_rank
FROM student s
JOIN score sc ON s.student_id = sc.student_id
GROUP BY s.student_id, s.name;

# 33. 查询每门课程分数最高的学生姓名和分数。
SELECT sc.course_id, sc.student_id, sc.score, s.name
FROM score sc
JOIN student s ON sc.student_id = s.student_id
WHERE (sc.course_id, sc.score) IN (
    SELECT sc_inner.course_id, MAX(sc_inner.score)
    FROM score sc_inner
    GROUP BY sc_inner.course_id
);

# 34. 查询选修了"高等数学"和"大学物理"的学生姓名。
SELECT DISTINCT s.name
FROM student s
JOIN score sc1 ON s.student_id = sc1.student_id
JOIN course c1 ON sc1.course_id = c1.course_id AND c1.course_name = '高等数学'
JOIN score sc2 ON s.student_id = sc2.student_id
JOIN course c2 ON sc2.course_id = c2.course_id AND c2.course_name = '大学物理';

# 35. 按平均成绩从高到低显示所有学生的所有课程的成绩以及平均成绩（没有选课则为空）。
SELECT s.student_id, s.name, c.course_id, c.course_name, sc.score, sc2.avg_score
FROM student s
LEFT JOIN score sc ON s.student_id = sc.student_id
LEFT JOIN course c ON sc.course_id = c.course_id
LEFT JOIN (
    SELECT student_id, AVG(score) AS avg_score
    FROM score
    GROUP BY student_id
) sc2 ON s.student_id = sc2.student_id
ORDER BY sc2.avg_score DESC, s.student_id;

# 36. 查询分数最高和最低的学生姓名及其分数。
SELECT s.name,sc.score
FROM score sc
JOIN student s ON sc.student_id = s.student_id
WHERE sc.score = (
	SELECT MAX(score) 
    FROM score
)
UNION ALL
SELECT s.name,sc.score
FROM score sc
JOIN student s ON sc.student_id = s.student_id
WHERE sc.score = (
	SELECT MIN(score) 
    FROM score
);
    
# 37. 查询每个班级的最高分和最低分。
SELECT my_class, MAX(score) AS max_score, MIN(score) AS min_score
FROM student
JOIN score ON student.student_id = score.student_id
GROUP BY my_class;

# 38. 查询每门课程的优秀率（优秀为90分）。
SELECT course_id, COUNT(*) 该课程总人数, 
       SUM(CASE WHEN score >= 90 THEN 1 ELSE 0 END) 优秀数, 
       ROUND(SUM(CASE WHEN score >= 90 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) 优秀率
FROM score
GROUP BY course_id;

# 39. 查询平均分数超过班级平均分数的学生。
SELECT s1.student_id, s1.name, s1.avg_score, s2.class_avg_score
FROM (
    SELECT student.student_id, student.name, student.my_class, AVG(score.score) AS avg_score
    FROM student
    JOIN score ON student.student_id = score.student_id
    GROUP BY student.student_id, student.name, student.my_class
) s1 -- 派生表
JOIN (
    SELECT student.my_class, AVG(score.score) AS class_avg_score
    FROM student
    JOIN score ON student.student_id = score.student_id
    GROUP BY student.my_class
) s2 ON s1.my_class = s2.my_class
WHERE s1.avg_score > s2.class_avg_score;

# 40. 查询每个学生的分数及其与课程平均分的差值。
SELECT s.name AS student_name,c.course_name,sc.score,
    AVG(sc.score) OVER (PARTITION BY sc.course_id) AS avg_score,
    sc.score - AVG(sc.score) OVER (PARTITION BY sc.course_id) AS score_diff
FROM score sc
JOIN student s ON sc.student_id = s.student_id
JOIN course c ON sc.course_id = c.course_id;
    
# 41. 查询至少有一门课程分数低于80分的学生姓名。
SELECT DISTINCT s.name
FROM score sc
JOIN student s ON sc.student_id = s.student_id
WHERE sc.score < 80;

# 42. 查询所有课程分数都高于85分的学生姓名。
SELECT s.name
FROM student s
WHERE NOT EXISTS (
    SELECT 1 
    FROM score sc 
    WHERE sc.student_id = s.student_id AND sc.score <= 85
);

# 43. 查询查询平均成绩大于等于90分的同学的学生编号和学生姓名和平均成绩。
SELECT s.student_id,s.name,AVG(sc.score) AS avg_score
FROM score sc
JOIN student s ON sc.student_id = s.student_id
GROUP BY s.student_id, s.name
HAVING AVG(sc.score) >= 90;

# 44. 查询选修课程数量最少的学生姓名。
SELECT s.name
FROM student s
JOIN (
    SELECT student_id, COUNT(course_id) AS course_count
    FROM score
    GROUP BY student_id
    ORDER BY course_count ASC
) AS subquery ON s.student_id = subquery.student_id;
    
# 45. 查询每个班级的第2名学生（按平均分数排名）。
WITH Ranked_Students AS (
    SELECT s.student_id, s.name, AVG(sc.score) as avg_score,
           DENSE_RANK() OVER (PARTITION BY s.my_class ORDER BY AVG(sc.score) DESC) as avg_rank
    FROM student s
    JOIN score sc ON s.student_id = sc.student_id
    GROUP BY s.student_id, s.name
)
SELECT student_id, name, avg_score
FROM Ranked_Students
WHERE avg_rank = 2;

# 46. 查询每门课程分数前三名的学生姓名和分数。
WITH Ranked_Scores AS (
    SELECT sc.student_id, sc.score, s.name, c.course_name,
           DENSE_RANK() OVER (PARTITION BY sc.course_id ORDER BY sc.score DESC) as sc_rank
    FROM score sc
    JOIN student s ON sc.student_id = s.student_id
    JOIN course c ON sc.course_id = c.course_id
)
SELECT course_name,student_id, score, name
FROM Ranked_Scores
WHERE sc_rank <= 3;

# 47. 查询平均分数最高和最低的班级。
SELECT my_class,average_score
FROM
    (SELECT s.my_class,AVG(sc.score) AS average_score
    FROM score sc
    JOIN student s ON sc.student_id = s.student_id
    GROUP BY s.my_class
    ORDER BY average_score DESC
    LIMIT 1) AS highest_avg
UNION ALL
SELECT my_class,average_score
FROM
    (SELECT s.my_class,AVG(sc.score) AS average_score
    FROM score sc
    JOIN student s ON sc.student_id = s.student_id
    GROUP BY s.my_class
    ORDER BY average_score ASC
    LIMIT 1) AS lowest_avg;

# 48. 查询每个学生的总分和他所在班级的平均分数。
SELECT s.student_id, s.name, SUM(sc.score) AS total_score, c_avg.class_avg_score
FROM student s
JOIN score sc ON s.student_id = sc.student_id
JOIN (
    SELECT my_class, AVG(score) AS class_avg_score
    FROM student
    JOIN score ON student.student_id = score.student_id
    GROUP BY my_class
) c_avg ON s.my_class = c_avg.my_class
GROUP BY s.student_id;

# 49. 查询每个学生的最高分的课程名称, 学生名称，成绩。
SELECT s.name, c.course_name, sc.score
FROM student s
JOIN score sc ON s.student_id = sc.student_id
JOIN course c ON sc.course_id = c.course_id
WHERE (s.student_id, sc.score) IN (
    SELECT student_id, MAX(score)
    FROM score
    GROUP BY student_id
);

# 50. 查询每个班级的学生人数和平均年龄。
SELECT my_class, COUNT(*) AS student_count, AVG(YEAR(CURDATE()) - YEAR(birth_date)) AS avg_age
FROM student
GROUP BY my_class;