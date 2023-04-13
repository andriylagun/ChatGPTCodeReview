/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_ContractTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_ContractTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        Account acc = TestDataFactory.createAccount();

        Contract parentContract = TestDataFactory.createParentContract(acc.Id);
        Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);
        
        dlrs.RollupService.testHandler(contract);
    }
}