public with sharing class FIN_RecordsForwarderHelper {
    public static void processRecords(List<FIN_RecordsForwarder__e> recordsForwardersNew) {
        for (FIN_RecordsForwarder__e recordsForwarder : recordsForwardersNew) {
            List<SObject> recordsNew = (List<SObject>) JSON.deserialize(recordsForwarder.RecordsToProcessNew__c, List<SObject>.class);
            Map<Id, SObject> recordsOld = (Map<Id, SObject>) JSON.deserialize(recordsForwarder.RecordsToProcessNew__c, Map<Id, SObject>.class);
            List<SObject> recordsToInsert = new List<SObject>();
            switch on recordsForwarder.OperationName__c {
                when 'createRetroactiveAdjustments' {
                    createRetroactiveAdjustments(recordsNew, recordsOld);
                } when 'deleteRecords' {
                    deleteRecords(recordsNew);
                }
            }
        }
    }

    private static void createRetroactiveAdjustments(List<SObject> records, Map<Id, SObject> recordsOldMap) {
        List<FIN_RetroactiveAdjustment__c> retroactiveAdjustments = new List<FIN_RetroactiveAdjustment__c>();
        String sObjectApiName = records.getSObjectType().getDescribe().getName();
        String targetObjectApiName = FIN_RetroactiveAdjustment__c.SObjectType.getDescribe().getName();
        List<FieldMapping> fieldMappings = FieldMapping.objectFieldMappings.get(sObjectApiName);
        Id recordTypeId = Constants.getRecordTypeIdByName(sObjectApiName.replace('__c', '').replace('FIN_', ''),
                FIN_RetroactiveAdjustment__c.SObjectType.getDescribe().getName());

        if (fieldMappings == null && recordTypeId == null) {
            return;
        }

        for (SObject record : records) {
            SObject oldRecord = recordsOldMap.get(record.Id);
            FIN_RetroactiveAdjustment__c newRetroactiveAdjustment = new FIN_RetroactiveAdjustment__c();
            Boolean hasChanges = false;

            for (FieldMapping fieldMapping : fieldMappings) {
                Object newValue = record.get(fieldMapping.sourceField);
                Object oldValue = oldRecord.get(fieldMapping.sourceField);

                if ((newValue != oldValue) || (fieldMapping.isMandatory && newValue != null)) {
                    newRetroactiveAdjustment.put(fieldMapping.destinationField, newValue);
                    hasChanges = true;
                }
            }
            if (hasChanges) {
                newRetroactiveAdjustment.put(Constants.getLookupFieldByRelatedObjectName(FIN_RetroactiveAdjustment__c.SObjectType.getDescribe().getName(),
                        targetObjectApiName), record.Id);
                newRetroactiveAdjustment.RecordTypeId = recordTypeId;
                retroactiveAdjustments.add(newRetroactiveAdjustment);
            }
        }

        if (!retroactiveAdjustments.isEmpty()) {
            insert retroactiveAdjustments;
        }
    }

    private static void deleteRecords(List<SObject> records) {
        Database.delete(records);
    }
}