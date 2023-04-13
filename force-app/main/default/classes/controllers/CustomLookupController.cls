public class CustomLookupController {
    @AuraEnabled(cacheable=true)
    public static List<SObject> fetchLookupData(String searchKey, String sObjectApiName, String searchField, String contractId) {
        List<SObject> returnList = new List<SObject>();

        String additionalLogic = '';
        if(contractId != null) {
            additionalLogic = ' AND (Contract.FIN_ParentContract__c = :contractId OR ContractId = :contractId) AND ApprovalStatus__c = \'Approved\'';
        } else {
            additionalLogic = ' AND ApprovalStatus__c = \'Approved\'';
        }

        String sQuery = 'SELECT Id, :searchField FROM :sObjectApiName WHERE :searchField LIKE \'%:searchKey%\' :additionalLogic ORDER BY createdDate DESC LIMIT 5';
        System.debug('sQuery'+sQuery);
        for (SObject obj : Database.query(sQuery.replace(':searchField', searchField).replace(':sObjectApiName', sObjectApiName).replace(':searchKey', searchKey).replace(':additionalLogic',additionalLogic))) {
            returnList.add(obj);
        }

        return returnList;
    }

    @AuraEnabled
    public static SObject fetchDefaultRecord(String recordId, String sObjectApiName, String searchField) {
        String sRecId = recordId;
        String sQuery = 'Select Id, '+ searchField + ' From ' + sObjectApiName + ' Where Id = : sRecId LIMIT 1';
        for (SObject obj : Database.query(sQuery)) {
            System.debug('obj'+obj);
            return obj;
        }
        return null;
    }
}