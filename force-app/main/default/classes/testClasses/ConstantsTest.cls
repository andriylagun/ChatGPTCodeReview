@IsTest
public with sharing class ConstantsTest {
    @IsTest
    static void testConstants() {
        System.debug(Constants.CONTRACT_ASSOCIATION_EXCEPTION_MESSAGE);
        System.debug(Constants.contextFieldsMap);
        System.debug(Constants.UNCLASSIFIED_QUEUE_US);
        System.debug(Constants.fieldToCheckConditions);
        System.debug(Constants.fieldsToGetMap);
        System.debug(Constants.UNCLASSIFIED_QUERY_CONDITION);
        System.debug(Constants.CLASSIFY_FROM_HEROKU_CONDITION);
        System.debug(Constants.finProcessMap);
        System.debug(Constants.paymentDistributionsFields);
        System.debug(Constants.CLASSIFIED_QUEUE_US);
        System.debug(Constants.finProcessMapForSettlement);
        System.debug(Constants.sObjectToFieldsMap);
        System.debug(Constants.STANDART_SELECT_QUERY);
        System.debug(Constants.SYSTEM_DATA_LOAD_LOG_JOB_NAME);
        System.debug(Constants.uniqueIdsMap);
        System.debug(Constants.getQueryForReclassification('Order', true));
        System.debug(Constants.getQueryForReclassification('FIN_PaymentDistribution__c', true));
        System.debug(Constants.getQueryForReclassification('FIN_Payment__c', true));
        try {
            System.debug(Constants.getQueryForReclassification('FIN_Payment__1', true));
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        System.debug(Constants.getContractFieldFromObject('Order'));
        System.debug(Constants.getContractFieldFromObject('FIN_Payment__c'));
        System.debug(Constants.getContractFieldFromObject('FIN_PaymentDistribution__c'));
        System.debug(Constants.getContractFieldFromObject('OrderItem'));
        try {
            System.debug(Constants.getContractFieldFromObject('OrderItems1'));
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        System.debug(Constants.getTicketComponentType('1'));
        System.debug(Constants.getTicketComponentType('test'));
        System.debug(Constants.getAssociationType('FEE'));
        System.debug(Constants.getAssociationType('merch'));
        System.debug(Constants.getAssociationType('uplift'));
        System.debug(Constants.getAssociationType('some'));
        System.debug(Constants.getFinObject('Sales'));
        System.debug(Constants.getFinProcessMap());
        System.debug(Constants.getContextPartQueryForSObject('Order', 'testId'));
        System.debug(Constants.getQueryForLibraryAssociationReclassification('OrderItem'));
        System.debug(Constants.getQueryForLibraryAssociationReclassification('FIN_Payment__c'));
        System.debug(Constants.getQueryForLibraryAssociationReclassification('FIN_PaymentDistribution__c'));
        try {
            System.debug(Constants.getQueryForLibraryAssociationReclassification('FIN_PaymentDistributionc'));
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        System.debug(Constants.getOrderForSystemDataLoadLogRecords());
    }
}