public with sharing class FIN_ResponsePublisherTriggerHandler extends TriggerHandler {
    public override void afterInsert() {
        for (FIN_ResponsePublisher__e responsePublisher : (List<FIN_ResponsePublisher__e>) this.triggerNew) {
                if (responsePublisher.ResponseType__c == FIN_SystemDataLoadLog__c.getSObjectType().getDescribe().getName()) {
                    FIN_ResponsePublisherService.processSystemDataLoadLogResponse(responsePublisher.ResponseDTO__c);
                }
        }
    }
}