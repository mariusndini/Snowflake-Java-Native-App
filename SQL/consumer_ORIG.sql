create or replace function SUMMIT_APP_LOCAL.UDF_HOUSE.LEGEND_EXECUTABLE_JAR(CUSIP VARCHAR)

returns string

language JAVA

imports = ('@"DEMO_DB"."DEVELOPMENT_TEST"."SUMMIT_LEGEND_S3_STAGE_QA"/H:/snowflake-native-app/summit-legend-app-service-execution-0.3.0-shaded.jar', '@"DEMO_DB"."DEVELOPMENT_TEST"."SUMMIT_LEGEND_S3_STAGE_QA"/H:/snowflake-native-app/summit-legend-udfv2.jar')

handler = 'LegendSnowflakeSummitAppV2.call'

;

 

select SUMMIT_APP_LOCAL.UDF_HOUSE.LEGEND_EXECUTABLE_JAR('EF1858341');

 

use role SUMMIT_APP_CONSUMER;

call SUMMIT_LEGEND_APP.APP_SCHEMA.SECURITY_MASTER_APP( 'SUMMIT_APP_LOCAL.UDF_HOUSE.LEGEND_EXECUTABLE_JAR','select cp.isin,cp.EARNINGS_PER_SHARE, smq."Marturity Date",smq."Sector" from DEMO_DB.DEVELOPMENT_TEST.CUSTOMER_PORTFOLIO cp join {legend(security_master_app)} smq on cp.ISIN = smq."Isin"','SUMMIT_APP_LOCAL.GSFINCLOUD_SCHEMA.STAGINGTABLE','EJ6763068');

 