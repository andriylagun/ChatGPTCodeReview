@isTest
public class TestDataFactory {
    public static Account createAccount() {
        RecordType record = getClientRecordType();

        Account testAcc = new Account(
            Name = 'Test Account',
            Type = 'Site',
            RecordTypeId = record.Id
        );
        insert testAcc;

        return testAcc;
    }

    public static Account createClientAccount(String recordTypeId) {

        Account testAcc = new Account(
            Name = 'Test Account',
            Type = 'Site',
            RecordTypeId = recordTypeId
        );
        insert testAcc;

        return testAcc;
    }

    public static List<Contract> getParentContract() {
        RecordType clientRecordType = getClientRecordType();
        Account account = [SELECT Id, Name FROM Account WHERE Name LIKE '%Test Account%' AND RecordTypeId = :clientRecordType.Id];
        return [SELECT Id, AccountId, FIN_Context__c, Status, ApprovalStatus__c, (SELECT Id, ApprovalStatus__c, Status, FIN_Context__c FROM SubContracts__r)
        FROM Contract
        WHERE AccountId = :account.Id AND FIN_ParentContract__c = NULL];
    }

    public static ContractAssociation__c createContractAssociation(Contract contract) {
        ContractAssociation__c contractAssociation = new ContractAssociation__c(Contract__c = contract.Id, Context__c = contract.FIN_Context__c, Client__c = contract.AccountId, ApprovalStatus__c = 'Approved');
        insert contractAssociation;
        return contractAssociation;
    }

    public static Contact createContactForAccount(Id accId, String emailId) {
        Contact con = new Contact();
        con.FirstName = 'First Test';
        con.LastName = 'Last Test';
        con.Email = emailId;
        con.Phone = '999-999-9999';
        con.AccountId = accId;
        con.MailingStreet = '123 Test Avenue';
        con.MailingCity = 'Test';
        con.MailingState = 'Florida';
        con.MailingPostalCode = '30010';
        con.MailingCountry = 'United States';
        insert con;

        return con;
    }

    public static Opportunity createOpportunityForAccount(Id accId, String Stagename) {
        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.AccountID = accId;
        opp.Type = 'New';
        opp.CloseDate = System.today();
        opp.StageName = Stagename;

        insert opp;

        return opp;
    }


    public static Pricebook2 createPriceBook(String name) {
        Pricebook2 priceBook = new Pricebook2(
            Name = name,
            Description = 'This is the Price Book description.',
            IsActive = true
        );

        insert priceBook;

        return priceBook;
    }

    public static Product2 createProduct2ByName(String prodName) {
        Product2 prod = new Product2(
                Name = prodName,
                ProductCode = prodName,
                isActive = true,
                CurrencyIsoCode = 'USD'
        );

        insert prod;

        return prod;
    }

    public static Product2 createProduct2() {
        Product2 prod = new Product2(
            Name = 'Product X',
            ProductCode = 'Pro-X',
            isActive = true,
            CurrencyIsoCode = 'USD'
        );

        insert prod;

        return prod;
    }

    public static PricebookEntry createPricebookEntry(Id productId) {
        PricebookEntry standardPriceEntry = new PricebookEntry();
        standardPriceEntry.IsActive = true;
        standardPriceEntry.Product2Id = productId;
        standardPriceEntry.Pricebook2Id = Test.getStandardPricebookId();
        standardPriceEntry.UnitPrice = 10;
        standardPriceEntry.UseStandardPrice = false;
        standardPriceEntry.CurrencyIsoCode = 'USD';
        insert standardPriceEntry;

        return standardPriceEntry;
    }

    public static OpportunityLineItem createOppLineItem(Id oppId, Id priceBookEntryId, String oppStatus) {
        OpportunityLineItem oppLineItem = new OpportunityLineItem();
        oppLineItem.OpportunityId = oppId;
        oppLineItem.Quantity = 1;
        oppLineItem.PricebookEntryId = priceBookEntryId;
        oppLineItem.TotalPrice = 100.00;
        insert oppLineItem;

        return oppLineItem;
    }


    public static OpportunityContactRole createTestOpportunityContactRole(Id oppId, Id conId) {
        OpportunityContactRole ContactRoleObj = new OpportunityContactRole();
        ContactRoleObj.ContactId = conId;
        ContactRoleObj.IsPrimary = true;
        ContactRoleObj.OpportunityId = oppId;
        insert ContactRoleObj;

        return ContactRoleObj;
    }

    public static Contract createContract(Id accId, Id contrId) {
        FIN_Context__c contx = new FIN_Context__c(
            Name = 'SubContract',
            Short_Name__c = 'tstn',
            FIN_StartDate__c = Date.today() - 1
        );
        insert contx;

        Contract contract = new Contract(
            AccountId = accId,
            ContractTerm = 10,
            StartDate = Date.today() - 1,
            FIN_Context__c = contx.Id,
            FIN_ParentContract__c = contrId
        );

        insert contract;

        return contract;
    }

    public static Contract createParentContract(Id accId) {
        FIN_Context__c contx = new FIN_Context__c(
                Name = 'SubContract',
                Short_Name__c = 'tstn',
                FIN_StartDate__c = Date.today() - 1
        );
        insert contx;

        Id finRecordTypeId = Schema.SObjectType.FIN_Standardization__c.getRecordTypeInfosByName().get('Financial Standard').getRecordTypeId();
        FIN_Standardization__c standardizationFin = new FIN_Standardization__c(
                Name = 'standardizationFin',
                RecordTypeId = finRecordTypeId
        );
        insert standardizationFin;

        Id statRecordTypeId = Schema.SObjectType.FIN_Standardization__c.getRecordTypeInfosByName().get('Statistical Standard').getRecordTypeId();
        FIN_Standardization__c standardizationStat = new FIN_Standardization__c(
                Name = 'standardizationStat',
                RecordTypeId = statRecordTypeId
        );
        insert standardizationStat;

        RecordType record = [SELECT Id FROM RecordType WHERE Name = 'US Master Contract'];
        Contract contract = new Contract(
            AccountId = accId,
            ContractTerm = 10,
            FIN_Context__c = contx.Id,
            StartDate = Date.today() - 1,
            RecordTypeId = record.id,
                Status = 'Draft',
                FIN_Statistical_Standard__c = standardizationStat.Id,
                FIN_Financial_Standard__c = standardizationFin.Id
        );

        insert contract;
        return contract;
    }

    public static Order createTestOrder(Id accId) {
        RecordType record = [SELECT Id FROM RecordType WHERE Name = 'US Sales'];

        Order order = new Order(
            AccountId = accId,
            EffectiveDate = System.today(),
            Status = 'Open',
            PriceBook2Id = Test.getStandardPricebookId(),
            RecordTypeId = record.id,
            CurrencyIsoCode = 'USD',
            Invoices_Status__c = 'ToBeInvoiced',
            ApprovalStatus__c = 'Approved'
        );
        insert order;

        return order;
    }

    public static Order createTestOrderWithContract(Id accId, Id contrId) {
        RecordType record = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'US Sales'
        ];

        Order order = new Order(
            AccountId = accId,
            EffectiveDate = System.today(),
            Status = 'Open',
            PriceBook2Id = Test.getStandardPricebookId(),
            RecordTypeId = record.id,
            CurrencyIsoCode = 'USD',
            ApprovalStatus__c = 'Approved',
            Invoices_Status__c = 'ToBeInvoiced',
            ContractId = contrId
        );
        insert order;

        return order;
    }

    public static OrderItem createTestOrderLine(Id orderId, Id product2Id, Id pricebookEntryId) {
        OrderItem lineItem = new OrderItem();
        lineItem.OrderId = orderId;
        lineItem.Quantity = 10;
        lineItem.UnitPrice = 240;
        lineItem.Product2id = product2Id;
        lineItem.PricebookEntryId = pricebookEntryId;
        lineItem.FIN_Invoices_Status__c = 'ToBeInvoiced';

        insert lineItem;

//        Order order = new Order();
//        order.Id = orderId;
////        order.Status = 'Posted';
//        update order;

        return lineItem;
    }

    public static FIN_Payment__c createPayment(Id ordId, Id contrId) {
        RecordType record = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'US Payment'
        ];

        FIN_Payment__c payment = new FIN_Payment__c(
            FIN_Order__c = ordId,
            FIN_PaymentDate__c = System.today(),
            RecordTypeId = record.Id,
            CurrencyIsoCode = 'USD',
            FIN_Invoices_Status__c = 'ToBeInvoiced',
            FIN_ApprovalStatus__c = 'Approved',
            Contract__c = contrId,
            FIN_TransactionId__c = 'Transaction'
        );
        insert payment;

        return payment;
    }

    public static FIN_PaymentDistribution__c createPaymentDistribution(Id paym, Id orderItem, Id contId) {
        RecordType record = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'US Payment Distribution'
        ];

        Campaign event = new Campaign(
            Name = 'Test Name'
        );
        insert event;

        FIN_PaymentDistribution__c paymentd = new FIN_PaymentDistribution__c(
            FIN_OrderProduct__c = orderItem,
            FIN_Payment__c = paym,
            RecordTypeId = record.Id,
            CurrencyIsoCode = 'USD',
            Contract__c = contId,
            FIN_Event__c = event.Id,
            FIN_DistributionDate__c = Date.today() + 1,
            FIN_Settlement_Status__c = 'ScheduledSettlement'
        );
        insert paymentd;

        return paymentd;
    }

    public static FIN_SettlementSchedule__c createSettlementSchedule(Id contr) {
        FIN_SettlementSchedule__c ss = new FIN_SettlementSchedule__c(
            FIN_Contract__c = contr
        );

        insert ss;
        return ss;
    }

    public static FIN_SettlementItem__c createSettlementItem(Id contract, Id settlementSchedule, Id pd) {
        FIN_SettlementItem__c si = new FIN_SettlementItem__c(
            FIN_ParentSettlementSchedule__c = settlementSchedule,
            FIN_PaymentDistribution__c = pd,
            FIN_SubContract__c = contract
        );

        insert si;
        return si;
    }

    public static FIN_InvoiceSchedule__c createInvoiceSchedule(Id contr) {
        FIN_InvoiceSchedule__c ss = new FIN_InvoiceSchedule__c(
            FIN_Contract__c = contr
        );

        insert ss;
        return ss;
    }

    public static Journalizing_Schedule__c createJournalizingSchedule(Id contr) {
        Journalizing_Schedule__c js = new Journalizing_Schedule__c(
            FIN_Contract__c = contr
        );

        insert js;
        return js;
    }

    public static SBQQ__ContractedPrice__c createLibraryAssociation(Id acc) {
        FIN_ChartOfAccounts__c chartOfAccounts = new FIN_ChartOfAccounts__c(
            Name = '1234',
            FIN_Account_Type__c = 'Asset',
            FIN_Start_Date__c = Date.today()
        );
        insert chartOfAccounts;

        FIN_Financial_Code__c finCode = new FIN_Financial_Code__c(
            Name = '12345',
            Region__c = 'US',
            FIN_Financial_Chart_of_Accounts__c = chartOfAccounts.Id
        );
        insert finCode;

        FIN_Payee__c payee = new FIN_Payee__c(
            FIN_StartDate__c = Date.today()
        );
        insert payee;

        RecordType rt = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'FIN_Contracted_Product'
        ];

        FIN_Context__c context = TestDataFactory.createContext();
        insert context;

        SBQQ__ContractedPrice__c la = new SBQQ__ContractedPrice__c(
            RecordTypeId = rt.Id,
            SBQQ__Account__c = acc,
            FIN_Component_Number__c = 1,
            FIN_TicketCategories__c = 'Individual',
            FIN_Concept_Use__c = 'Liability',
            FIN_Payee__c = payee.Id,
            FIN_Financial_Code__c = finCode.Id,
            SBQQ__Discount__c = 10,
            SBQQ__Price__c = 10,
            SBQQ__FilterField__c = 'Product',
            SBQQ__Operator__c = 'equals',
            Association_Type__c = 'Ticket',
            FIN_Context__c = context.Id
        );

        insert la;
        return la;
    }

    public static FIN_Payee__c createPayee() {
        FIN_Payee__c pa = new FIN_Payee__c(
            FIN_LegalName__c = 'test'
        );
        insert pa;
        return pa;
    }

    public static ConsumptionSchedule createConsumptionSchedule(String recordType) {
        Id recordTypeId = Schema.SObjectType.ConsumptionSchedule.getRecordTypeInfosByDeveloperName().get(recordType).getRecordTypeId();
        ConsumptionSchedule consSchedule = new ConsumptionSchedule();
        consSchedule.RecordTypeId = recordTypeId;
        consSchedule.BillingTerm = 12;
        consSchedule.BillingTermUnit = 'Month';
        consSchedule.Type = 'Range';
        consSchedule.RatingMethod = 'Tier';
        consSchedule.Name = 'TestSchedule';
        consSchedule.FIN_Start_Date__c = System.today();
        consSchedule.FIN_ApprovalStatus__c = 'Approved';

        return consSchedule;
    }

    public static ConsumptionRate createConsumptionRate() {
        ConsumptionRate consRate = new ConsumptionRate();
        consRate.ProcessingOrder = 1;
        consRate.LowerBound = 1;
        consRate.UpperBound = 2;
        consRate.Price = 123;
        consRate.PricingMethod = 'FlatFee';

        return consRate;
    }

    public static Accumulator_Condition__c createConsumptionCondition() {
        Accumulator_Condition__c consCondition = new Accumulator_Condition__c();
        consCondition.FIN_Number__c = 123;
        consCondition.Operator__c = '<>';

        return consCondition;
    }

    public static FIN_Context__c createContext() {
        FIN_Context__c context = new FIN_Context__c(
            Name = 'Context',
            Short_Name__c = 'cntxt',
            FIN_StartDate__c = Date.today() - 1
        );
        return context;
    }

    public static Contract createMasterContract(Id accId, Id contextId) {
        RecordType record = [SELECT Id FROM RecordType WHERE Name = 'US Master Contract'];

        Contract contract = new Contract(
            Name = 'MasterContract',
            AccountId = accId,
            ContractTerm = 10,
            FIN_Context__c = contextId,
            StartDate = Date.today() - 1,
            RecordTypeId = record.id
        );

        return contract;
    }

    public static Contract createSubContract(Id accId, Id contrId, Id contextId) {

        Contract contract = new Contract(
            Name = 'SubContract',
            AccountId = accId,
            ContractTerm = 10,
            StartDate = Date.today() - 1,
            FIN_Context__c = contextId,
            FIN_ParentContract__c = contrId
        );

        return contract;
    }

    public static Account createVenue() {
        RecordType record = [SELECT Id FROM RecordType WHERE Name = 'Venue'];

        Account venue = new Account(
            Name = 'Test Account',
            Type = 'Site',
            RecordTypeId = record.Id
        );

        return venue;
    }

    public static Campaign createEvent() {
        RecordType record = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'US Event'
        ];

        Campaign event = new Campaign(
            Name = 'Event'
        );

        return event;
    }

    public static Zone_Types__c createZoneType() {
        Zone_Types__c zoneType = new Zone_Types__c(
            Name = 'Admissions'
        );

        return zoneType;
    }

    public static Order createSale(Id accId, Id contrId, Id eventId, Id contextId, Id venueId, string zoneTypeName) {
        RecordType record = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'US Sales'
        ];

        Order order = new Order(
            AccountId = accId, Name = 'New sale',
            Status = 'Open',
            EffectiveDate = System.today(),
            PriceBook2Id = Test.getStandardPricebookId(),
            RecordTypeId = record.id,
            CurrencyIsoCode = 'USD',
            ApprovalStatus__c = 'Approved',
            Invoices_Status__c = 'ToBeInvoiced',
            ContractId = contrId,
            FIN_OrderContext__c = contextId,
            FIN_Venue__c = venueId,
            FIN_Event__c = eventId,
            FIN_ZoneType__c = zoneTypeName,
            FIN_TransactionId__c = 'Transaction'
        );

        return order;
    }

    public static FIN_PaymentDistribution__c createPaymentDistributionForReclas(Id paymentId, Id saleId, Id contractId) {
        RecordType record = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'US Payment Distribution'
        ];

        FIN_PaymentDistribution__c paymentd = new FIN_PaymentDistribution__c(
            FIN_Payment__c = paymentId,
            RecordTypeId = record.Id,
            Contract__c = contractId,
            FIN_Order_ID__c = saleId
        );

        return paymentd;
    }

    public static ContractAssociation__c createFullFilledContractAssociation(Id contextId, Id contractId, Id clientId, Id venueId, Id eventId, Id zoneTypeId) {
        RecordType record = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'Contract-Mapping'
        ];

        ContractAssociation__c contrAs = new ContractAssociation__c();
        contrAs.Contract__c = contractId;
        contrAs.Context__c = contextId;
        contrAs.Client__c = clientId;
        contrAs.FIN_Venue__c = venueId;
        contrAs.FIN_AXS_Event__c = eventId;
        contrAs.FIN_Event_Zone__c = zoneTypeId;
        contrAs.ApprovalStatus__c = 'Approved';

        return contrAs;
    }

    public static Remittance_Payout__c createRemittancePayout(Id ssNums, Id contractId) {
        FIN_Payee__c payee = TestDataFactory.createPayee();

        Remittance_Payout__c rp = new Remittance_Payout__c(
            Status__c = 'Approved',
            Payee__c = payee.Id,
            Contract__c = contractId,
            FIN_SettlementSchedule__c = ssNums
        );

        insert rp;
        return rp;
    }

    public static FIN_RemittanceSchedule__c createRemittanceSchedule() {
        FIN_RemittanceSchedule__c remittanceSchedule = new FIN_RemittanceSchedule__c(
            Status__c = 'Exported'
        );

        insert remittanceSchedule;
        return remittanceSchedule;
    }

    public static FIN_SystemDataLoadLog__c createSystemDataLog(String processName) {
        FIN_SystemDataLoadLog__c sysDataLog = new FIN_SystemDataLoadLog__c ();
        sysDataLog.FIN_Process__c = processName;
        sysDataLog.FIN_ProcessDate__c = System.today();

        return sysDataLog;
    }

    public static FIN_AXSRuleEngine__c createRuleEngine(String contractId) {
        String recordTypeId = [SELECT Id FROM RecordType WHERE Name LIKE '%Settlement%' AND SobjectType = 'FIN_AXSRuleEngine__c'][0].Id;
        String conditionRecordTypeId = [SELECT Id FROM RecordType WHERE Name LIKE '%Settlement%' AND SobjectType = 'FIN_AXSRuleCondition__c'][0].Id;
        String actionRecordTypeId = [SELECT Id FROM RecordType WHERE Name LIKE '%Settlement%' AND SobjectType = 'FIN_AXSRuleAction__c'][0].Id;
        FIN_AXSRuleEngine__c ruleEngine = new FIN_AXSRuleEngine__c();
        ruleEngine.RecordTypeId = recordTypeId;
        ruleEngine.FIN_Object__c = 'Sales';
        ruleEngine.ApprovalStatus__c = 'Approved';
        ruleEngine.FIN_Region__c = 'US';
        ruleEngine.isActive__c = true;
        ruleEngine.FIN_Type__c = 'Settlement';
        ruleEngine.FIN_Condition__c = 'AND';
        ruleEngine.FIN_Start_Date__c = Date.today().addDays(-1);
        ruleEngine.FIN_AssociatedContract__c = contractId;
        Id ruleId = Database.insert(ruleEngine).id;
        FIN_AXSRuleCondition__c condition = new FIN_AXSRuleCondition__c();
        condition.RecordTypeId = conditionRecordTypeId;
        condition.FIN_SortingRule__c = ruleId;
        condition.FIN_Operator__c = '=';
        condition.FIN_Object__c = ruleEngine.FIN_Object__c;
        condition.FIN_RelatedObject__c = getPicklistMap(FIN_AXSRuleCondition__c.FIN_RelatedObject__c.getDescribe().getPicklistValues()).get(Order.getSObjectType().getDescribe().getName());
        condition.FIN_RelatedObjectAttribute__c = getPicklistMap(FIN_AXSRuleCondition__c.FIN_RelatedObjectAttribute__c.getDescribe().getPicklistValues()).get(Order.Name.getDescribe().getName());
        condition.FIN_Value__c = 'New sale';
        insert condition;
        FIN_AXSRuleAction__c action = new FIN_AXSRuleAction__c();
        action.RecordTypeId = actionRecordTypeId;
        action.FIN_Object__c = ruleEngine.FIN_Object__c;
        action.FIN_SortingRule__c = ruleId;
        action.FIN_DestinationField__c = getPicklistMap(FIN_AXSRuleAction__c.FIN_DestinationField__c.getDescribe().getPicklistValues()).get(Order.Settlement_Status__c.getDescribe().getName());
        action.FIN_StatusFieldValue__c = getPicklistMap(Order.Settlement_Status__c.getDescribe().getPicklistValues()).get('ToBeSettled');
        action.Action_Type__c = 'Update';
        insert action;
        ruleEngine.AXS_Rule_Conditions__r.add(condition);
        ruleEngine.AXS_Rule_Actions__r.add(action);
        return ruleEngine;
    }

    public static Map<String, String> getPicklistMap(List<PicklistEntry> picklistEntries) {
        Map<String, String> pickListMap = new Map<String, String>();
        for (PicklistEntry pe : picklistEntries) {
            pickListMap.put(pe.getValue(), pe.getValue());
        }
        return pickListMap;
    }

    public static RecordType getClientRecordType() {
        return [SELECT Id FROM RecordType WHERE DeveloperName = 'FIN_Client'];
    }
}