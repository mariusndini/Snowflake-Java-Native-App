create or replace function demo_db.public.GSLegends(p1 String)
returns String // MAKE THIS AN ARRAY - WE ARE LOOKING TO RETURN TWO STRINGS (SQL FUNCTION, LOG)
language java
imports = ('@demo_db.public.jarstage/GS.jar', '@demo_db.public.jarstage/legend.jar')
handler='legend.call'
target_path='@~/GSLegends4.jar'
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
   
    import java.util.ArrayList; // IMPORT ARRAYLIST CLASS
    import org.apache.commons.codec.binary.Base64; // CIPHER IMPORT FOR ENCRYPTION

    class legend {
        static ArrayList<String> log = new ArrayList<String>(); 

        
        public static String call(String p1) throws Exception {
        
          String method = Thread.currentThread().getStackTrace()[1].getMethodName();
          String myclass = Thread.currentThread().getStackTrace()[1].getClassName();
          
          log.add( "{\"time\" :\" " + (System.currentTimeMillis()) + "\", \"method\": \"" + (method) + "\" , \"class\": \"" + (myclass) + "\" }" );
          log.add( "{\"time\" :\" " + (System.currentTimeMillis()) + "\", \"event\": \"step 3\" }" );
          log.add( "{\"time\" :\" " + (System.currentTimeMillis()) + "\", \"p1\":\"" + ( p1 ) + "\" }" );

        
        
          URL url = persons.class.getResource("/plans/org/finos/legend/showcase/showcase2/service/persons.json");
          BufferedReader reader1 = new BufferedReader(new InputStreamReader(url.openStream(), StandardCharsets.UTF_8));
          String planJson = reader1.lines().collect(Collectors.joining("\n"));
          
          log.add( "{\"time\" :\" " + (System.currentTimeMillis()) + "\", \"event\": \"step 3\" }" );

          BufferedReader reader2 = new BufferedReader(new InputStreamReader(url.openStream(), StandardCharsets.UTF_8));
          ExecutionPlan executionPlan = PlanExecutor.readExecutionPlan(reader2);
          SingleExecutionPlan singleExecutionPlan = executionPlan.getSingleExecutionPlan(new HashMap<>());
          SQLExecutionNode sqlExecutionNode = (SQLExecutionNode)singleExecutionPlan.rootExecutionNode.executionNodes.get(0);

          log.add( "{\"time\" :\" " + (System.currentTimeMillis()) + "\", \"event\": \"step 3\" }" );

          // Here we concat log + return json
          log.add( "{\"time\" :\" " + (System.currentTimeMillis()) + "\", \"event\": \"final step\" }" );

          log.add( "{\"time\" :\" " + (System.currentTimeMillis()) + "\", \"sql\":\"" + ( "Legend SQL Goes Here - Test App Cannot Parse and returns full JSON (SQL THIS FROM TABLE WHERE VALUE > 1)" ) + "\" }" );
          
          // CONCAT two strings together to return
          String finalReturn =  "{\"sql\": " + planJson + ", \"log\": " + log.toString() + "}";
          return finalReturn;
          
        }
        
        
  }
$$;


select 
    PARSE_JSON(demo_db.public.GSLegends('p1')):log as LOG, 
    PARSE_JSON(demo_db.public.GSLegends('p1')::variant):sql.rootExecutionNode.executionNodes[0].sqlQuery::string as SQL;

select demo_db.public.GSLegends('p1');