@IsTest
private class FIN_JournalizingItemHelperTest {
    @TestSetup
    static void prepareData() {
        RecordType record = [
                SELECT Id
                FROM RecordType
                WHERE Name = 'US Payment Distribution'
            ];

            Campaign event = new Campaign(
                Name = 'Test Name'
            );
            insert event;

            FIN_PaymentDistribution__c pd = new FIN_PaymentDistribution__c(
                RecordTypeId = record.Id,
                CurrencyIsoCode = 'USD',
                FIN_Event__c = event.Id,
                FIN_Journalizing_Status__c = 'ToBePosted'
            );
            insert pd;

            Journalizing_Schedule__c js = new Journalizing_Schedule__c(
                FIN_Type__c = 'PDs'
            );
            insert js;
    }

    @IsTest
    static void updateStatusesAfterInsert() {
        FIN_PaymentDistribution__c pd = [
            SELECT Id
            FROM FIN_PaymentDistribution__c
            LIMIT 1
        ];
        Journalizing_Schedule__c js = [
            SELECT Id
            FROM Journalizing_Schedule__c
            LIMIT 1
        ];

        FIN_Journalizing_Item__c ji = new FIN_Journalizing_Item__c(
            FIN_Parent_Journalizing_Schedule__c = js.Id,
            Payment_Distribution__c = pd.Id
        );
        insert ji;

        List<FIN_PaymentDistribution__c> PDList = [
            SELECT Id, RecordTypeId, FIN_Journalizing_Status__c
            FROM FIN_PaymentDistribution__c
        ];

        System.assertEquals(PDList[0].FIN_Journalizing_Status__c, 'InProgress');
    }

    @IsTest
    static void updateStatusesBeforeDelete() {
        FIN_PaymentDistribution__c pd = [
            SELECT Id
            FROM FIN_PaymentDistribution__c
            LIMIT 1
        ];
        Journalizing_Schedule__c js = [
            SELECT Id
            FROM Journalizing_Schedule__c
            LIMIT 1
        ];

        FIN_Journalizing_Item__c ji = new FIN_Journalizing_Item__c(
            FIN_Parent_Journalizing_Schedule__c = js.Id,
            Payment_Distribution__c = pd.Id
        );

        insert ji;
        delete ji;

        List<FIN_PaymentDistribution__c> PDList = [
            SELECT Id, RecordTypeId, FIN_Journalizing_Status__c
            FROM FIN_PaymentDistribution__c
        ];

        System.assertEquals(PDList[0].FIN_Journalizing_Status__c, 'ToBePosted');
    }
}