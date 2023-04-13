/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_FIN_RetroactiveAdjustmentTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_FIN_RetroactiveAdjustmentTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new FIN_RetroactiveAdjustment__c());
    }
}