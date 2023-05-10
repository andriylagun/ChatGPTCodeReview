public with sharing class SettleDataController {

    @AuraEnabled(Cacheable=true)
    public static List<Contract> getFilteredSubContractsWithPDs(String objectName, String contractId,
            Date eventDateFrom, Date eventDateTo, String sale, String event,
            Date transactionDateFrom, Date transactionDateTo, String zone, String context, String region) {

        SOQLQueryBuilder subQueryBuilder = SOQLQueryBuilder.create()
                .selectClause()
                .fieldList(Constants.getFieldNames(new List<Schema.SObjectField>{
                        FIN_PaymentDistribution__c.Id, FIN_PaymentDistribution__c.FIN_DistributionAmount__c, FIN_PaymentDistribution__c.FIN_JournalEntryAmount__c
                }))
                .endSelectSOQL()
                .fromClause('Payment_Distributions__r');
        WhereClauseBuilder whereForSubQuery = buildConditionsForQuery(WhereClauseBuilder.create(subQueryBuilder), objectName, contractId, eventDateFrom, eventDateTo, sale,
                event, transactionDateFrom, transactionDateTo, zone, context, region);
        SOQLQueryBuilder soqlQueryBuilder = SOQLQueryBuilder.create()
                .selectClause().fieldList(Constants.getFieldNames(new List<Schema.SObjectField>{
                Contract.Id, Contract.Name, Contract.ContractNumber
        })).addSubquery(subQueryBuilder.whereConditionsByBuilder(whereForSubQuery).endWhereSOQL())
                .endSelectSOQL()
                .fromClause(Contract.SObjectType.getDescribe().getName());
        WhereClauseBuilder whereForQuery = WhereClauseBuilder.create(soqlQueryBuilder);
        if (objectName == 'journalizing') {
            whereForQuery.negative(Contract.FIN_ParentContract__c.getDescribe().getName(), '',
                    Constants.ConditionType.EQUALS_CONDITION, null, null);
        } else {
            whereForQuery.condition(Contract.FIN_ParentContract__c.getDescribe().getName(), contractId,
                    Constants.ConditionType.EQUALS_CONDITION, null, null);
        }
        List<Contract> filteredSubContracts = new List<Contract>();
        soqlQueryBuilder
                .whereConditionsByBuilder(whereForQuery)
                .endWhereSOQL();
        System.debug(soqlQueryBuilder.build());
        filteredSubContracts = Database.query(soqlQueryBuilder.build());

        List<Contract> processedSubContracts = new List<Contract>();

        for (Contract contract : filteredSubContracts) {
            if (contract.Payment_Distributions__r.size() > 0) {
                processedSubContracts.add(contract);
            }
        }

        System.debug('processedSubContracts' + processedSubContracts);

        return processedSubContracts;
    }

    @AuraEnabled(cacheable=false)
    public static Integer createSI(List<Id> pdIds, String settlementSh) {
        if (!pdIds.isEmpty()) {
            SOQLQueryBuilder queryBuilder = SOQLQueryBuilder.create()
                    .selectClause()
                    .field('Id').field('Contract__c')
                    .field('FIN_LibraryAssociation__c').field('FIN_DistributionAmount__c')
                    .field('FIN_Settlement_Status__c')
                    .endSelectSOQL()
                    .fromClause('FIN_PaymentDistribution__c')
                    .whereClause()
                    .useBindVariablesInQuery(true)
                    .condition(FIN_PaymentDistribution__c.Id.getDescribe().getName(),
                            pdIds, Constants.ConditionType.IN_CONDITION, null, null)
                    .endWhereSOQL();
            Database.executeBatch(new FIN_SettlementDataBatch(queryBuilder.build(), queryBuilder.getBindVariables(), new FIN_SettlementSchedule__c(Id = settlementSh)));
        } else {
            throw new AuraHandledException('There is no payment distributions');
        }
        return pdIds.size();
    }

    @AuraEnabled(cacheable=true)
    public static List<Contract> getRelatedSubContractsWithPDs(String settlementSh) {
        List<FIN_SettlementItem__c> listSI = [
            SELECT Id, FIN_PaymentDistribution__r.Contract__c
            FROM FIN_SettlementItem__c
            WHERE FIN_ParentSettlementSchedule__c = :settlementSh
        ];
        Set <String> setContractId = new Set <String>();
        Set <String> setPDIds = new Set <String>();

        for (FIN_SettlementItem__c item : listSI) {
            setContractId.add(item.FIN_PaymentDistribution__r.Contract__c);
            setPDIds.add(item.FIN_PaymentDistribution__c);
        }

        List<Contract> contractList = [
            SELECT Id, Name, ContractNumber, (
                SELECT Id, FIN_DistributionAmount__c, FIN_JournalEntryAmount__c
                FROM Payment_Distributions__r
                WHERE Id IN :setPDIds
            )
            FROM Contract
            WHERE Id IN :setContractId
        ];

        return contractList;
    }

    @AuraEnabled(cacheable=false)
    public static Integer removeRelatedSIs(List<Id> listSubContracts, String settlementSh) {
        List<FIN_SettlementItem__c> listSI = [
                SELECT Id, FIN_PaymentDistribution__r.FIN_Settlement_Status__c
                FROM FIN_SettlementItem__c
                WHERE FIN_PaymentDistribution__r.Contract__c IN :listSubContracts
                AND FIN_ParentSettlementSchedule__c = :settlementSh
        ];

        delete listSI;
        return listSI.size();
    }

    private static WhereClauseBuilder buildConditionsForQuery(WhereClauseBuilder whereBuilder, String objectName, String contractId,
            Date eventDateFrom, Date eventDateTo, String sale, String event,
            Date transactionDateFrom, Date transactionDateTo, String zone, String context, String region) {
        return buildStatusConditions(whereBuilder, objectName, contractId, false)
                .condition(FIN_PaymentDistribution__c.FIN_ContextID__c.getDescribe().getName(), context,
                        Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.AND_CONDITION)
                .condition(FIN_PaymentDistribution__c.FIN_Region__c.getDescribe().getName(), region,
                        Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.AND_CONDITION)
                .condition('FIN_Payment__r.FIN_Order__r.FIN_Event__r.StartDate', eventDateFrom,
                        Constants.ConditionType.GREATER_THEN, null, Constants.ConditionOperatorType.AND_CONDITION)
                .negative('FIN_Payment__r.FIN_Order__r.FIN_Event__r.EndDate', eventDateTo,
                        Constants.ConditionType.GREATER_THEN, null, Constants.ConditionOperatorType.AND_CONDITION)
                .condition(FIN_PaymentDistribution__c.FIN_DistributionDate__c.getDescribe().getName(), transactionDateFrom,
                        Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.AND_CONDITION)
                .negative(FIN_PaymentDistribution__c.FIN_DistributionDate__c.getDescribe().getName(), transactionDateTo,
                        Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.AND_CONDITION)
                .condition('FIN_Payment__r.FIN_Order__c', sale,
                        Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.AND_CONDITION)
                .condition('FIN_Payment__r.FIN_Order__r.FIN_Event__c', event,
                        Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.AND_CONDITION)
                .condition('FIN_Payment__r.FIN_Order__r.FIN_ZoneDesc__c', zone,
                        Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.AND_CONDITION);
    }

    private static WhereClauseBuilder buildStatusConditions(WhereClauseBuilder builder, String objectName, String contractId, Boolean isForEvents) {
        builder.beginGroup(Constants.ConditionOperatorType.AND_CONDITION);
        if (objectName == 'settlement') {
            builder.condition(FIN_PaymentDistribution__c.FIN_Settlement_Status__c.getDescribe().getName(), 'ToBeSettled',
                    Constants.ConditionType.EQUALS_CONDITION, null, null)
                    .condition(FIN_PaymentDistribution__c.FIN_Settlement_Status__c.getDescribe().getName(), 'Voided',
                            Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.OR_CONDITION);
        } else if (objectName == 'invoice') {
            builder.condition(FIN_PaymentDistribution__c.Invoices_Status__c.getDescribe().getName(), 'ToBeInvoiced',
                    Constants.ConditionType.EQUALS_CONDITION, null, null)
                    .condition(FIN_PaymentDistribution__c.Invoices_Status__c.getDescribe().getName(), 'Voided',
                            Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.OR_CONDITION);
        } else if (objectName == 'journalizing') {
            builder.condition(FIN_PaymentDistribution__c.FIN_Journalizing_Status__c.getDescribe().getName(), 'ToBePosted',
                    Constants.ConditionType.EQUALS_CONDITION, null, null)
                    .condition(FIN_PaymentDistribution__c.FIN_Order_ID__c.getDescribe().getRelationshipName() + '.' + Order.ContractId.getDescribe().getName(), contractId,
                            Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.AND_CONDITION);
        }
        if (isForEvents) {
            builder.condition(FIN_PaymentDistribution__c.FIN_Order_ID__c.getDescribe().getRelationshipName() + '.' + Order.ContractId.getDescribe().getName(), contractId,
                    Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.AND_CONDITION);
        }
        return builder.endGroup()
                .condition('FIN_Payment__r.FIN_Order__r.ApprovalStatus__c', 'Approved',
                        Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.AND_CONDITION);
    }
}