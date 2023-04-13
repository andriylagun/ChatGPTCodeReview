public with sharing class  FIN_LibraryAssociationHelper {
    public static final String ContractFeeRTID = Schema.getGlobalDescribe().get('SBQQ__ContractedPrice__c').getDescribe().getRecordTypeInfosByDeveloperName().get('FIN_Contracted_Fee').getRecordTypeId();
    public static void checkDuplicates(List<SBQQ__ContractedPrice__c> libraryAssociationList) {
        
        Set<Id> laIds = new Set<Id>();
        for(SBQQ__ContractedPrice__c libraryAssociation : libraryAssociationList) {
            laIds.add(libraryAssociation.Id);
        }

        List<SBQQ__ContractedPrice__c> allLA = [
            SELECT Id, FIN_Context__c, FIN_Active__c, SBQQ__Product__c, SBQQ__EffectiveDate__c, 
            Association_Type__c, RecordTypeId, FIN_Fee_Category__c
            FROM SBQQ__ContractedPrice__c
            WHERE FIN_Active__c = TRUE
            AND FIN_Context__c != NULL
            AND SBQQ__Product__c != NULL
            AND Association_Type__c != NULL
            AND Id NOT IN :laIds
        ];

        Map<LAComparingWrapper, SBQQ__ContractedPrice__c> laMap = new Map<LAComparingWrapper, SBQQ__ContractedPrice__c>();

        for (SBQQ__ContractedPrice__c la : allLA) {
            laMap.put(new LAComparingWrapper(la.FIN_Context__c, la.SBQQ__Product__c, String.valueOfGmt(la.SBQQ__EffectiveDate__c), la.Association_Type__c, la.RecordTypeId, la.FIN_Fee_Category__c), la);
        }

        System.debug('laMap'+laMap.keySet());
        for (SBQQ__ContractedPrice__c la : libraryAssociationList) {
            System.debug(la);
            if (laMap.containsKey(new LAComparingWrapper(la.FIN_Context__c, la.SBQQ__Product__c, String.valueOfGmt(la.SBQQ__EffectiveDate__c), la.Association_Type__c, la.RecordTypeId, la.FIN_Fee_Category__c))) {
                la.addError('It`s a duplicate');
            } else {
                la.FIN_ContextNameforSearch__c = la.FIN_ContextName__c;
            }
        }
    }

    public class LAComparingWrapper {
        private String contextId;
        private String productId;
        private String effectiveDate;
        private String associationType;
        private Id recordTypeId;
        private String feeCategory;

        public LAComparingWrapper(String contextId, String productId, String effectiveDate, String associationType, Id recordTypeId, String feeCategory) {
            this.contextId = contextId;
            this.productId = productId;
            this.effectiveDate = effectiveDate;
            this.associationType = associationType;
            this.recordTypeId = recordTypeId;
            this.feeCategory = feeCategory;
        }

        public Boolean equals(Object obj) {
            if (obj instanceof LAComparingWrapper) {
                LAComparingWrapper lacw = (LAComparingWrapper) obj;
                if(recordTypeId == ContractFeeRTID){
                    return this.contextId == lacw.contextId && this.feeCategory == lacw.feeCategory && this.effectiveDate == lacw.effectiveDate && this.associationType == lacw.associationType;
                }
                else{
                    return this.contextId == lacw.contextId && this.productId == lacw.productId && this.effectiveDate == lacw.effectiveDate && this.associationType == lacw.associationType;
                }
            }
            return false;
        }
    }
}