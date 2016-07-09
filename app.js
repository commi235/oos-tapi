const Handlebars = require('./lib/handlebars.js');
const path = require('path');
const fs = require('fs');
const extend = require('node.extend');
const {execSync} = require('child_process');


const consoleRed = '\033[31m';


var config = JSON.parse(fs.readFileSync(path.resolve(__dirname + '/config.json'),'utf8'));

// TODO mdsouza: need to use args but for now testing
// TODO mdsouza: Create a sample_config.json
var project = config.projects.giffy;
project = extend(true, {}, config.defaults, project);

project.templateContent = {};


// TODO mdsouza: allow for a custom SQL file to generate the SQL as MTAG has specific needs

// TODO eventually we can get this data from SQLcl
// See poc.sql for query to use
// var tableInfo = {"results":[{"columns":[{"name":"TABLE_NAME","type":"NUMBER"},{"name":"COLUMNS","type":"NUMBER"}],"items":
// [
// {"table_name":"DEMO_ORDERS","columns":[
// {"column_name":"ORDER_ID","data_type":"NUMBER","nullable":"N"},{"column_name":"CUSTOMER_ID","data_type":"NUMBER","nullable":"N"},{"column_name":"ORDER_TOTAL","data_type":"NUMBER","nullable":"Y"},{"column_name":"ORDER_TIMESTAMP","data_type":"TIMESTAMP(6) WITH LOCAL TIME ZONE","nullable":"Y"},{"column_name":"USER_NAME","data_type":"VARCHAR2","nullable":"Y"},{"column_name":"TAGS","data_type":"VARCHAR2","nullable":"Y"}]},{"table_name":"DEMO_ORDER_ITEMS","columns":[
// {"column_name":"ORDER_ITEM_ID","data_type":"NUMBER","nullable":"N"},{"column_name":"ORDER_ID","data_type":"NUMBER","nullable":"N"},{"column_name":"PRODUCT_ID","data_type":"NUMBER","nullable":"N"},{"column_name":"UNIT_PRICE","data_type":"NUMBER","nullable":"N"},{"column_name":"QUANTITY","data_type":"NUMBER","nullable":"N"}]}]}]}
// ;

// Generate SQL friendly list of Table Names
var tablesSql = project.tables.split(',');
tablesSql.forEach(function(curVal, index){
  this[index] = `'${curVal.toUpperCase().trim()}'`
}, tablesSql);

// Need to wrap the table names around some special characters to procduce 'table1','table2', etc
// See http://stackoverflow.com/questions/30489214/double-quote-as-parameter-in-sqlplus
var cmd = `${config.sqlcl} ${project.connectionDetails} @${project.sqlFile} "'${tablesSql.join(',')}'"`;


console.log(cmd);

var stdout = execSync(
  cmd ,
  {
    "pwd": path.resolve(__dirname),
    "encoding": 'utf8'
  });


// This will be the string between START and END
try{
  var tableInfo = /(%%%START%%%)((.|\n)*)(%%%END%%%)/.exec(stdout)[2].trim();
}
catch (e) {
  console.log(`${consoleRed} *** Error parsing SQL ***\n`);
  console.log('Ensure that SQL output is wrapped with %%%START%%% and %%%END%%% ');
  console.log(`\n\n Output: \n\n ${stdout}`);
  process.exit(1);
}


// Convert it to JSON structure
try{
  tableInfo = JSON.parse(tableInfo);
}
catch(e){
  console.log(`${consoleRed} *** Error converting SQL output to JSON ***\n`);
  console.log('Ensure that "set sqlformat json" is set in your SQL file');
  console.log('Ensure that "set verify off" is set in your SQL file');
  console.log(`\n\n Output: \n\n ${tableInfo}`);
  process.exit(1);
}


// Filter to items level
// This will return an array of data
// Each array entry will represent a table.
tableInfo = tableInfo.results[0].items;


// Parse templates and load their content
project.templates.forEach(function(template,i){
  if (/^\.\//.test(template.path)) {
    template.path = template.path.replace(/^\./, __dirname);
  }

  template.content = fs.readFileSync(path.resolve(template.path),'utf8');
  template.handlerbarsObj = Handlebars.compile(template.content);

});


// Update Project Output path
// TODO mdsouza: create function since copied from aboive
if (/^\.\//.test(project.outputPath)) {
  project.outputPath = project.outputPath.replace(/^\./, __dirname);
}


// Loop over each table and then merge with handlebars
tableInfo.forEach(function(myTable){
  myTable.author = project.author;
  myTable.date = 'TODO DD-MON-YYYY';
  myTable.files = []
  // Merge table information with templates
  project.templates.forEach(function(template){
    let fileName = template.outFileName.replace('TABLE_NAME', myTable.table_name.toLowerCase());

    myTable.files[fileName] = template.handlerbarsObj(myTable);;
  }); //project.templates
});


// Output
for (var key in tableInfo){
  myTable = tableInfo[key];

  for (var fileName in myTable.files){
    // Store the merged files on file system
    fs.writeFileSync(path.resolve(project.outputPath, fileName), myTable.files[fileName]);
  }

}