@IsTest
private class FIN_OrderHelperTest {
    @IsTest
    static void testOrderSharing() {
        List<User> users = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 3];

        Account acc = TestDataFactory.createAccount();
        Order ord = TestDataFactory.createTestOrder(acc.Id);
        ord.FIN_Region__c = 'US';
        update ord;

        Group grp = [
            SELECT Id
            FROM Group
            WHERE Name =: 'US Region'
            LIMIT 1
        ];

        List<OrderShare> oShrs = [
            SELECT Id, UserOrGroupId, OrderAccessLevel, RowCause 
            FROM OrderShare 
            WHERE OrderId = :ord.Id 
            AND UserOrGroupId= :grp.Id
        ];

//        System.assertEquals(oShrs.size(), 1);
//        System.assertEquals(oShrs[0].OrderAccessLevel, 'Read');
//        System.assertEquals(oShrs[0].RowCause, 'Manual');
//        System.assertEquals(oShrs[0].UserOrGroupId, grp.Id);
    }  

    @IsTest
    static void testOrderUpdate() {
        try {
            List<FIN_RetroactiveAdjustment__c> oldRetroList = [
                SELECT Id
                FROM FIN_RetroactiveAdjustment__c
            ];
            Id orderRecordTypeId = Schema.SObjectType.FIN_RetroactiveAdjustment__c.getRecordTypeInfosByName().get('Order').getRecordTypeId();
            Account acc = TestDataFactory.createAccount();
            Contact cont = TestDataFactory.createContactForAccount(acc.Id, 'test@g.com');
            Product2 pro = TestDataFactory.createProduct2();
            PricebookEntry standardPriceEntry = TestDataFactory.createPricebookEntry(pro.Id);
            Order ord = TestDataFactory.createTestOrder(acc.Id);

            Test.startTest();
            ord.Adjustment_Amount__c = 10;
            update ord;
            List<FIN_RetroactiveAdjustment__c> newRetroList = [
                SELECT Id, RecordTypeId
                FROM FIN_RetroactiveAdjustment__c
            ];
            Test.stopTest();

            System.assertEquals(oldRetroList.size()+1, newRetroList.size());
            System.assertEquals(newRetroList[0].RecordTypeId, orderRecordTypeId);
        } catch(Exception e) {
            System.debug(e.getMessage());
        }
    }
}