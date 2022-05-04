//CREATE DATABASE LOG
create or replace schema DEMO_DB.LOGS;
create or replace table APP_LOG (evt string);
create or replace table JS_LOG (evt string);



// ********************************************
// ************** CONSUMER
// create procedure to use JAVA NATIVE APP
// INPUT PATH - SQL STATEMENT

create or replace procedure SUMMIT_LEGEND_APP.APP_SCHEMA.SECURITY_MASTER_APP(MYJAVAUDFPATH varchar, JOINEDSQLSTMT varchar  )
RETURNS STRING
LANGUAGE JAVASCRIPT
EXECUTE AS OWNER
AS $$
{
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

    var log = [];
    
    log.push( {time: Date.now(), event: 'step 1 - init'} );

    var ResultSet = (snowflake.createStatement({sqlText:' select ' + MYJAVAUDFPATH + '(\'MyParameter\');'})).execute();
    var row = ResultSet.next();

    log.push( {time: Date.now(), event: 'step 2 - complete running java code'} );
    
    // LEGENQUERY RESULT HAS CHANGED - Previous SQL string now is array which contains SQL string + Log
    var legendQuery = JSON.stringify(JSON.parse(ResultSet.getColumnValue(1)).sql.rootExecutionNode.executionNodes[0].sqlQuery);
      
    log.push( {time: Date.now(), event: 'step 3 - got legend query'} );
        
    // largely unchanged
    var legend_search_str = "{legend(security_master_app)}";
    var intermediateQuery = JOINEDSQLSTMT.replace(legend_search_str, "(" + legendQuery + ")");
    
    log.push( {time: Date.now(), event: 'step - 4 - replaced legend query'} );
    
    var finalQuery = "select listagg(object_construct(*)::varchar, '\n') from (" + intermediateQuery + ")";

    log.push( {time: Date.now(), event: 'step 5 - almost done'} );

    // get snowflake acccount - may or may not be runable from shared app
    var acct = snowflake.createStatement({sqlText: `select current_account();` }).execute();
    acct.next();
    log.push( {time: Date.now(), acct: acct.getColumnValue(1) } );

    log.push( {time: Date.now(), finalQuery: (finalQuery.replace(/(\r\n|\n|\r)/gm, "")) } );


    //WRITE LOG TO LOGS TABLE
    var insertStmt = `insert into DEMO_DB.LOGS.APP_LOG(select '${JSON.stringify(JSON.parse(ResultSet.getColumnValue(1)).log)}')` ;
    snowflake.createStatement({sqlText:insertStmt }).execute();

    var insertStmt = `insert into DEMO_DB.LOGS.JS_LOG(select '${ JSON.stringify(log) }')` ;
    snowflake.createStatement({sqlText:insertStmt }).execute();

    //finaly return result
    return crypt("test", finalQuery);


//    var ResultSet2 = (snowflake.createStatement({sqlText: finalQuery})).execute();
//    var row2 = ResultSet2.next();
//    var returnValue = ResultSet2.getColumnValue(1);
//    return JSON.stringify(JSON.parse(ResultSet.getColumnValue(1)).log);

}

$$;