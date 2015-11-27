# comp9311-database-systems
PostgreSQL Projects for Database Systems (UNSW Semester 1 2015)

*** PROJECT 1:

Q1 (3 marks)
Define an SQL view Q1(unswid, name) that gives the student id and name of any student who has studied more than 65 courses at UNSW. The name should be taken from the People.name field for the student, and the student id should be taken from People.unswid.

Q2 (5 marks)
Define an SQL view Q2(nstudents, nstaff, nboth) which produces a table with a single row containing counts of:
- the total number of students (who are not also staff)
- the total number of staff (who are not also students)
- the total number of people who are both staff and student.

Q3 (5 marks)
Define an SQL view Q3(name, ncourses) that prints the name of the person(s) who has been lecturer-in-charge (LIC) of the most courses at UNSW and the number of courses they have been LIC for. In the database, the LIC has the role of "Course Convenor".

Q4 (6 marks)
Define SQL views Q4a(id), Q4b(id), and Q4c(id), which give the student IDs of, respectively
- all students enrolled in 05s2 in the Computer Science (3978) degree
- all students enrolled in 05s2 in the Software Engineering (SENGA1) stream
- all students enrolled in 05s2 in degrees offered by CSE
Note: the student IDs are the UNSW id's (i.e. student numbers) defined in the People.unswid field.
The definitions could be used as definitions for these groups in the student_groups table, although you do not need to add them into the Student_groups table.

Q5 (8 marks)
Define an SQL view Q5(name) which gives the faculty with the maximum number of committees. Include in the count for each faculty, both faculty-level committees and also the committees under the schools within the faculty. You can use the facultyOf() function, which is already available in the database, to assist with this (You can view the function definition using proper psql command). You can assume that committees are defined only at the faculty and school level.Use the OrgUnits.name field as the faculty name.

Q6 (8 marks)
Define an SQL function (not PLpgSQL) called Q6(text) that takes as parameter a UNSW course code (e.g. COMP1917) and returns a list of all offerings of the course for which a Course Convenor is known. Note that this means just the Course Convenor role, not Course Lecturer or any other role associated with the course. Also, if there happen to be several Course Convenors, they should all be returned (in separate tuples). If there is no Course Convenor registered for a particular offering of the course, then that course offering should not appear in the result.
The function must use the following interface:
create or replace function Q6(text)
returns table (course text, year integer, term text, convenor text)
The course field in the result tuples should be the UNSW course code (i.e. that same thing that was used as the parameter). If the parameter does not correspond to a known UNSW course, then simply return an empty result set.

*** PROJECT 2:

Q1 (7 marks)
Define an SQL function (SQL, not PLpgSQL) called Q1(integer) that takes as parameter either
a People.id value (i.e. an internal database identifier) or a People.unswid value (i.e. a UNSW student ID), and returns the name of that person. If the id value is invalid, return an empty result. You can assume that People.id and People.unswid values come from disjoint sets, so you should never return multiple names. (It turns out that the sets aren't quite disjoint, but I won't test any of the cases where the id/unswid sets overlap)

The function must use the following interface: 
create or replace function Q1(integer) returns text ... 

Q2 (12 marks)
The transcript(integer) function from lectures is supplied in the database. Define a new PLpgSQL function Q2(integer), which is based on this function but returns a new kind of transcript record, called NewTranscriptRecord, that includes in each row (except the last) the 4-digit program code for the program being studied when the course was studied.

Use the following definition for the new-style transcript tuples:
create type NewTranscriptRecord as (
code char(8), -- UNSW-style course code (e.g. COMP1021) term char(4), -- semester code (e.g. 98s1)
prog char(4), -- program being studied in this semester name text, -- short name of the course's subject
mark integer, -- numeric mark acheived
grade char(2), -- grade code (e.g. FL,UF,PS,CR,DN,HD)
uoc integer -- units of credit awarded for the course
);

Note that this type is already in the database so you won't need to define it. In order to get access to the source code for the transcript() function, use the following command in psql and save the function definition in a local file where you can edit it:
proj2=# \ef transcript(integer)

Q3 (16 marks)
An important part of defining academic rules in MyMyUNSW is the ability to define groups of academic objects (e.g. groups of subjects, streams or programs) In MyMyUNSW, groups can be defined in three different ways:
- enumerated by giving a list of objects in a X_members table
- pattern by giving a pattern that identifies all relevant objects
- query by storing an SQL query which returns a set of object ids

In all cases, the result is a set of academic objects of a particular type

Write a PLpgSQL function Q3(integer) that takes the internal ID of an academic object group and returns the codes for all members of the academic object group. Associated with each code should be the type of the corresponding object, either subject, stream or program. For this question, you only need to consider groups defined via a pattern. If the supplied object group ID refers to
an enumerated or query type group, you may simply return an empty result. You should return distinct codes (i.e. ignore multiple versions of any object), and there is no need to check whether the academic object is still being offered.

The function is defined as follows:
create or replace function Q3(integer) returns setof AcObjRecord 

where AcObjRecord is already defined in the database as follows:
create type AcObjRecord as (
objtype text, -- academic object's type e.g. subject, stream, program 
object text, -- academic object's code e.g. COMP3311, SENGA1, 3978
);

Groups of academic objects are defined in the tables:

- acad_object_groups(id, name, gtype, glogic, gdefby, negated, parent, definition) where the most important fields are:
o gtype ... what kind of objects in the group
o gdefby ... how the group is defined
o definition ... where queries or patterns are given
- program_group_members(program, ao_group) ... for enumerated program groups
- stream_group_members(stream, ao_group) ... for enumerated stream groups
- subject_group_members(subject, ao_group) ... for enumerated subject groups

The ways of specifying object groups are quite flexible, and groups can be defined hierarchically. For this exercise, however, you can ignore groups defined in terms of child groups. You can also ignore negated groups, which would probably result in very large sets of objects. In these cases, simply return an empty result. You can also ignore the glogic field.

There are a wide variety of patterns. You should explore the acad_object_groups table yourself to see what's available. To give you a head start, here are some existing patterns and what they mean:
- COMP2### ... any level 2 computing course (e.g. COMP2911, COMP2041)
- COMP[34]### ... any level 3 or 4 computing course (e.g. COMP3311, COMP4181)
- FREE#### ... any free elective; for this case, simply return the pattern itself**
- GENG#### ... any Gen Ed course; for this case, simply return the pattern itself**
- ####1### ... any level 1 course at UNSW
- (COMP|SENG|BINF)2### ... any level 2 course from CSE
- COMP1917,COMP1927 ... core first year computing courses
- COMP1###,COMP2### ... same as COMP[12]###

Your function should be able to expand any pattern element from the above classes of patterns (i.e. pattern elements that include #, [...] and (...|...)), except for FREE#### and GENG#### as noted.

** Note that there are some variations on the FREE and GEN patterns that should also be treated specially. Any pattern element that begins with "FREE" should be returned unchanged. Similarly for the patterns "GEN#####" and "ZGEN####".

Patterns can be qualified by constraint clauses (e.g. /F=ENG) and alternatives can be specified (e.g. {MATH1131;MATH1141}), but you don't need to be able to handle these. If a
pattern does contain one of these, simply return an empty result.
