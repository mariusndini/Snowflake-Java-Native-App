# GS | Snowflake - Native - App
Below steps can be taken for replication to create GS 
JAVA native app.

<br />
<u><b>Provided</b></u><br />
2 combiled JAVA files (.Jar)<br />
1 Java file (legend.java)<br />
<br>
SQL code documented below and can run on Snowflake via <b>Copy + Paste</b>

<br /><br /><br />

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







