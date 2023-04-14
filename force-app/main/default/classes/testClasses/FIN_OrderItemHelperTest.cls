@IsTest
private class FIN_OrderItemHelperTest {
    @IsTest
    static void testOrderItemUpdate() {
        try {
            List<FIN_RetroactiveAdjustment__c> oldRetroList = [
                SELECT Id
                FROM FIN_RetroactiveAdjustment__c
            ];
            Id orderRecordTypeId = Schema.SObjectType.FIN_RetroactiveAdjustment__c.getRecordTypeInfosByName().get('Order Product').getRecordTypeId();
            Account acc = TestDataFactory.createAccount();
            Contact cont = TestDataFactory.createContactForAccount(acc.Id, 'test@g.com');
            Product2 pro = TestDataFactory.createProduct2();
            Order ord = TestDataFactory.createTestOrder(acc.Id);
            PricebookEntry standardPriceEntry = TestDataFactory.createPricebookEntry(pro.Id);
            OrderItem orderItem = TestDataFactory.createTestOrderLine(ord.Id, pro.Id, standardPriceEntry.Id);
            
            orderItem.FIN_Amount__c = 120;
            
            update orderItem;

            List<FIN_RetroactiveAdjustment__c> newRetroList = [
                SELECT Id, RecordTypeId
                FROM FIN_RetroactiveAdjustment__c
            ];

           System.assertEquals(oldRetroList.size()+1, newRetroList.size());
           System.assertEquals(newRetroList[0].RecordTypeId, orderRecordTypeId);
        } catch(Exception e) {
            System.debug(e.getMessage());
        }
    }
}