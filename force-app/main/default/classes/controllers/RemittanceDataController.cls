public with sharing class RemittanceDataController {
    @AuraEnabled(cacheable=false)
    public static List<Remittance_Payout__c> getFilteredRPs(Date remittanceDate, Date dueDate, String payees, String contracts, String ssNums) {

        String query = 'SELECT Id, Payee__c, Payee__r.FIN_LegalName__c, FIN_RemittanceAccount__r.Name, FIN_RemittancePayoutAmount__c, ' +
            'FIN_SettlementSchedule__r.Name, FIN_SettlementScheduleStatus__c, Due_Date__c, FIN_PublishDate__c, Status__c, Name, ' +
            'Contract__c, Contract__r.ContractNumber, FIN_RemittanceAccount__c ' +
            'FROM Remittance_Payout__c ' +
            'WHERE Status__c = \'Approved\'';

        if (remittanceDate != null) {
            query += ' AND FIN_PublishDate__c = :remittanceDate';
        }
        if (dueDate != null) {
            query += ' AND Due_Date__c = :dueDate';
        }
        if (payees != '') {
            query += ' AND Payee__c = :payees';
        }
        if (contracts != '') {
            query += ' AND Contract__c = :contracts';
        }
        if (ssNums != '') {
            query += ' AND FIN_SettlementSchedule__c = :ssNums';
        }

        List<Remittance_Payout__c> filteredRPs = new List<Remittance_Payout__c>();
        filteredRPs = Database.query(query);

        System.debug('filteredRPs' + filteredRPs);
        return filteredRPs;
    }

    @AuraEnabled(cacheable=true)
    public static List<FIN_Payee__c> getPayees(String contractId) {
        List<FIN_Payee__c> actualPayees = new List<FIN_Payee__c>();
        List<Id> actualPayeesIDs = new List<Id>();

        List<Remittance_Payout__c> rpList = [
            SELECT Id, Payee__c
            FROM Remittance_Payout__c
            WHERE Status__c = 'Approved'
        ];

        for (Remittance_Payout__c rp : rpList) {
            actualPayeesIDs.add(rp.Payee__c);
        }

        for (FIN_Payee__c p : [SELECT Id, FIN_LegalName__c FROM FIN_Payee__c WHERE Id IN :actualPayeesIDs]) {
            actualPayees.add(p);
        }

        return actualPayees;
    }

    @AuraEnabled(cacheable=true)
    public static List<Contract> getContracts(String contractId) {
        List<Contract> actualContracts = new List<Contract>();
        List<Id> actualContractsIDs = new List<Id>();

        List<Remittance_Payout__c> rpList = [
            SELECT Id, Contract__c
            FROM Remittance_Payout__c
            WHERE Status__c = 'Approved'
        ];

        for (Remittance_Payout__c rp : rpList) {
            actualContractsIDs.add(rp.Contract__c);
        }

        for (Contract p : [SELECT Id, ContractNumber FROM Contract WHERE Id IN :actualContractsIDs]) {
            actualContracts.add(p);
        }

        return actualContracts;
    }

    @AuraEnabled(cacheable=true)
    public static List<FIN_SettlementSchedule__c> getSSNums(String contractId) {
        List<FIN_SettlementSchedule__c> actualSSs = new List<FIN_SettlementSchedule__c>();
        List<Id> actualSSIDs = new List<Id>();

        List<Remittance_Payout__c> rpList = [
            SELECT Id, FIN_SettlementSchedule__c
            FROM Remittance_Payout__c
            WHERE Status__c = 'Approved'
        ];

        for (Remittance_Payout__c rp : rpList) {
            actualSSIDs.add(rp.FIN_SettlementSchedule__c);
        }

        for (FIN_SettlementSchedule__c p : [SELECT Id, Name FROM FIN_SettlementSchedule__c WHERE Id IN :actualSSIDs]) {
            actualSSs.add(p);
        }

        return actualSSs;
    }

    @AuraEnabled(cacheable=false)
    public static Integer createRI(List<Id> rps, String remittanceSh) {
        List<FIN_RemittanceItem__c> newItems = new List<FIN_RemittanceItem__c>();

        List<Remittance_Payout__c> listRP = [
            SELECT Id, Payee__c, Payee__r.FIN_LegalName__c, FIN_RemittanceAccount__c, FIN_RemittancePayoutAmount__c
            FROM Remittance_Payout__c
            WHERE Id IN :rps
        ];

        for (Remittance_Payout__c rp : listRP) {
            //rp.Status__c = 'Complete';
            newItems.add(new FIN_RemittanceItem__c(
                FIN_RemittancePayout__c = rp.Id,
                FIN_ParentRemittanceSchedule__c = remittanceSh,
                FIN_Payee__c = rp.Payee__c,
                FIN_RemittanceAccount__c = rp.FIN_RemittanceAccount__c,
                FIN_RemittanceAmount__c = rp.FIN_RemittancePayoutAmount__c
            ));
        }

        insert newItems;
        update listRP;

        return newItems.size();
    }
}