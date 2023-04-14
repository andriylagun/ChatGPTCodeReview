public with sharing class FIN_MasterDataLoadTriggerHandler extends TriggerHandler {
    public override void afterUpdate() {
        for (Master_Data_Load__c mdl : (List<Master_Data_Load__c>) triggerNew) {
            Master_Data_Load__c masterDataLoad = MasterDataLoadSelector.getMasterDataLoadRecordWithLookupDataById(mdl.Id)[0];
            if (checkMasterDataLoadConditions(masterDataLoad)) {
                FIN_SystemDataLoadLogService.makeCalloutToHerokuOnApprove( new Map<String, String>{
                        masterDataLoad.Sales__r.FIN_Process__c.toLowerCase() => masterDataLoad.Sales__c,
                        masterDataLoad.Payment__r.FIN_Process__c.toLowerCase() => masterDataLoad.Payment__c,
                        masterDataLoad.Payment_Distribution__r.FIN_Process__c.toLowerCase() => masterDataLoad.Payment_Distribution__c,
                        'region' => masterDataLoad.FIN_Region__c }
                );
            }
        }
    }

    public override void beforeInsert() {
        for (Master_Data_Load__c mdl : (List<Master_Data_Load__c>) triggerNew) {
            if (MasterDataLoadSelector.getMasterDataLoadRecordByProcessDate(mdl.ProcessDate__c).isEmpty()) {
                return;
            } else {
                throw new AuraHandledException('Record with that date already exist');
            }
        }
    }

    private Boolean checkMasterDataLoadConditions(Master_Data_Load__c masterDataLoad) {
        return masterDataLoad.Payment__r.FIN_StagingTableLoadBusinessApproved__c
                && masterDataLoad.Sales__r.FIN_StagingTableLoadBusinessApproved__c
                && masterDataLoad.Payment_Distribution__r.FIN_StagingTableLoadBusinessApproved__c
                && masterDataLoad.Payment__r.FIN_BusinessRuleProcessCompleteStatus__c == 'In-Progress'
                && masterDataLoad.Sales__r.FIN_BusinessRuleProcessCompleteStatus__c == 'In-Progress'
                && masterDataLoad.Payment_Distribution__r.FIN_BusinessRuleProcessCompleteStatus__c == 'In-Progress';
    }
}