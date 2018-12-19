set sqlformat json
set feedback off
set serveroutput on
set verify off

exec dbms_output.put_line('%%%START%%%');

with uc as
(
    select uc.table_name
         , ucc.column_name
         , ucc.position
         , uc.constraint_type
    from user_constraints uc
    join user_cons_columns ucc
      on ucc.constraint_name = uc.constraint_name
   where uc.constraint_type = 'P'
), ut as
(
  select ut.table_name
       , ( select substr(utc.column_name, 1, instr(utc.column_name, '_') - 1)
             from user_tab_cols utc
            where utc.table_name = ut.table_name
              and utc.column_id = 1
         ) as table_abbreviation
    from user_tables ut
)
select ut.table_name
     , ut.table_abbreviation
     , ( select us.sequence_name from user_sequences us where substr(us.sequence_name, 1, instr(us.sequence_name, '_') -1) = ut.table_abbreviation ) as table_sequence
     , cursor( select utc.column_name
                    , utc.data_type
                    , utc.nullable
                    , coalesce(uc.constraint_type, 'N/A') as constraint_type
                    , case when utc.data_type = 'VARCHAR2' then to_char(utc.char_length )
                           when utc.data_type = 'NUMBER' and (utc.data_precision is not null or utc.data_scale is not null)
                              then to_char(case when utc.data_precision is null then 0 else utc.data_precision end) || ',' || to_char(case when utc.data_scale is null then 0 else utc.data_scale end)
                           when utc.data_type like 'TIMESTAMP%' then null
                           else '0' end 
                      as data_length
                    , coalesce(ucc.comments, 'N/A') as comments
                 from user_tab_cols utc
            left join user_col_comments ucc
                   on ucc.table_name  = utc.table_name
                  and ucc.column_name = utc.column_name
            left join uc
                   on uc.table_name  = utc.table_name
                  and uc.column_name = utc.column_name
                where 1=1
                  and utc.table_name = ut.table_name
             order by uc.position nulls last
                    , utc.column_id
             ) columns
  from ut
 where 1=1
   and ut.table_name in (&1)
;

exec dbms_output.put_line('%%%END%%%');
