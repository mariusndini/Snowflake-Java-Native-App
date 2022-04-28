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