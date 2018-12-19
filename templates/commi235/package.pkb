create or replace package body {{toLowerCase table_name}}_pkg
as

  function get_db_checksum
  (
    pi_{{toLowerCase table_abbreviation}}_id in {{toLowerCase table_name}}.{{toLowerCase table_abbreviation}}_id%type
  )
    return types_pkg.t_checksum
  as
    l_return types_pkg.t_checksum;
  begin
    select to_char({{toLowerCase table_abbreviation}}_changed_on, global_constants_pkg.gc_date_checksum_fmt)
      into l_return
      from {{toLowerCase table_name}}
     where {{toLowerCase table_abbreviation}}_id = pi_{{toLowerCase table_abbreviation}}_id
    ;
    return l_return;
  end get_db_checksum;

  procedure insert_record
  (
  {{#each (arrayFilter columns 'column_name' 'CREATED,CHANGED' 'true')}}
  {{#if @first}} {{/if}}{{#unless @first}},{{~/unless}} pi{{#if @first}}o{{/if}}_{{toLowerCase column_name}} in{{#if @first}} out{{/if}} {{toLowerCase ../table_name}}.{{toLowerCase column_name}}%type{{#unless @last}}{{lineBreak}}{{/unless}}
  {{~/each}} {{! columns }}
  , pi_user in types_pkg.t_user
  )
  as
  begin
    insert
      into {{toLowerCase table_name}}
           ({{#each (arrayFilter columns 'column_name' 'CREATED,CHANGED' 'true')}}
           {{#if @first}} {{/if}}{{#unless @first}},{{~/unless}} {{toLowerCase column_name}}{{#unless @last}}{{linebreak}}{{~/unless}}{{~/each}}
           , {{toLowerCase table_abbreviation}}_created_by
           , {{toLowerCase table_abbreviation}}_changed_by
           )
    values ({{#each (arrayFilter columns 'column_name' 'CREATED,CHANGED' 'true')}}
           {{#if @first}}  pio_{{/if}}{{#unless @first}}, pi_{{~/unless}}{{toLowerCase column_name}}{{#unless @last}}{{linebreak}}{{~/unless}}{{~/each}}
           , pi_user
           , pi_user
           )
    returning {{toLowerCase table_abbreviation}}_id into pio_{{toLowerCase table_abbreviation}}_id
    ;
  end insert_record;

  procedure update_record
  (
  {{#each (arrayFilter columns 'column_name' 'CREATED,CHANGED' 'true')}}
  {{#if @first}} {{/if}}{{#unless @first}},{{~/unless}} pi_{{toLowerCase column_name}} in {{toLowerCase ../table_name}}.{{toLowerCase column_name}}%type{{#unless @last}}{{lineBreak}}{{/unless}}
  {{~/each}} {{! columns }}
  , pi_user in types_pkg.t_user
  , pi_checksum in types_pkg.t_checksum
  )
  as
  begin
    if pi_checksum = get_db_checksum(pi_{{toLowerCase table_abbreviation}}_id => pi_{{toLowerCase table_abbreviation}}_id) then
      update {{toLowerCase table_name}}
         set{{#each (arrayFilter (arrayFilter columns 'column_name' 'CREATED,CHANGED' 'true') 'constraint_type' 'P' 'true')}}{{#unless @first}}           ,{{~/unless}} {{toLowerCase column_name}} = pi_{{toLowerCase column_name}}{{#unless @last}}{{lineBreak}}{{~/unless}}{{~/each}}
           , {{toLowerCase table_abbreviation}}_changed_by = pi_user
           , {{toLowerCase table_abbreviation}}_changed_on = sysdate
       where {{toLowerCase table_abbreviation}}_id = pi_{{toLowerCase table_abbreviation}}_id
      ;
    else
      raise global_constants_pkg.e_checksum_mismatch;
    end if;
  end update_record;

  procedure delete_record
  (
  {{#each (arrayFilter columns 'constraint_type' 'P' 'false')}}
  {{#if @first}} {{/if}}{{#unless @first}},{{~/unless}} pi_{{toLowerCase column_name}} in {{toLowerCase ../table_name}}.{{toLowerCase column_name}}%type{{#unless @last}}{{lineBreak}}{{/unless}}
  {{~/each}} {{! columns }}
  , pi_user in types_pkg.t_user
  , pi_checksum in types_pkg.t_checksum
  )
  as
  begin
    if pi_checksum = get_db_checksum(pi_{{toLowerCase table_abbreviation}}_id => pi_{{toLowerCase table_abbreviation}}_id) then
      delete
        from {{toLowerCase table_name}}
       where {{toLowerCase table_abbreviation}}_id = pi_{{toLowerCase table_abbreviation}}_id
      ;
    else
      raise global_constants_pkg.e_checksum_mismatch;
    end if;
  end delete_record;

  procedure get_record
  (
  {{#each (arrayFilter columns 'column_name' 'CREATED,CHANGED' 'true')}}
  {{#if @first}} {{/if}}{{#unless @first}},{{~/unless}} {{#ifCond constraint_type '==' 'P' }}pi_{{toLowerCase column_name}} in{{~/ifCond}}{{#ifCond constraint_type '!=' 'P' }}po_{{toLowerCase column_name}} out nocopy{{~/ifCond}} {{toLowerCase ../table_name}}.{{toLowerCase column_name}}%type{{#unless @last}}{{lineBreak}}{{/unless}}
  {{~/each}} {{! columns }}
  , po_checksum out nocopy types_pkg.t_checksum
  )
  as
  begin
    select{{#each (arrayFilter columns 'column_name' 'CREATED,CHANGED_BY' 'true')}}{{#unless @first}} {{#ifCond column_name '~=' 'CHANGED_ON'}}to_char({{~/ifCond}}{{toLowerCase column_name}}{{#ifCond column_name '~=' 'CHANGED_ON'}}, global_constants_pkg.gc_date_checksum_fmt){{~/ifCond}}{{#unless @last}}{{lineBreak}}         ,{{~/unless}}{{~/unless}}{{~/each}}
      into{{#each (arrayFilter columns 'column_name' 'CREATED,CHANGED_BY' 'true')}}{{#unless @first}} {{#ifCond column_name '~=' 'CHANGED_ON'}}po_checksum{{~/ifCond}}{{#ifCond column_name '!~=' 'CHANGED_ON'}}po_{{toLowerCase column_name}}{{~/ifCond}}{{#unless @last}}{{lineBreak}}         ,{{~/unless}}{{~/unless}}{{~/each}}
      from {{toLowerCase table_name}}
     where 1=1
       and {{#each columns}}{{#ifCond constraint_type '==' 'P'}}{{toLowerCase column_name}} = pi_{{toLowerCase column_name}}{{linebreak}}{{~/ifCond}}{{~/each}}
    ;
  end get_record;

end {{toLowerCase table_name}}_pkg;
/
