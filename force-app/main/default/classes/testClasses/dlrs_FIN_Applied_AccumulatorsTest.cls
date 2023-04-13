/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_FIN_Applied_AccumulatorsTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_FIN_Applied_AccumulatorsTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new FIN_Applied_Accumulators__c());
    }
}