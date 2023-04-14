@isTest
private class Fin_ContractExtControllerTests {

    @IsTest
    static void testSubmit() {
        RecordType record = [SELECT Id FROM RecordType WHERE Name = 'US Master Contract'];
        Account acc = new Account(Name = 'test acc');
        insert acc;
        FIN_Context__c context = new FIN_Context__c(
            FIN_StartDate__c = Date.today() - 1
        );
        insert context;

        Id finRecordTypeId = Schema.SObjectType.FIN_Standardization__c.getRecordTypeInfosByName().get('Financial Standard').getRecordTypeId();
        FIN_Standardization__c standardizationFin = new FIN_Standardization__c(
            Name = 'standardizationFin',
            RecordTypeId = finRecordTypeId
        );
        insert standardizationFin;

        Id statRecordTypeId = Schema.SObjectType.FIN_Standardization__c.getRecordTypeInfosByName().get('Statistical Standard').getRecordTypeId();
        FIN_Standardization__c standardizationStat = new FIN_Standardization__c(
            Name = 'standardizationStat',
            RecordTypeId = statRecordTypeId
        );
        insert standardizationStat;

        Contract Contract = new Contract();
        Contract.RecordTypeId = record.Id;
        Contract.CurrencyIsoCode = 'USD';
        Contract.AccountId = acc.Id;
        Contract.FIN_Context__c = context.Id;
        Contract.FIN_Financial_Standard__c = standardizationFin.Id;
        Contract.FIN_Statistical_Standard__c = standardizationStat.Id;
        insert Contract;

        Test.startTest();
        Fin_ContractExtController con = new Fin_ContractExtController(new ApexPages.StandardController(Contract));
        con.onSubmit();
        Contract = [SELECT ApprovalStatus__c FROM Contract WHERE Id = :Contract.Id LIMIT 1];
        Test.stopTest();

        System.assertEquals('Approved', Contract.ApprovalStatus__c);
    }

    @IsTest
    static void testRecall() {
        RecordType record = [SELECT Id FROM RecordType WHERE Name = 'US Master Contract'];
        Account acc = new Account(Name = 'test acc');
        insert acc;
        FIN_Context__c context = new FIN_Context__c(
            FIN_StartDate__c = Date.today() - 1
        );
        insert context;
        Contract Contract = new Contract();
        Contract.RecordTypeId = record.Id;
        Contract.CurrencyIsoCode = 'USD';
        Contract.AccountId = acc.Id;
        Contract.FIN_Context__c = context.Id;
        insert Contract;


        Test.startTest();
        Fin_ContractExtController con = new Fin_ContractExtController (new ApexPages.StandardController(Contract));
        con.onRecall();
        Contract = [SELECT ApprovalStatus__c FROM Contract WHERE Id = :Contract.Id LIMIT 1];
        Test.stopTest();

        System.assertEquals('Recalled', Contract.ApprovalStatus__c);

    }
}