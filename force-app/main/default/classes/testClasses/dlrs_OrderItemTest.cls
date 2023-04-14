/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_OrderItemTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_OrderItemTrigger to be invoked, fails the test if org config or other Apex code prevents this.

        Account acc = TestDataFactory.createAccount();        
        Order ord = TestDataFactory.createTestOrder(acc.Id);

        dlrs.RollupService.testHandler(ord);
    }
}