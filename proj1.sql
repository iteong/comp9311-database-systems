-- COMP9311 15s1 Project 1
--
-- MyMyUNSW Solution Template

-- Q1: students who have taken more than 65 courses

create or replace view Q1(unswid, name)
as
SELECT y1.unswid, y1.name FROM people y1, course_enrolments y2 WHERE y1.id = y2.student GROUP BY y1.unswid, y1.name HAVING COUNT(y2.student) > 65
;

-- Q2: counts of student-only, staff-only, student+staff

create or replace view Q2(nstudents, nstaff, nboth)
as
SELECT
	(SELECT COUNT(*)
	FROM students
	LEFT JOIN staff ON staff.id = students.id
	WHERE staff.id IS NULL),
	(SELECT COUNT(*)
	FROM staff
	LEFT JOIN students on students.id = staff.id
	WHERE students.id IS NULL),
	(SELECT COUNT(*)
	FROM students
	INNER JOIN staff ON staff.id = students.id);

-- Q3: convenor for the most courses

create or replace view Q3(name, ncourses)
as
SELECT ranking.name, ranking.count FROM (SELECT counter.name, counter.count, row_number() OVER (ORDER BY GREATEST(counter.count) DESC) as rn from (SELECT convenor.name, COUNT(convenor.course) FROM (SELECT people.id, people.name, course_staff.course FROM people INNER JOIN course_staff on (people.id = course_staff.staff) WHERE role='1870' ORDER BY people.id) AS convenor GROUP BY convenor.name) AS counter) AS ranking WHERE rn = 1
;

-- Q4: program enrolments from 05s2

create or replace view Q4a(id)
as
SELECT x4.unswid AS id FROM program_enrolments x1, semesters x2, programs x3, people x4 WHERE x1.semester = x2.id AND x1.program = x3.id AND x1.student = x4.id AND x2.year = '2005' AND x2.term = 'S2' AND x3.name = 'Computer Science' AND x3.code = '3978'
;

create or replace view Q4b(id)
as
SELECT x5.unswid AS id FROM program_enrolments x1, semesters x2, streams x3, stream_enrolments x4, people x5 WHERE x1.semester = x2.id AND x1.id = x4.partof AND x1.student = x5.id AND x2.year = '2005' AND x2.term = 'S2' AND x3.id = x4.stream AND x3.code = 'SENGA1'
;

create or replace view Q4c(id)
as
SELECT x4.unswid AS id FROM program_enrolments x1, semesters x2, programs x3, people x4 WHERE x1.semester = x2.id AND x1.program = x3.id AND x1.student = x4.id AND x2.year = '2005' AND x2.term = 'S2' AND x3.offeredby = '89'
;

-- Q5: faculty with the most committees

create or replace view Counter(name, max)
as
SELECT org4.name, max(org4.count) FROM (SELECT * FROM (SELECT * FROM (SELECT commtable.facultyof, COUNT(*) FROM (SELECT facultyOf(y1.id) FROM orgunits y1, orgunit_types y2 WHERE y2.name = 'Committee' AND y1.utype = y2.id) AS commtable WHERE commtable.facultyof IS NOT NULL GROUP BY commtable.facultyof ORDER BY commtable.count DESC) AS toporg INNER JOIN (SELECT orgunits.id, orgunits.name FROM orgunits) AS org ON (org.id = toporg.facultyof)) AS org3 ORDER BY org3.count DESC) AS org4 GROUP BY org4.name ORDER BY max DESC;
;

create or replace view Q5(name)
as
SELECT name FROM Counter
WHERE max = (
SELECT max(max) from Counter);

-- Q6: convenors for specified course

create or replace view Coursecode(code, year, term, convenor)
as
SELECT s2.code, s4.year, s4.term, s6.name
FROM staff_roles s1
INNER JOIN course_staff s5 ON s1.id = s5.role
INNER JOIN people s6 ON s6.id = s5.staff
INNER JOIN courses s3 ON s3.id = s5.course
INNER JOIN subjects s2 ON s2.id = s3.subject
INNER JOIN semesters s4 ON s3.semester = s4.id 
WHERE s1.name = 'Course Convenor';

create or replace function Q6(course char)
	returns table (course char, year integer, term char, convenor char)
as $$
	SELECT * FROM Coursecode WHERE Coursecode.code = $1;
$$ language sql
;
