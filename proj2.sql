-- COMP9311 15s1 Proj 2


-- Q1: ...

create or replace function Q1(integer) returns text
as $$
	SELECT people.name
	FROM people 
	WHERE people.id = $1 OR people.unswid = $1;
$$ language sql
;

-- Q2: ...

create or replace function Q2(integer)
	returns setof NewTranscriptRecord
as $$
declare
        rec NewTranscriptRecord;
        UOCtotal integer := 0;
        UOCpassed integer := 0;
        wsum integer := 0;
        wam integer := 0;
        x integer;
begin
        select s.id into x
        from   Students s join People p on (s.id = p.id)
        where  p.unswid = $1;
        if (not found) then
                raise EXCEPTION 'Invalid student %',$1;
        end if;
        for rec in
                select distinct su.code,
                         substr(t.year::text,3,2)||lower(t.term),
                         pg.code,
                         substr(su.name,1,20),
                         e.mark, e.grade, su.uoc
                from   People p
                         join Students s on (p.id = s.id)
                         join Course_enrolments e on (e.student = s.id)
                         join Courses c on (c.id = e.course)
                         join Subjects su on (c.subject = su.id)
                         join Semesters t on (c.semester = t.id)
                         join Program_enrolments pge on (pge.student = p.id)
                         join Programs pg on (pg.id = pge.program)
                where  p.unswid = $1
                order  by su.code
        loop
                if (rec.grade = 'SY') then
                        UOCpassed := UOCpassed + rec.uoc;
                elsif (rec.mark is not null) then
                        if (rec.grade in ('PT','PC','PS','CR','DN','HD','A','B','C')) then
                                -- only counts towards creditted UOC
                                -- if they passed the course
                                UOCpassed := UOCpassed + rec.uoc;
                        end if;
                        -- we count fails towards the WAM calculation
                        UOCtotal := UOCtotal + rec.uoc;
                        -- weighted sum based on mark and uoc for course
                        wsum := wsum + (rec.mark * rec.uoc);
                        -- don't give UOC if they failed
                        if (rec.grade not in ('PT','PC','PS','CR','DN','HD','A','B','C')) then
                                rec.uoc := 0;
                        end if;

                end if;
                return next rec;
        end loop;
        if (UOCtotal = 0) then
                rec := (null,null,null,'No WAM available',null,null,null);
        else
                wam := wsum / UOCtotal;
                rec := (null,null,null,'Overall WAM',wam,null,UOCpassed);
        end if;
        -- append the last record containing the WAM
        return next rec;
end;
$$ language plpgsql
;


-- Q3: ...

create or replace function Q3(integer)
	returns setof AcObjRecord
as $$
declare
-- declare properties of variables that will be used later
	rec AcObjRecord;
	obj_type text;
	obj_defby text;
	obj_def text;
        aog_code char(8);
	
begin
-- Select columns from acad_objects_groups into variables declared
	SELECT acad_object_groups.gtype, acad_object_groups.gdefby, acad_object_groups.definition 
	INTO obj_type, obj_defby, obj_def 
	FROM acad_object_groups
	WHERE acad_object_groups.id = $1;

-- Conditional selects from only column of obj_type equals to 'subject', 'stream' or 'program'
    IF obj_type = 'subject' THEN
        FOR aog_code IN
            SELECT DISTINCT su.code
            FROM Subjects su
-- Multiple replace to change the definition column into regex format so it can be matched using POSIX regex ~
            WHERE su.code ~ (SELECT replace(replace(replace(obj_def, '#', '.'), 'x', '.'), ',', '|'))
-- Condition where only those code without ZGEN%, FREE% and GEN% will be selected, otherwise return empty row
		AND su.code NOT LIKE 'ZGEN%' AND su.code NOT LIKE 'FREE%' AND su.code NOT LIKE 'GEN%'
            GROUP BY su.code
            ORDER BY su.code
        LOOP
-- Set records retrieved as format of obj_type followed by aog_code
            rec := (obj_type, aog_code);
            return next rec;
        END LOOP;

    ELSIF obj_type = 'stream' THEN
        FOR aog_code IN
            SELECT DISTINCT st.code
            FROM Streams st
            WHERE st.code ~ (SELECT replace(replace(replace(obj_def, '#', '.'), 'x', '.'), ',', '|'))
            GROUP BY st.code
            ORDER BY st.code
        LOOP
            rec := (obj_type, aog_code);
            return next rec;
        END LOOP;

    ELSE
        FOR aog_code IN
            SELECT DISTINCT pg.code
            FROM Programs pg
            WHERE pg.code ~ (SELECT replace(replace(replace(obj_def, '#', '.'), 'x', '.'), ',', '|'))
            GROUP BY pg.code
            ORDER BY pg.code
        LOOP
            rec := (obj_type, aog_code);
            return next rec;
        END LOOP;
    END IF;
end;
$$ language plpgsql
;
