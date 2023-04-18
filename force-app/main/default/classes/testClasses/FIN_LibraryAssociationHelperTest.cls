@IsTest
private class FIN_LibraryAssociationHelperTest {
    @IsTest
    static void testCheckDuplicates() {
        Account acc = TestDataFactory.createAccount();
        Contract parentContract = TestDataFactory.createParentContract(acc.Id);
        Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);

        Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
        Campaign event = new Campaign(Name = 'Test Name');
        insert event;

        Product2 product = TestDataFactory.createProduct2();
        SBQQ__ContractedPrice__c la = TestDataFactory.createLibraryAssociation(acc.Id);
        la.SBQQ__FilterField__c = '';
        la.SBQQ__Product__c = product.Id;
        la.SBQQ__EffectiveDate__c = Date.today() - 2;
        update la;

        la.FIN_ApprovalStatus__c = 'Approved';
        update la;

        SBQQ__ContractedPrice__c la2 = la.clone(false, false, false);

        Boolean exceptionOccurred = false;
        try {
            insert la2;
        } catch (Exception e) {
            exceptionOccurred = true;
        }

        Assert.isTrue(exceptionOccurred, 'An Exception was not thrown');
    }

    //ToDo refactor this
    @IsTest
    static void testLibraryAssociationSelector() {
        Account acc = TestDataFactory.createAccount();
        Contract parentContract = TestDataFactory.createParentContract(acc.Id);
        Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);

        Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
        Campaign event = new Campaign(Name = 'Test Name');
        insert event;

        Product2 product = TestDataFactory.createProduct2();
        SBQQ__ContractedPrice__c la = TestDataFactory.createLibraryAssociation(acc.Id);
        System.assertEquals(0, FIN_LibraryAssociationSelector.getLibraryAssociationsForReclassificationByContextId(la.FIN_Context__c).size());
    }
}