drop procedure SUMMIT_LEGEND_APP.APP_SCHEMA.SECURITY_MASTER_APP(varchar, varchar);

create or replace procedure SUMMIT_LEGEND_APP.APP_SCHEMA.SECURITY_MASTER_APP(MYJAVAUDFPATH varchar, JOINEDSQLSTMT varchar  )

RETURNS STRING

LANGUAGE JAVASCRIPT

EXECUTE AS OWNER

AS $$

{

    var ResultSet = (snowflake.createStatement({sqlText:' select ' + MYJAVAUDFPATH + '();'})).execute();

    var row = ResultSet.next();

    var legendQuery = ResultSet.getColumnValue(1);

    var legend_search_str = "{legend(security_master_app)}";

    var intermediateQuery = JOINEDSQLSTMT.replace(legend_search_str, "(" + legendQuery + ")");

    var finalQuery = "select listagg(object_construct(*)::varchar, '\n') from (" + intermediateQuery + ")";

    var ResultSet2 = (snowflake.createStatement({sqlText: finalQuery})).execute();

    var row2 = ResultSet2.next();

    var returnValue = ResultSet2.getColumnValue(1);

    return returnValue;

}

$$;

 


create or replace procedure SUMMIT_LEGEND_APP.APP_SCHEMA.SECURITY_MASTER_APP(MYJAVAUDFPATH varchar, JOINEDSQLSTMT varchar, STAGINGTABLE varchar, PRODUCTSYNONYM varchar  )

RETURNS STRING

LANGUAGE JAVASCRIPT

EXECUTE AS OWNER

AS $$

{

    var returnValue = '';

    var ResultSet = (snowflake.createStatement({sqlText:' select ' + MYJAVAUDFPATH + '(\''+ PRODUCTSYNONYM + '\');'})).execute();

    var row = ResultSet.next();

    var legendQuery = ResultSet.getColumnValue(1);

    var legend_search_str = "{legend(security_master_app)}";

    var intermediateQuery = JOINEDSQLSTMT.replace(legend_search_str, "(" + legendQuery + ")");

    var finalQuery = "select listagg(object_construct(*)::varchar, '\n') from (" + intermediateQuery + ")";

    if( STAGINGTABLE == null ) {

    var ResultSet2 = (snowflake.createStatement({sqlText: finalQuery})).execute();

    var row2 = ResultSet2.next();

    returnValue = ResultSet2.getColumnValue(1);

    }

    else

    {

            var query = 'INSERT INTO ' +  STAGINGTABLE + ' ' + finalQuery;

            var ResultSet3 = (snowflake.createStatement({sqlText: query})).execute();

           

    }

       

    return returnValue;

}

$$;

 

use role SUMMIT_APP_OWNER;

Create database role shared_db_role;

grant usage on procedure SUMMIT_LEGEND_APP.APP_SCHEMA.SECURITY_MASTER_APP(VARCHAR, VARCHAR, VARCHAR, VARCHAR) to database role shared_db_role;