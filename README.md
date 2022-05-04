# GS | Snowflake - Native - App
Below steps can be taken for replication to create GS 
JAVA native app. 
<br> 
Additionally logging has been added both to the Java Native App as well as the JavaScript native app.

<br />
<u><b>Provided</b></u><br />
2 combiled JAVA files (.Jar)<br />
1 Java file (legend.java)<br />
<br>
SQL code documented below and can run on Snowflake via <b>Copy + Paste</b>
<br>
SQL Code also provided for <b>Producer</b> and <b>Consumer</b> in <b>SQL</b> folder.
<br>
SQL Folder contains <i>_ORIG</i> and <i>_LOG</i> files. <i>_LOG</i> will have logging logic embedded.
<br><br>
SQL Folder also contains <b>decrypt</b> javascript app to be defined on the producer side.



<br /><br /><br />

# Embedded Logging
Logging logic has been embedded into the application. Please do remember that there are a couple of different languages (Java, Javascript & SQL).
<br><br>
Logging, in most cases, is an array object which pushes a JSON event to the array and ultimately returns JSON object.
<br><br>
Ultimately, results are written to a table and shared back to producer from consumer.
<br><br>
On the consumer side new tables are created to hold logging:
```sql
create or replace schema DEMO_DB.LOGS;
create or replace table APP_LOG (evt string);
create or replace table JS_LOG (evt string);
```

## Logging in JAVA NATIVE App
Please reference <b>SQL/producer_LOG.sql</b> for code base.
<br>
Please note you will need to import and use an ArrayList (import java.util.ArrayList).
<br><br>

Logging exampled below:
```java
// Create Array List
static ArrayList<String> log = new ArrayList<String>(); 

// PUSH Log values to array
log.add( "{\"time\" :\" " + (System.currentTimeMillis()) + "\", \"method\": \"" + (method) + "\" , \"class\": \"" + (myclass) + "\" }" );
log.add( "{\"time\" :\" " + (System.currentTimeMillis()) + "\", \"event\": \"step 3\" }" );
log.add( "{\"time\" :\" " + (System.currentTimeMillis()) + "\", \"p1\":\"" + ( p1 ) + "\" }" );

// CREATE JSON to return SQL + Logs to Consumer App
String finalReturn =  "{\"sql\": " + planJson + ", \"log\": " + log.toString() + "}";
return finalReturn;
```
<b style="color:red">Please note that the above is a breaking change to the JAVA Native App code base. SQL and LOG is now a part of a JSON output which will need to handled on the Consumer side.</b>

<br>

## Logging in JavaScript App 
Please reference <b>SQL/consumer.log</b> for code base. This refers to JavaScript wrapper around the Java App. 
<br><br>
Similar to JAVA Native App, JavaScript App also includes an array which has log objects inserted.
```javascript
var log = [];
log.push( {time: Date.now(), event: 'step 1 - init'} );
...
log.push( {time: Date.now(), event: 'step 2 - complete running java code'} );
...
```
<br>
Eventually toward the end of the script the logs will be saved to two tables (<i>APP_LOG</i> & <i>JS_LOG</i>), one more the Native App and one of the JS consumer app.

```javascript
var insertStmt = `insert into DEMO_DB.LOGS.APP_LOG(select '${JSON.stringify(JSON.parse(ResultSet.getColumnValue(1)).log)}')` ;
snowflake.createStatement({sqlText:insertStmt }).execute();

var insertStmt = `insert into DEMO_DB.LOGS.JS_LOG(select '${ JSON.stringify(log) }')` ;
snowflake.createStatement({sqlText:insertStmt }).execute();
```
<br>

# Tables Shared Back to Producer
At this point tables are populated and ready to be shared back to the producer. 

The producer has the option to create a [stream](https://docs.snowflake.com/en/user-guide/streams.html) on shared tables to track DML changes. Permissioning from consumer possibly necessary. 
<br><br>

## Log Examples
<b>Java Native App</b> Log Example
```json
[{"time":" 1651628262838","method":"call","class":"legend"},{"time":" 1651628262867","event":"step 3"},{"time":" 1651628262871","p1":"MyParameter"},{"time":" 1651628262926","event":"step 3"},{"time":" 1651628263374","event":"step 3"},{"time":" 1651628263375","event":"final step"},{"time":" 1651628263375","sql":"Legend SQL Goes Here - Test App (SQL THIS FROM TABLE WHERE VALUE > 1)"}]
```
<br> 
<b>Wrapper JavaScript App</b> Log Example

```json
[{"time":1651628261651,"event":"step 1 - init"},{"time":1651628263512,"event":"step 2 - complete running java code"},{"time":1651628263512,"event":"step 3 - got legend query"},{"time":1651628263512,"event":"step - 4 - replaced legend query"},{"time":1651628263512,"event":"step 5 - almost done"},{"time":1651628263563,"acct":"SFSENORTHAMERICA_MARIUS"},{"time":1651628263563,"finalQuery":"select listagg(object_construct(*)::varchar, ') from (select cp.isin,cp.EARNINGS_PER_SHARE, smq."Marturity Date",smq."Sector" from DEMO_DB.DEVELOPMENT_TEST.CUSTOMER_PORTFOLIO cp join ("select \"root\".NAME as \"Name\", \"root\".FIRMID as \"FirmId\" from PERSON as \"root\"") smq on cp.ISIN = smq."Isin")"}]
```

<br>

## Encryption & Decryption of Logs

Logs can be encrypted prior to being writen to consumer LOG tables. Possible encryption methods outlined below.

<b>Decrypt</b>

```javascript
create or replace procedure SUMMIT_LEGEND_APP.APP_SCHEMA.DECRYPT(SALT varchar, ENCODED varchar  )
RETURNS STRING
LANGUAGE JAVASCRIPT
EXECUTE AS OWNER
AS $$
{
const textToChars = (text) => text.split("").map((c) => c.charCodeAt(0));
const applySaltToChar = (code) => textToChars(SALT).reduce((a, b) => a ^ b, code);
return ENCODED
    .match(/.{1,2}/g)
    .map((hex) => parseInt(hex, 16))
    .map(applySaltToChar)
    .map((charCode) => String.fromCharCode(charCode))
    .join("");
}
$$;
```

<b>Encrypt></b>

```javascript
const crypt = (salt, text) => {
    const textToChars = (text) => text.split("").map((c) => c.charCodeAt(0));
    const byteHex = (n) => ("0" + Number(n).toString(16)).substr(-2);
    const applySaltToChar = (code) => textToChars(salt).reduce((a, b) => a ^ b, code);

return text
    .split("")
    .map(textToChars)
    .map(applySaltToChar)
    .map(byteHex)
    .join("");
};
```



<br><br><br>
# Run Locally on Mac
You can run the test locally with the code below (Will need java installed and probably a bunch of other stuff). 
<br />
```
java -cp GS.jar:legend.jar legend.java
```
Output should be <b>result.json</b> file provided (or similar)

<br>

<b>Java Body</b>  - Unsure what majority of the below <i>really</i> does.
<br />

```java
public class legend{

    public static void main(String[] args) throws Exception{
        System.out.println("HELLO!");
        URL url = persons.class.getResource("/plans/org/finos/legend/showcase/showcase2/service/persons.json");
        BufferedReader reader1 = new BufferedReader(new InputStreamReader(url.openStream(), StandardCharsets.UTF_8));
        String planJson = reader1.lines().collect(Collectors.joining("\n"));

        BufferedReader reader2 = new BufferedReader(new InputStreamReader(url.openStream(), StandardCharsets.UTF_8));
        ExecutionPlan executionPlan = PlanExecutor.readExecutionPlan(reader2);
        SingleExecutionPlan singleExecutionPlan = executionPlan.getSingleExecutionPlan(new HashMap<>());
        SQLExecutionNode sqlExecutionNode = (SQLExecutionNode)singleExecutionPlan.rootExecutionNode.executionNodes.get(0);

        System.out.println(planJson);
    }
}
```
<br /><br />


# PUT JARs - Snowflake Stage
Provided are two required combiled JAVA files (.jar) to create the Snowflake Native App. 
<br />

## Upload Provided JARs to Stage

Upload legend.jar
```cli
put file://.../legend.jar  @...JARSTAGE auto_compress=false;
```
<br />

Upload GS.jar
```cli
put file://.../GS.jar  @...JARSTAGE auto_compress=false;
```

<!-- ![Profiler](https://github.com/mariusndini/gS-Native-App/blob/main/images/profiler.png) -->

<br />

# Creating Function in Snowflake
After the Jars have been uploaded the following will create the Snowflake Java UDF.
<br />

```java
create or replace function demo_db.public.legendGS2()
returns String
language java
imports = ('@...jarstage/GS.jar', '@...jarstage/legend.jar')
handler='legend.call'
target_path='@~/legendGS2.jar'
as
$$
    import org.finos.legend.engine.plan.execution.PlanExecutor;
    import org.finos.legend.engine.protocol.pure.v1.model.executionPlan.ExecutionPlan;
    import org.finos.legend.engine.protocol.pure.v1.model.executionPlan.SingleExecutionPlan;
    import org.finos.legend.engine.protocol.pure.v1.model.executionPlan.nodes.ExecutionNode;
    import org.finos.legend.engine.protocol.pure.v1.model.executionPlan.nodes.SQLExecutionNode;
    import org.finos.legend.showcase.showcase2.service.persons;

    import java.io.BufferedReader;
    import java.io.InputStreamReader;
    import java.net.URL;
    import java.nio.charset.StandardCharsets;
    import java.util.HashMap;
    import java.util.stream.Collectors;

    class legend {
        public static String call() throws Exception {
          URL url = persons.class.getResource("/plans/org/finos/legend/showcase/showcase2/service/persons.json");
          BufferedReader reader1 = new BufferedReader(new InputStreamReader(url.openStream(), StandardCharsets.UTF_8));
          String planJson = reader1.lines().collect(Collectors.joining("\n"));

          BufferedReader reader2 = new BufferedReader(new InputStreamReader(url.openStream(), StandardCharsets.UTF_8));
          ExecutionPlan executionPlan = PlanExecutor.readExecutionPlan(reader2);
          SingleExecutionPlan singleExecutionPlan = executionPlan.getSingleExecutionPlan(new HashMap<>());
          SQLExecutionNode sqlExecutionNode = (SQLExecutionNode)singleExecutionPlan.rootExecutionNode.executionNodes.get(0);

          return planJson;
        }
    }
$$;
```
<br />

## Calling Function

```sql
select legendGS2();
```

### Call Function > Parse JSON > Get sqlQuery
```sql
select PARSE_JSON(legendGS2()::variant):rootExecutionNode.executionNodes[0].sqlQuery;
```

### Output Below
``` sql
"select \"root\".NAME as \"Name\", \"root\".FIRMID as \"FirmId\" from PERSON as \"root\""

```
<br />

## Creating JavaScript Stored Procedure

```javascript
create or replace procedure SUMMIT_LEGEND_APP.APP_SCHEMA.SECURITY_MASTER_APP(MYJAVAUDFPATH varchar, JOINEDSQLSTMT varchar  )
RETURNS STRING
LANGUAGE JAVASCRIPT
EXECUTE AS OWNER
AS $$
{
    var javaSQLQuery = `SELECT PARSE_JSON( ${MYJAVAUDFPATH}()::variant):rootExecutionNode.executionNodes[0].sqlQuery`;
    var ResultSet = snowflake.createStatement({sqlText: javaSQLQuery }).execute();
    var row = ResultSet.next();
    var legendQuery = ResultSet.getColumnValue(1);

    var legend_search_str = "{legend(security_master_app)}";
    var intermediateQuery = JOINEDSQLSTMT.replace(legend_search_str, "(" + legendQuery + ")");
    var finalQuery = "select listagg(object_construct(*)::varchar, '\n') from (" + intermediateQuery + ")";
//    var ResultSet2 = (snowflake.createStatement({sqlText: finalQuery})).execute();
//    var row2 = ResultSet2.next();
//    var returnValue = ResultSet2.getColumnValue(1);
    return finalQuery;

}
$$;
```

<br />

## Calling JS S.Proc
```sql
call SUMMIT_LEGEND_APP.APP_SCHEMA.SECURITY_MASTER_APP( 'demo_db.public.legendGS2','select cp.isin,cp.EARNINGS_PER_SHARE, smq."Marturity Date",smq."Sector" from DEMO_DB.DEVELOPMENT_TEST.CUSTOMER_PORTFOLIO cp join {legend(security_master_app)} smq on cp.ISIN = smq."Isin"');
```



## Resultant Output SQL

```sql
select listagg(object_construct(*)::varchar, '') from (select cp.isin,cp.EARNINGS_PER_SHARE, smq."Marturity Date",smq."Sector" from DEMO_DB.DEVELOPMENT_TEST.CUSTOMER_PORTFOLIO cp join (select "root".NAME as "Name", "root".FIRMID as "FirmId" from PERSON as "root") smq on cp.ISIN = smq."Isin")
```

#### Input SQL (for reference)
```sql
'select cp.isin,cp.EARNINGS_PER_SHARE, smq."Marturity Date",smq."Sector" from DEMO_DB.DEVELOPMENT_TEST.CUSTOMER_PORTFOLIO cp join {legend(security_master_app)} smq on cp.ISIN = smq."Isin"
```






<br><br><br><br><br>

# MISC 
Misc Steps during creation process


## Building Legend.jar
The legend.jar is generated w/ the following MAVIN command and can be downloaded here (https://github.com/finos/legend/tree/service-exec-jar-example/examples/service-execution-jar/legend-application).

    MVN install 

Thereafter --> A target folder will be created --> in there will be two JAR files. Mine was named: legend-application-0.0.1-SNAPSHOT-shaded.jar

Rename this file to <b>legend.jar</b> --> Provided

<b>You can now upload this file to Snowflake to create Native App</b>







