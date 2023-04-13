public with sharing class FIN_ContractTriggerHandler extends TriggerHandler {
    public override void beforeUpdate() {
        FIN_ContractHelper.processDeactivatedContracts((List<Contract>) triggerNew);
    }

    public override void afterUpdate() {
        FIN_ContractHelper.processActivatedContractsCAs((Map<Id, Contract>) triggerOldMap,(List<Contract>) triggerNew);
    }
}