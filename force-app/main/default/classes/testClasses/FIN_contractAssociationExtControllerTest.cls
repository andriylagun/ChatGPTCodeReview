@isTest
public with sharing class FIN_contractAssociationExtControllerTest {
    testMethod static void testSubmit() {
        Account acc = TestDataFactory.createAccount();

        FIN_Context__c context = TestDataFactory.createContext();
        insert context;

        Contract contract = TestDataFactory.createMasterContract(acc.Id, context.Id);
        insert contract;
        ContractAssociation__c cA = TestDataFactory.createContractAssociation(contract);

        Test.startTest();
        FIN_contractAssociationExtController con = new FIN_contractAssociationExtController(new ApexPages.StandardController(cA));
        con.onSubmit();
        cA = [SELECT ApprovalStatus__c FROM ContractAssociation__c WHERE Id = :cA.Id LIMIT 1];
        Test.stopTest();

        System.assertEquals('Approved', cA.ApprovalStatus__c );
    }

    testMethod static void testRecall() {
        Account acc = TestDataFactory.createAccount();

        FIN_Context__c context = TestDataFactory.createContext();
        insert context;

        Contract contract = TestDataFactory.createMasterContract(acc.Id, context.Id);
        insert contract;
        ContractAssociation__c cA = TestDataFactory.createContractAssociation(contract);

        Test.startTest();
        FIN_contractAssociationExtController con = new FIN_contractAssociationExtController(new ApexPages.StandardController(cA));
        con.onRecall();
        cA = [SELECT ApprovalStatus__c FROM ContractAssociation__c WHERE Id = :cA.Id LIMIT 1];
        Test.stopTest();

        System.assertEquals('Recalled', cA.ApprovalStatus__c );
    }
}