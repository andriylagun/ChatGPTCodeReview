public with sharing class FIN_LibraryAssociationTriggerHandler extends TriggerHandler {
    protected override void beforeInsert() {
        FIN_LibraryAssociationHelper.checkDuplicates((List<SBQQ__ContractedPrice__c>) this.triggerNew);
    }

    protected override void beforeUpdate() {
        FIN_LibraryAssociationHelper.checkDuplicates((List<SBQQ__ContractedPrice__c>) this.triggerNew);
    }
}