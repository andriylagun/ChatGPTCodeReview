@IsTest
private class CustomLookupControllerTest {
    @IsTest
    public static void testFetchLookupData() {
        Account acc = TestDataFactory.createAccount();
        Contract parentContract = TestDataFactory.createParentContract(acc.Id);
        Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);
        Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
        List<Order> testord = [
            SELECT Id, OrderNumber
            FROM Order
        ];
        System.debug('testord'+testord);
        List<Order> sales = (List<Order>) CustomLookupController.fetchLookupData('0', 'Order', 'OrderNumber', contract.Id);

        Assert.areEqual(1, sales.size());
    }

    @IsTest
    public static void testFetchDefaultRecord() {
        Account acc = TestDataFactory.createAccount();
        Contract parentContract = TestDataFactory.createParentContract(acc.Id);
        Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);
        Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);

        Order sales = (Order)CustomLookupController.fetchDefaultRecord(ord.Id,'Order','OrderNumber');

        Assert.areNotEqual(null,sales);
    }
}