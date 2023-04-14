@IsTest
public with sharing class FIN_ContractTest {
    @TestSetup
    static void setUp() {
        RecordType clientRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'FIN_Client'];
        Account acc = TestDataFactory.createClientAccount(clientRecordType.Id);
        Contract parent = TestDataFactory.createParentContract(acc.Id);
        Contract sub = TestDataFactory.createContract(acc.Id, parent.Id);
        TestDataFactory.createContractAssociation(sub);
    }

    @IsTest
    static void checkDisabledContract() {
        List<Contract> contracts = TestDataFactory.getParentContract();
        System.assert(contracts.size() == 1);
        Test.startTest();
        Contract ctrct = contracts[0];
        ctrct.Status = 'Deactivated';
        update ctrct;
        for (Contract con : TestDataFactory.getParentContract()[0].SubContracts__r) {
            System.assertEquals('Deactivated', con.Status);
        }
        Test.stopTest();
    }

    @IsTest
    static void checkEnabledContract() {
        List<Contract> contracts = TestDataFactory.getParentContract();
        System.assert(contracts.size() == 1);
        Test.startTest();
        Contract ctrct = contracts[0];
        Set<Id> contractIds = new Set<Id>{ctrct.Id};
        Fin_ContractExtController con = new Fin_ContractExtController(new ApexPages.StandardController(ctrct));
        con.onSubmit();
        ctrct = TestDataFactory.getParentContract()[0];
        List<ContractAssociation__c> contractAssociations = [SELECT Id, ApprovalStatus__c FROM ContractAssociation__c WHERE Contract__c IN :contractIds];
        for (ContractAssociation__c contractAssociation : contractAssociations) {
            System.assertEquals('New', contractAssociation.ApprovalStatus__c);
        }
        Test.stopTest();
    }

    @IsTest
    static void checkContractAssociations() {
        List<Contract> contracts = TestDataFactory.getParentContract();
        System.assert(contracts.size() == 1);
        Test.startTest();
        Contract ctrct = contracts[0];
        ctrct.Status = 'Deactivated';
        update ctrct;
        Set<Id> contractIds = new Set<Id>();

        for (Contract contr : ctrct.SubContracts__r) {
            contractIds.add(contr.Id);
        }
        List<ContractAssociation__c> contractAssociations = [SELECT Id, ApprovalStatus__c FROM ContractAssociation__c WHERE Contract__c IN :contractIds];
        try {
            ContractAssociation__c ca = contractAssociations[0].clone(true, true, false, false);
            ca.ApprovalStatus__c = 'New';
            update ca;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        for (ContractAssociation__c contractAssociation : contractAssociations) {
            System.assertEquals('Deactivated', contractAssociation.ApprovalStatus__c);
        }
        Test.stopTest();
    }

    @IsTest
    static void testContractAssociationSelector() {
        Test.startTest();
        List<Contract> parentContract = TestDataFactory.getParentContract();
        List<String> contractIds = new List<String>{parentContract[0].SubContracts__r[0].Id};
        Set<Id> contractIdsSet = new Set<Id>{parentContract[0].SubContracts__r[0].Id};
        String contextId = parentContract[0].SubContracts__r[0].FIN_Context__c;
        List<ContractAssociation__c> contractAssociations = FIN_ContractAssociationSelector.getAllContractAssociationsByContractIdInAndContextId(contextId, contractIds);
        System.assertEquals(1, contractAssociations.size());
        contractAssociations = FIN_ContractAssociationSelector.getAllContractAssociationsByContextId(contextId);
        System.assertEquals(1, contractAssociations.size());
        contractAssociations = FIN_ContractAssociationSelector.getDeactivatedContractAssociationsByContractIds(contractIdsSet);
        System.assertEquals(0, contractAssociations.size());
        Test.stopTest();
    }

    @IsTest
    static void testReclassifyController() {
        Contract contract = TestDataFactory.getParentContract()[0];
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(contract);
        FIN_ReclassifyRelatedRecordsController recordsController = new FIN_ReclassifyRelatedRecordsController(sc);
        recordsController.onReclassify();
        recordsController.onReprocess();
        Test.stopTest();
    }
}