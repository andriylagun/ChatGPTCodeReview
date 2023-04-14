/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
*  Test class for FIN_ClassifyRecordsBatch logic
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Ivan Liolia
* @modifiedBy     Ivan Liolia
* @version        1.0
* @created        2022-04-11
* @modified       2022-04-11
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* vX.X            Name
* YYYY-MM-DD      Explanation of the change.  Multiple lines can be used to explain the change, but
*                 each line should be indented till left aligned with the previous description text.
*
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/

@isTest
public with sharing class FIN_ClassifyRecordsBatchTest {
    private static String fieldsToGet = 'Id, OwnerId, FIN_TransactionId__c';
    private static String sObjectTypeName = 'Order';

    /**
    * @method      setupTestData
    * @description Method that generates the test data used in test methods.
    * @author      Ivan Liolia - 2023-04-11
    */
    @TestSetup
    static void setupTestData(){
        FIN_Context__c context = TestDataFactory.createContext();
        insert context;

        Account client = TestDataFactory.createAccount();

        Account venue = TestDataFactory.createVenue();
        insert venue;

        Campaign event = TestDataFactory.createEvent();
        insert event;

        Zone_Types__c zoneType = TestDataFactory.createZoneType();
        insert zoneType;

        Contract masterContract = TestDataFactory.createMasterContract(client.Id, context.Id);
        insert masterContract;

        Contract subContract = TestDataFactory.createSubContract(client.Id, masterContract.Id, context.Id);
        insert subContract;

        ContractAssociation__c contrAs = TestDataFactory.createFullFilledContractAssociation(context.Id, subContract.Id, client.Id, venue.Id, event.Id, zoneType.Id);
        insert contrAs;

        Order sale = TestDataFactory.createSale(client.Id, null, event.Id, context.Id, venue.Id, zoneType.Name);
        sale.OwnerId = FIN_GroupSelector.getGroupByDeveloperName(Constants.UNCLASSIFIED_QUEUE_US).Id;
        insert sale;

        FIN_Payment__c payment = TestDataFactory.createPayment(null, null);

        FIN_PaymentDistribution__c paymentDis = TestDataFactory.createPaymentDistributionForReclas(null, null, null);
        paymentDis.FIN_TransactionId__c = 'Transaction';
        paymentDis.FIN_PaymentTransactionId__c = 'PaymentTransaction';
        paymentDis.FIN_ContextName__c = context.Id;
        paymentDis.OwnerId = FIN_GroupSelector.getGroupByDeveloperName(Constants.UNCLASSIFIED_QUEUE_US).Id;
        insert paymentDis;
    }

    /**
     * @method      classByContextCLientVenueEventZoneTest
     * @description Tests, that sales, payment and payment distributions should be
     *              mapped to Subcontract, if Context, Client, Venue,
     *              Event and Zone match
     * @author      Ivan Liolia - 2022-04-11
     */
    @isTest
    static void classByContextCLientVenueEventZoneTest() {
        Order oldSale = [   SELECT Id
                            ,      ContractId
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];

        Assert.areEqual(null, oldSale.ContractId, 'Sale should not have a related contract');

        List<FIN_Context__c> finContexts = FIN_ContextSelector.getAllActiveContexts();

        Test.startTest();
            FIN_ClassifyRecordsBatch recordsBatch = new FIN_ClassifyRecordsBatch(Constants.sObjectToFieldsMap.get(sObjectTypeName), sObjectTypeName, fieldsToGet + Constants.fieldsToGetMap.get(sObjectTypeName), finContexts);
            Database.executeBatch(recordsBatch);
        Test.stopTest();

        Order classifiedSale = [  SELECT Id
                                    ,      Contract.Name
                                    ,      Contract.FIN_Context__c
                                    FROM   Order];

        Assert.areEqual('SubContract', classifiedSale.Contract.Name, 'Sale was not mapped to SubContract Context, Client, Venue, Event and ZoneType');
    }

    /**
     * @method      classByContextCLientEventZoneTest
     * @description Tests, that sales, payment and payment distributions should be
     *              mapped to Subcontract, if Context, Client, Even,
     *              Zone match
     * @author      Ivan Liolia - 2022-04-11
     */
    @isTest
    static void classByContextCLientEventZoneTest() {
        Order oldSale = [   SELECT Id
                            ,      ContractId
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];

        Assert.areEqual(null, oldSale.ContractId, 'Sale should not have a related contract');

        ContractAssociation__c contrAs = [  SELECT Id
                                            ,      FIN_Event_Zone__c
                                            FROM   ContractAssociation__c];
        contrAs.FIN_Venue__c = null;
        update contrAs;

        List<FIN_Context__c> finContexts = FIN_ContextSelector.getAllActiveContexts();

        Test.startTest();
            FIN_ClassifyRecordsBatch recordsBatch = new FIN_ClassifyRecordsBatch(Constants.sObjectToFieldsMap.get(sObjectTypeName), sObjectTypeName, fieldsToGet + Constants.fieldsToGetMap.get(sObjectTypeName), finContexts);
            Database.executeBatch(recordsBatch);
        Test.stopTest();

        Order classifiedSale = [  SELECT Id
                                    ,      Contract.Name
                                    ,      Contract.FIN_Context__c
                                    FROM   Order];

        Assert.areEqual('SubContract', classifiedSale.Contract.Name, 'Sale was not mapped to SubContract Context, Client, Event, Zone');
    }

    /**
     * @method      classByContextCLientVenueZoneTest
     * @description Tests, that sales, payment and payment distributions should be
     *              mapped to Subcontract, if Context, Client, Venue,
     *              Zone match
     * @author      Ivan Liolia - 2022-04-11
     */
    @isTest
    static void classByContextCLientVenueZoneTest() {
        Order oldSale = [   SELECT Id
                            ,      ContractId
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];

        Assert.areEqual(null, oldSale.ContractId, 'Sale should not have a related contract');

        ContractAssociation__c contrAs = [  SELECT Id
                                            ,      FIN_Event_Zone__c
                                            FROM   ContractAssociation__c];
        contrAs.FIN_AXS_Event__c = null;
        update contrAs;

        List<FIN_Context__c> finContexts = FIN_ContextSelector.getAllActiveContexts();

        Test.startTest();
            FIN_ClassifyRecordsBatch recordsBatch = new FIN_ClassifyRecordsBatch(Constants.sObjectToFieldsMap.get(sObjectTypeName), sObjectTypeName, fieldsToGet + Constants.fieldsToGetMap.get(sObjectTypeName), finContexts);
            Database.executeBatch(recordsBatch);
        Test.stopTest();

        Order classifiedSale = [  SELECT Id
                                    ,      Contract.Name
                                    ,      Contract.FIN_Context__c
                                    FROM   Order];

        Assert.areEqual('SubContract', classifiedSale.Contract.Name, 'Sale was not mapped to SubContract Context, Client, Venue, Zone');
    }

    /**
     * @method      classByContextCLientVenueEventTest
     * @description Tests, that sales, payment and payment distributions should be
     *              mapped to Subcontract, if Context, Client, Venue,
     *              Event match
     * @author      Ivan Liolia - 2022-04-11
     */
    @isTest
    static void classByContextCLientVenueEventTest() {
        Order oldSale = [   SELECT Id
                            ,      ContractId
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];

        Assert.areEqual(null, oldSale.ContractId, 'Sale should not have a related contract');

        ContractAssociation__c contrAs = [  SELECT Id
                                            ,      FIN_Event_Zone__c
                                            FROM   ContractAssociation__c];
        contrAs.FIN_Event_Zone__c = null;
        update contrAs;

        List<FIN_Context__c> finContexts = FIN_ContextSelector.getAllActiveContexts();

        Test.startTest();
            FIN_ClassifyRecordsBatch recordsBatch = new FIN_ClassifyRecordsBatch(Constants.sObjectToFieldsMap.get(sObjectTypeName), sObjectTypeName, fieldsToGet + Constants.fieldsToGetMap.get(sObjectTypeName), finContexts);
            Database.executeBatch(recordsBatch);
        Test.stopTest();

        Order classifiedSale = [  SELECT Id
                                    ,      Contract.Name
                                    ,      Contract.FIN_Context__c
                                    FROM   Order];

        Assert.areEqual('SubContract', classifiedSale.Contract.Name, 'Sale was not mapped to SubContract Context, Client, Venue, Event');
    }

    /**
     * @method      classByContextCLientVenueTest
     * @description Tests, that sales, payment and payment distributions should be
     *              mapped to Subcontract, if Context, Client, Venue match
     * @author      Ivan Liolia - 2022-04-11
     */
    @isTest
    static void classByContextCLientVenueTest() {
        Order oldSale = [   SELECT Id
                            ,      ContractId
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];

        Assert.areEqual(null, oldSale.ContractId, 'Sale should not have a related contract');

        ContractAssociation__c contrAs = [  SELECT Id
                                            ,      FIN_Event_Zone__c
                                            FROM   ContractAssociation__c];
        contrAs.FIN_Event_Zone__c = null;
        contrAs.FIN_AXS_Event__c = null;
        update contrAs;

        List<FIN_Context__c> finContexts = FIN_ContextSelector.getAllActiveContexts();

        Test.startTest();
            FIN_ClassifyRecordsBatch recordsBatch = new FIN_ClassifyRecordsBatch(Constants.sObjectToFieldsMap.get(sObjectTypeName), sObjectTypeName, fieldsToGet + Constants.fieldsToGetMap.get(sObjectTypeName), finContexts);
            Database.executeBatch(recordsBatch);
        Test.stopTest();

        Order classifiedSale = [  SELECT Id
                                    ,      Contract.Name
                                    ,      Contract.FIN_Context__c
                                    FROM   Order];

        Assert.areEqual('SubContract', classifiedSale.Contract.Name, 'Sale was not mapped to SubContract Context, Client, Venue');
    }

    /**
     * @method      classByContextCLientEventTest
     * @description Tests, that sales, payment and payment distributions should be
     *              mapped to Subcontract, if Context, Client, Event match
     * @author      Ivan Liolia - 2022-04-11
     */
    @isTest
    static void classByContextCLientEventTest() {
        Order oldSale = [   SELECT Id
                            ,      ContractId
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];

        Assert.areEqual(null, oldSale.ContractId, 'Sale should not have a related contract');

        ContractAssociation__c contrAs = [  SELECT Id
                                            ,      FIN_Event_Zone__c
                                            FROM   ContractAssociation__c];
        contrAs.FIN_Event_Zone__c = null;
        contrAs.FIN_Venue__c = null;
        update contrAs;

        List<FIN_Context__c> finContexts = FIN_ContextSelector.getAllActiveContexts();

        Test.startTest();
            FIN_ClassifyRecordsBatch recordsBatch = new FIN_ClassifyRecordsBatch(Constants.sObjectToFieldsMap.get(sObjectTypeName), sObjectTypeName, fieldsToGet + Constants.fieldsToGetMap.get(sObjectTypeName), finContexts);
            Database.executeBatch(recordsBatch);
        Test.stopTest();

        Order classifiedSale = [  SELECT Id
                                    ,      Contract.Name
                                    ,      Contract.FIN_Context__c
                                    FROM   Order];

        Assert.areEqual('SubContract', classifiedSale.Contract.Name, 'Sale was not mapped to SubContract Context, Client, Event');
    }

    /**
     * @method      classByContextCLientZoneTest
     * @description Tests, that sales, payment and payment distributions should be
     *              mapped to Subcontract, if Context, Client, Zone match
     * @author      Ivan Liolia - 2022-04-11
     */
    @isTest
    static void classByContextCLientZoneTest() {
        Order oldSale = [   SELECT Id
                            ,      ContractId
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];

        Assert.areEqual(null, oldSale.ContractId, 'Sale should not have a related contract');

        ContractAssociation__c contrAs = [  SELECT Id
                                            ,      FIN_Event_Zone__c
                                            FROM   ContractAssociation__c];
        contrAs.FIN_AXS_Event__c = null;
        contrAs.FIN_Venue__c = null;
        update contrAs;

        List<FIN_Context__c> finContexts = FIN_ContextSelector.getAllActiveContexts();

        Test.startTest();
            FIN_ClassifyRecordsBatch recordsBatch = new FIN_ClassifyRecordsBatch(Constants.sObjectToFieldsMap.get(sObjectTypeName), sObjectTypeName, fieldsToGet + Constants.fieldsToGetMap.get(sObjectTypeName), finContexts);
            Database.executeBatch(recordsBatch);
        Test.stopTest();

        Order classifiedSale = [SELECT Id
                                ,      Contract.Name
                                ,      Contract.FIN_Context__c
                                FROM   Order];

        Assert.areEqual('SubContract', classifiedSale.Contract.Name, 'Sale was not mapped to SubContract Context, Client, Zone');
    }

    /**
     * @method      classByContextCLientTest
     * @description Tests, that sales, payment and payment distributions should be
     *              mapped to Subcontract, if Context, Client match
     * @author      Ivan Liolia - 2022-04-11
     */
    @isTest
    static void classByContextCLientTest() {
        Order oldSale = [   SELECT Id
                            ,      ContractId
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];

        Assert.areEqual(null, oldSale.ContractId, 'Sale should not have a related contract');

        ContractAssociation__c contrAs = [  SELECT Id
                                            ,      FIN_Event_Zone__c
                                            FROM   ContractAssociation__c];
        contrAs.FIN_AXS_Event__c = null;
        contrAs.FIN_Venue__c = null;
        contrAs.FIN_Event_Zone__c = null;
        update contrAs;

        List<FIN_Context__c> finContexts = FIN_ContextSelector.getAllActiveContexts();

        Test.startTest();
            FIN_ClassifyRecordsBatch recordsBatch = new FIN_ClassifyRecordsBatch(Constants.sObjectToFieldsMap.get(sObjectTypeName), sObjectTypeName, fieldsToGet + Constants.fieldsToGetMap.get(sObjectTypeName), finContexts);
            Database.executeBatch(recordsBatch);
        Test.stopTest();

        Order classifiedSale = [SELECT Id
                                ,      Contract.Name
                                ,      Contract.FIN_Context__c
                                FROM   Order];

        Assert.areEqual('SubContract', classifiedSale.Contract.Name, 'Sale was not mapped to SubContract Context, Client');
    }

    /**
     * @method      classWhenNoMatchWithFilledClientAndContextTest
     * @description Tests, that sales, payment and payment distributions should not be
     *              mapped if no match when CLient and Context is Not Empty
     * @author      Ivan Liolia - 2022-04-11
     */
    @isTest
    static void classWhenNoMatchWithFilledClientAndContextTest() {
        Order oldSale = [   SELECT Id
                            ,      ContractId
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];

        Assert.areEqual(null, oldSale.ContractId, 'Sale should not have a related contract');

        Account newClient = TestDataFactory.createAccount();

        ContractAssociation__c contrAs = [  SELECT Id
                                            ,      FIN_Event_Zone__c
                                            FROM   ContractAssociation__c];
        contrAs.FIN_Event_Zone__c = null;
        contrAs.FIN_AXS_Event__c = null;
        contrAs.FIN_Venue__c = null;
        contrAs.Client__c = newClient.Id;
        update contrAs;

        List<FIN_Context__c> finContexts = FIN_ContextSelector.getAllActiveContexts();

        Test.startTest();
            FIN_ClassifyRecordsBatch recordsBatch = new FIN_ClassifyRecordsBatch(Constants.sObjectToFieldsMap.get(sObjectTypeName), sObjectTypeName, fieldsToGet + Constants.fieldsToGetMap.get(sObjectTypeName), finContexts);
            Database.executeBatch(recordsBatch);
        Test.stopTest();

        Order classifiedSale = [SELECT Id
                                ,      Contract.Name
                                ,      Contract.FIN_Context__c
                                FROM   Order];

        Assert.areEqual(null, classifiedSale.Contract.Name, 'Sale should not be mapped to any Contract');
    }

    /**
     * @method      classByContextCLientVenueEventZoneLogRecordTest
     * @description Tests, that sales, payment and payment distributions should be
     *              mapped to Subcontract, if Context, Client, Venue,
     *              Event and Zone match started from SystemDataLog record
     * @author      Ivan Liolia - 2022-04-11
     */
    @isTest
    static void classByContextCLientVenueEventZoneLogRecordTest() {
        FIN_SystemDataLoadLog__c sysDataLog = TestDataFactory.createSystemDataLog('Sales');
        insert sysDataLog;

        Order oldSale = [   SELECT Id
                            ,      ContractId
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];
        oldSale.FIN_SystemDataLoadLog__c = sysDataLog.Id;
        update oldSale;

        List<FIN_Context__c> finContexts = FIN_ContextSelector.getAllActiveContexts();

        Test.startTest();
            FIN_ClassifyRecordsBatch recordsBatch = new FIN_ClassifyRecordsBatch(Constants.sObjectToFieldsMap.get(sObjectTypeName), sObjectTypeName, fieldsToGet + Constants.fieldsToGetMap.get(sObjectTypeName), sysDataLog, finContexts);
            Database.executeBatch(recordsBatch);
        Test.stopTest();

        Order classifiedSale = [SELECT Id
                                ,      Contract.Name
                                ,      Contract.FIN_Context__c
                                FROM   Order];

        Assert.areEqual('SubContract', classifiedSale.Contract.Name, 'Sale was not mapped to SubContract Context, Client, Venue, Event and ZoneType');
    }

    /**
     * @method      classifyPaymentTest
     * @description Tests, that payments mapped to correct Sale and Contract
     * @author      Ivan Liolia - 2022-04-11
     */
    @isTest
    static void classifyPaymentTest() {
        Order sale = [  SELECT Id
                        ,      FIN_OrderContext__c
                        FROM   Order];

        sale.ContractId = [ SELECT Id
                            FROM   Contract
                            WHERE  Name = 'SubContract'].Id;

        update sale;

        FIN_Payment__c payment = [  SELECT Id
                                    FROM   FIN_Payment__c
                                    LIMIT 1];
        payment.OwnerId = FIN_GroupSelector.getGroupByDeveloperName(Constants.UNCLASSIFIED_QUEUE_US).Id;
        payment.FIN_Context__c = sale.FIN_OrderContext__c;

        update payment;

        List<FIN_Context__c> finContexts = FIN_ContextSelector.getAllActiveContexts();

        Test.startTest();
            sObjectTypeName = 'FIN_Payment__c';
            FIN_ClassifyRecordsBatch recordsBatch = new FIN_ClassifyRecordsBatch(Constants.sObjectToFieldsMap.get(sObjectTypeName), sObjectTypeName, fieldsToGet + Constants.fieldsToGetMap.get(sObjectTypeName), finContexts);
            Database.executeBatch(recordsBatch);
        Test.stopTest();

        FIN_Payment__c classifiedPayment = [SELECT Id
                                            ,      FIN_Order__c
                                            ,      Contract__r.Name
                                            FROM   FIN_Payment__c];

        Assert.areEqual(sale.Id, classifiedPayment.FIN_Order__c, 'Payment was not mapped to Sale');
        Assert.areEqual('SubContract', classifiedPayment.Contract__r.Name, 'Payment was not mapped to Contract');
    }

    /**
     * @method      classifyPaymentDistributionTest
     * @description Tests, that paymentDistributions mapped to correct Payment, Sale and Contract
     * @author      Ivan Liolia - 2022-04-11
     */
    @isTest
    static void classifyPaymentDistributionTest() {
        Order sale = [  SELECT Id
                        ,      FIN_OrderContext__c
                        FROM   Order];

        sale.ContractId = [ SELECT Id
                            FROM   Contract
                            WHERE  Name = 'SubContract'].Id;

        update sale;

        FIN_Payment__c payment = [  SELECT Id
                                    FROM   FIN_Payment__c
                                    LIMIT 1];
        payment.FIN_Order__c = sale.Id;
        payment.FIN_Context__c = sale.FIN_OrderContext__c;
        payment.FIN_PaymentTransactionId__c = 'PaymentTransaction';
        update payment;

        List<FIN_Context__c> finContexts = FIN_ContextSelector.getAllActiveContexts();

        Test.startTest();
            sObjectTypeName = 'FIN_PaymentDistribution__c';
            FIN_ClassifyRecordsBatch recordsBatch = new FIN_ClassifyRecordsBatch(Constants.sObjectToFieldsMap.get(sObjectTypeName), sObjectTypeName, fieldsToGet + Constants.fieldsToGetMap.get(sObjectTypeName), finContexts);
            Database.executeBatch(recordsBatch);
        Test.stopTest();

        FIN_PaymentDistribution__c classifiedPaymentDistr = [   SELECT Id
                                                                ,      FIN_Order_ID__c
                                                                ,      Contract__r.Name
                                                                ,      FIN_Payment__c
                                                                ,      OwnerId
                                                                FROM   FIN_PaymentDistribution__c];

        Assert.areEqual(sale.Id, classifiedPaymentDistr.FIN_Order_ID__c, 'Payment Distribution was not mapped to Sale');
        Assert.areEqual('SubContract', classifiedPaymentDistr.Contract__r.Name, 'Payment Distribution was not mapped to Contract');
        Assert.areEqual(payment.Id, classifiedPaymentDistr.FIN_Payment__c, 'Payment Distribution was not mapped to Payment');
    }
}