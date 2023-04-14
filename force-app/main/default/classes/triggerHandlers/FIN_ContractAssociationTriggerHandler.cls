public with sharing class FIN_ContractAssociationTriggerHandler extends TriggerHandler {
    public override void beforeUpdate() {
        FIN_ContractAssociationHelper.checkForDeactivatedContract((List<ContractAssociation__c>) triggerNew);
    }

    public override void beforeInsert() {
        FIN_ContractAssociationHelper.checkForDeactivatedContract((List<ContractAssociation__c>) triggerNew);
    }
}