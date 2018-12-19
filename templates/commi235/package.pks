create or replace package {{toLowerCase table_name}}_pkg
  authid definer
as

  procedure insert_record
  (
  {{#each (arrayFilter columns 'column_name' 'CREATED,CHANGED' 'true')}}
  {{#if @first}} {{/if}}{{#unless @first}},{{~/unless}} pi{{#if @first}}o{{/if}}_{{toLowerCase column_name}} in{{#if @first}} out{{/if}} {{toLowerCase ../table_name}}.{{toLowerCase column_name}}%type{{#unless @last}}{{lineBreak}}{{/unless}}
  {{~/each}} {{! columns }}
  , pi_user in types_pkg.t_user
  );

  procedure update_record
  (
  {{#each (arrayFilter columns 'column_name' 'CREATED,CHANGED' 'true')}}
  {{#if @first}} {{/if}}{{#unless @first}},{{~/unless}} pi_{{toLowerCase column_name}} in {{toLowerCase ../table_name}}.{{toLowerCase column_name}}%type{{#unless @last}}{{lineBreak}}{{/unless}}
  {{~/each}} {{! columns }}
  , pi_user in types_pkg.t_user
  , pi_checksum in types_pkg.t_checksum
  );

  procedure delete_record
  (
  {{#each (arrayFilter columns 'constraint_type' 'P' 'false')}}
  {{#if @first}} {{/if}}{{#unless @first}},{{~/unless}} pi_{{toLowerCase column_name}} in {{toLowerCase ../table_name}}.{{toLowerCase column_name}}%type{{#unless @last}}{{lineBreak}}{{/unless}}
  {{~/each}} {{! columns }}
  , pi_user in types_pkg.t_user
  , pi_checksum in types_pkg.t_checksum
  );

  procedure get_record
  (
  {{#each (arrayFilter columns 'column_name' 'CREATED,CHANGED' 'true')}}
  {{#if @first}} {{/if}}{{#unless @first}},{{~/unless}} {{#ifCond constraint_type '==' 'P' }}pi_{{toLowerCase column_name}} in{{~/ifCond}}{{#ifCond constraint_type '!=' 'P' }}po_{{toLowerCase column_name}} out nocopy{{~/ifCond}} {{toLowerCase ../table_name}}.{{toLowerCase column_name}}%type{{#unless @last}}{{lineBreak}}{{/unless}}
  {{~/each}} {{! columns }}
  , po_checksum out nocopy types_pkg.t_checksum
  );

end {{toLowerCase table_name}}_pkg;
/
