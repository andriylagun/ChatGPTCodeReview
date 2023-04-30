public with sharing class FIN_RecordsForwarderTriggerHandler extends TriggerHandler {
    public override void afterInsert() {
        FIN_RecordsForwarderHelper.processRecords((List<FIN_RecordsForwarder__e>) Trigger.new);
    }
}