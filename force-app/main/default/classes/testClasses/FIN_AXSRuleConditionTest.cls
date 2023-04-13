@IsTest
public with sharing class FIN_AXSRuleConditionTest {
    @IsTest
    static void testBeforeInsert() {
        Account acc = TestDataFactory.createAccount();
        Contract parentContract = TestDataFactory.createParentContract(acc.Id);

        FIN_AXSRuleEngine__c sr = new FIN_AXSRuleEngine__c(
            RecordTypeId = Schema.SObjectType.FIN_AXSRuleEngine__c.getRecordTypeInfosByDeveloperName()
                .get('EnrichmentTagging').getRecordTypeId(),
            FIN_Object__c = 'Sales',
            FIN_AssociatedContract__c = parentContract.Id,
            FIN_Start_Date__c = Date.today(),
                FIN_Type__c = 'Financial'
        );
        insert sr;


        FIN_AXSRuleCondition__c arc = new FIN_AXSRuleCondition__c(
            FIN_SortingRule__c = sr.Id,
            RecordTypeId = Schema.SObjectType.FIN_AXSRuleCondition__c.getRecordTypeInfosByDeveloperName()
                .get('AXS_Rule_Condition_Enrichment_Record_Type').getRecordTypeId(),
            FIN_Object__c = 'Sales',
            FIN_RelatedObject__c = 'Order',
            FIN_ObjectAttribute__c = 'region'
        );

//        Test.startTest();
        insert arc;
//        Test.stopTest();

        FIN_AXSRuleCondition__c resultARC = [
            SELECT Id, FIN_Object__c
            FROM FIN_AXSRuleCondition__c
            LIMIT 1
        ];

        Assert.areEqual(sr.FIN_Object__c, resultARC.FIN_Object__c);
    }
}