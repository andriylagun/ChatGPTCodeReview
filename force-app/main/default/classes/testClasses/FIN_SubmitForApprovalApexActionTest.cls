@IsTest
private class FIN_SubmitForApprovalApexActionTest {
    @IsTest
    static void testGetAccountNamesOrder() {
        try {
            Account acc = TestDataFactory.createAccount();
            Contract parentContract = TestDataFactory.createParentContract(acc.Id);
            Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);
            Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);

            Test.startTest();
            FIN_SubmitForApprovalApexAction.getAccountNames(new List<String>{ord.Id});
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    @IsTest
    static void testGetAccountNamesContract() {
        try {
            Account acc = TestDataFactory.createAccount();
            Contract cntract = TestDataFactory.createParentContract(acc.Id);

            Test.startTest();
            FIN_SubmitForApprovalApexAction.getAccountNames(new List<String>{cntract.Id});
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
}