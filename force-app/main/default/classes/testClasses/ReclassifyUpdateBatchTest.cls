/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
*  Test class for ReclassifyUpdateBatch logic
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Ivan Liolia
* @modifiedBy     Ivan Liolia
* @version        1.0
* @created        2022-04-05
* @modified       2022-04-05
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* vX.X            Name
* YYYY-MM-DD      Explanation of the change.  Multiple lines can be used to explain the change, but
*                 each line should be indented till left aligned with the previous description text.
*
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/

@isTest
public with sharing class ReclassifyUpdateBatchTest {

    /**
    * @method      setupTestData
    * @description Method that generates the test data used in test methods.
    * @author      Ivan Liolia - 2023-04-05
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

        Order sale = TestDataFactory.createSale(client.Id, masterContract.Id, event.Id, context.Id, venue.Id, zoneType.Name);
        insert sale;

        FIN_Payment__c payment = TestDataFactory.createPayment(sale.Id, masterContract.Id);

        FIN_PaymentDistribution__c paymentDis = TestDataFactory.createPaymentDistributionForReclas(payment.Id, sale.Id, masterContract.Id);
        insert paymentDis;
    }

    /**
     * @method      reclasByContextCLientVenueEventZoneTest
     * @description Tests, that sales, payment and payment distributions should be
     *              remapped from the MasterContract to Subcontract, if Context, Client, Venue,
     *              Event and Zone match
     * @author      Ivan Liolia - 2022-04-05
     */
    @isTest
    static void reclasByContextClientVenueEventZoneTest() {
        List<String> contractIds = new List<String>();

        for (Contract contract : [  SELECT Id
                                    FROM   Contract]) {
            contractIds.add(contract.Id);
        }

        Order oldSale = [   SELECT Id
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];

        FIN_PaymentDistribution__c oldTransAssociations = [ SELECT Id
                                                            ,      Contract__r.Name
                                                            ,      FIN_Payment__r.Contract__r.Name
                                                            FROM   FIN_PaymentDistribution__c];

        Assert.areEqual('MasterContract', oldSale.Contract.Name);
        Assert.areEqual('MasterContract', oldTransAssociations.Contract__r.Name);
        Assert.areEqual('MasterContract', oldTransAssociations.FIN_Payment__r.Contract__r.Name);

        Test.startTest();
        Database.executeBatch(new ReclassifyUpdateBatch('Order', oldSale.Contract.FIN_Context__c, contractIds), 200);
        Test.stopTest();

        Order reclassifiedSale = [  SELECT Id
                                    ,      Contract.Name
                                    ,      Contract.FIN_Context__c
                                    FROM   Order];

        FIN_PaymentDistribution__c reclassifiedTransAssociations = [SELECT Id
                                                                    ,      Contract__r.Name
                                                                    ,      FIN_Payment__r.Contract__r.Name
                                                                    FROM   FIN_PaymentDistribution__c];

        Assert.areEqual('SubContract', reclassifiedSale.Contract.Name, 'Sale was not remapped to SubContract Context, Client, Venue, Event and ZoneType');
        Assert.areEqual('SubContract', reclassifiedTransAssociations.Contract__r.Name, 'PaymentDistribution was not remapped after reclassification');
        Assert.areEqual('SubContract', reclassifiedTransAssociations.FIN_Payment__r.Contract__r.Name, 'Payment was not remapped after reclassification');
    }

    /**
     * @method      reclasByContextCLientVenueEventTest
     * @description Tests, that sales, payment and payment distributions should be
     *              remapped from the MasterContract to Subcontract, if Context, Client, Venue,
     *              and Event match
     * @author      Ivan Liolia - 2022-04-05
     */
    @isTest
    static void reclasByContextClientVenueEventTest() {
        List<String> contractIds = new List<String>();

        for (Contract contract : [  SELECT Id
                                    FROM   Contract]) {
            contractIds.add(contract.Id);
        }

        Order oldSale = [   SELECT Id
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];

        Assert.areEqual('MasterContract', oldSale.Contract.Name);

        ContractAssociation__c contrAs = [  SELECT Id
                                            ,      FIN_Event_Zone__c
                                            FROM   ContractAssociation__c];
        contrAs.FIN_Event_Zone__c = null;
        update contrAs;

        Test.startTest();
        Database.executeBatch(new ReclassifyUpdateBatch('Order', oldSale.Contract.FIN_Context__c, contractIds), 200);
        Test.stopTest();

        Order reclassifiedSale = [  SELECT Id
                                    ,      Contract.Name
                                    ,      Contract.FIN_Context__c
                                    FROM   Order];

        Assert.areEqual('SubContract', reclassifiedSale.Contract.Name, 'Sale was not remapped to SubContract by Context, Client, Venue and Event');
    }

    /**
     * @method      reclasByContextCLientEventZoneTest
     * @description Tests, that sales, payment and payment distributions should be
     *              remapped from the MasterContract to Subcontract, if Context, Client, Event,
     *              and ZoneType match
     * @author      Ivan Liolia - 2022-04-05
     */
    @isTest
    static void reclasByContextCLientEventZoneTest() {
        List<String> contractIds = new List<String>();

        for (Contract contract : [  SELECT Id
                                    FROM   Contract]) {
            contractIds.add(contract.Id);
        }

        Order oldSale = [   SELECT Id
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];

        Assert.areEqual('MasterContract', oldSale.Contract.Name);

        ContractAssociation__c contrAs = [  SELECT Id
                                            ,      FIN_Event_Zone__c
                                            FROM   ContractAssociation__c];
        contrAs.FIN_Venue__c = null;
        update contrAs;

        Test.startTest();
        Database.executeBatch(new ReclassifyUpdateBatch('Order', oldSale.Contract.FIN_Context__c, contractIds), 200);
        Test.stopTest();

        Order reclassifiedSale = [  SELECT Id
                                    ,      Contract.Name
                                    ,      Contract.FIN_Context__c
                                    FROM   Order];

        Assert.areEqual('SubContract', reclassifiedSale.Contract.Name, 'Sale was not remapped to SubContract by Context, Client, Event and ZoneType');
    }

    /**
     * @method      reclasByContextCLientVenueZoneTest
     * @description Tests, that sales, payment and payment distributions should be
     *              remapped from the MasterContract to Subcontract, if Context, Client, Venue,
     *              and ZoneType match
     * @author      Ivan Liolia - 2022-04-05
     */
    @isTest
    static void reclasByContextCLientVenueZoneTest() {
        List<String> contractIds = new List<String>();

        for (Contract contract : [  SELECT Id
                                    FROM   Contract]) {
            contractIds.add(contract.Id);
        }

        Order oldSale = [   SELECT Id
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];

        Assert.areEqual('MasterContract', oldSale.Contract.Name);

        ContractAssociation__c contrAs = [  SELECT Id
                                            ,      FIN_Event_Zone__c
                                            FROM   ContractAssociation__c];
        contrAs.FIN_AXS_Event__c = null;
        update contrAs;

        Test.startTest();
        Database.executeBatch(new ReclassifyUpdateBatch('Order', oldSale.Contract.FIN_Context__c, contractIds), 200);
        Test.stopTest();

        Order reclassifiedSale = [  SELECT Id
                                    ,      Contract.Name
                                    ,      Contract.FIN_Context__c
                                    FROM   Order];

        Assert.areEqual('SubContract', reclassifiedSale.Contract.Name, 'Sale was not remapped to SubContract by Context, Client, Venue and ZoneType');
    }

    /**
     * @method      reclasByContextCLientEventTest
     * @description Tests, that sales, payment and payment distributions should be
     *              remapped from the MasterContract to Subcontract, if Context, Client
     *              and Event match
     * @author      Ivan Liolia - 2022-04-05
     */
    @isTest
    static void reclasByContextClientEventTest() {
        List<String> contractIds = new List<String>();

        for (Contract contract : [  SELECT Id
                                    FROM   Contract]) {
            contractIds.add(contract.Id);
        }

        Order oldSale = [   SELECT Id
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];

        Assert.areEqual('MasterContract', oldSale.Contract.Name);

        ContractAssociation__c contrAs = [  SELECT Id
                                            ,      FIN_Event_Zone__c
                                            FROM   ContractAssociation__c];
        contrAs.FIN_Event_Zone__c = null;
        contrAs.FIN_Venue__c = null;
        update contrAs;

        Test.startTest();
        Database.executeBatch(new ReclassifyUpdateBatch('Order', oldSale.Contract.FIN_Context__c, contractIds), 200);
        Test.stopTest();

        Order reclassifiedSale = [  SELECT Id
                                    ,      Contract.Name
                                    ,      Contract.FIN_Context__c
                                    FROM   Order];

        Assert.areEqual('SubContract', reclassifiedSale.Contract.Name, 'Sale was not remapped to SubContract by Context, Client and Event');
    }

    /**
     * @method      reclasByContextCLientVenueTest
     * @description Tests, that sales, payment and payment distributions should be
     *              remapped from the MasterContract to Subcontract, if Context, Client
     *              and Venue match
     * @author      Ivan Liolia - 2022-04-05
     */
    @isTest
    static void reclasByContextClientVenueTest() {
        List<String> contractIds = new List<String>();

        for (Contract contract : [  SELECT Id
                                    FROM   Contract]) {
            contractIds.add(contract.Id);
        }

        Order oldSale = [   SELECT Id
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];

        Assert.areEqual('MasterContract', oldSale.Contract.Name);

        ContractAssociation__c contrAs = [  SELECT Id
                                            ,      FIN_Event_Zone__c
                                            FROM   ContractAssociation__c];
        contrAs.FIN_Event_Zone__c = null;
        contrAs.FIN_AXS_Event__c = null;
        update contrAs;

        Test.startTest();
        Database.executeBatch(new ReclassifyUpdateBatch('Order', oldSale.Contract.FIN_Context__c, contractIds), 200);
        Test.stopTest();

        Order reclassifiedSale = [  SELECT Id
                                    ,      Contract.Name
                                    ,      Contract.FIN_Context__c
                                    FROM   Order];

        Assert.areEqual('SubContract', reclassifiedSale.Contract.Name, 'Sale was not remapped to SubContract by Context, Client and Venue');
    }

    /**
     * @method      reclasByContextCLientZoneTest
     * @description Tests, that sales, payment and payment distributions should be
     *              remapped from the MasterContract to Subcontract, if Context, Client
     *              and Even Zone match
     * @author      Ivan Liolia - 2022-04-11
     */
    @isTest
    static void reclasByContextCLientZoneTest() {
        List<String> contractIds = new List<String>();

        for (Contract contract : [  SELECT Id
                                    FROM   Contract]) {
            contractIds.add(contract.Id);
        }

        Order oldSale = [   SELECT Id
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];

        Assert.areEqual('MasterContract', oldSale.Contract.Name);

        ContractAssociation__c contrAs = [  SELECT Id
                                            ,      FIN_Event_Zone__c
                                            FROM   ContractAssociation__c];
        contrAs.FIN_Venue__c = null;
        contrAs.FIN_AXS_Event__c = null;
        update contrAs;

        Test.startTest();
        Database.executeBatch(new ReclassifyUpdateBatch('Order', oldSale.Contract.FIN_Context__c, contractIds), 200);
        Test.stopTest();

        Order reclassifiedSale = [  SELECT Id
                                    ,      Contract.Name
                                    ,      Contract.FIN_Context__c
                                    FROM   Order];

        Assert.areEqual('SubContract', reclassifiedSale.Contract.Name, 'Sale was not remapped to SubContract by Context, Client and Event Zone');
    }

    /**
     * @method      reclasByContextCLientTest
     * @description Tests, that sales, payment and payment distributions should be
     *              remapped from the MasterContract to Subcontract, if Context
     *              and Client match
     * @author      Ivan Liolia - 2022-04-05
     */
    @isTest
    static void reclasByContextCLientTest() {
        List<String> contractIds = new List<String>();

        for (Contract contract : [  SELECT Id
                                    FROM   Contract]) {
            contractIds.add(contract.Id);
        }

        Order oldSale = [   SELECT Id
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];

        Assert.areEqual('MasterContract', oldSale.Contract.Name);

        ContractAssociation__c contrAs = [  SELECT Id
                                            ,      FIN_Event_Zone__c
                                            FROM   ContractAssociation__c];
        contrAs.FIN_Event_Zone__c = null;
        contrAs.FIN_AXS_Event__c = null;
        contrAs.FIN_Venue__c = null;
        update contrAs;

        Test.startTest();
        Database.executeBatch(new ReclassifyUpdateBatch('Order', oldSale.Contract.FIN_Context__c, contractIds), 200);
        Test.stopTest();

        Order reclassifiedSale = [  SELECT Id
                                    ,      Contract.Name
                                    ,      Contract.FIN_Context__c
                                    FROM   Order];

        Assert.areEqual('SubContract', reclassifiedSale.Contract.Name, 'Sale was not remapped to SubContract by Context and Client');
    }

    /**
     * @method      reclasWhenNoMatchWithEmptyClientTest
     * @description Tests, that sales, payment and payment distributions should be
     *              remapped to the MasterContract if no match with subContracts and
     *              clientId is empty
     * @author      Ivan Liolia - 2022-04-05
     */
    @isTest
    static void reclasWhenNoMatchWithEmptyClientTest() {
        List<String> contractIds = new List<String>();

        Contract subContract = [SELECT Id
                                ,      Name
                                ,      FIN_ParentContract__c
                                FROM   Contract
                                WHERE  Name = 'SubContract'];

        contractIds.add(subContract.Id);
        contractIds.add(subContract.FIN_ParentContract__c);

        Order oldSale = [   SELECT Id
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];

        oldSale.ContractId = subContract.Id;
        update oldSale;

        ContractAssociation__c contrAs = [  SELECT Id
                                            ,      FIN_Event_Zone__c
                                            FROM   ContractAssociation__c];
        contrAs.FIN_Event_Zone__c = null;
        contrAs.FIN_AXS_Event__c = null;
        contrAs.FIN_Venue__c = null;
        contrAs.Client__c = null;
        update contrAs;

        Test.startTest();
        Database.executeBatch(new ReclassifyUpdateBatch('Order', oldSale.Contract.FIN_Context__c, contractIds), 200);
        Test.stopTest();

        Order reclassifiedSale = [  SELECT Id
                                    ,      Contract.Name
                                    ,      Contract.FIN_Context__c
                                    FROM   Order];

        Assert.areEqual('MasterContract', reclassifiedSale.Contract.Name, 'Sale should be remapped to the MasterContract');
    }

    /**
     * @method      reclasWhenNoMatchWithFilledClientAndContextTest
     * @description Tests, that sales, payment and payment distributions should be
     *              remapped to the MasterContract if no match with subContracts
     *              when CLient and Context is Not Empty
     * @author      Ivan Liolia - 2022-04-05
     */
    @isTest
    static void reclasWhenNoMatchWithFilledClientAndContextTest() {
        List<String> contractIds = new List<String>();

        Contract subContract = [SELECT Id
                                ,      Name
                                ,      FIN_ParentContract__c
                                FROM   Contract
                                WHERE  Name = 'SubContract'];

        contractIds.add(subContract.Id);
        contractIds.add(subContract.FIN_ParentContract__c);

        Order oldSale = [   SELECT Id
                            ,      Contract.Name
                            ,      Contract.FIN_Context__c
                            FROM   Order];

        oldSale.ContractId = subContract.Id;
        update oldSale;

        Account newClient = TestDataFactory.createAccount();

        ContractAssociation__c contrAs = [  SELECT Id
                                            ,      FIN_Event_Zone__c
                                            FROM   ContractAssociation__c];
        contrAs.FIN_Event_Zone__c = null;
        contrAs.FIN_AXS_Event__c = null;
        contrAs.FIN_Venue__c = null;
        contrAs.Client__c = newClient.Id;
        update contrAs;

        Test.startTest();
        Database.executeBatch(new ReclassifyUpdateBatch('Order', oldSale.Contract.FIN_Context__c, contractIds), 200);
        Test.stopTest();

        Order reclassifiedSale = [  SELECT Id
                                    ,      Contract.Name
                                    ,      Contract.FIN_Context__c
                                    FROM   Order];

        Assert.areEqual('MasterContract', reclassifiedSale.Contract.Name, 'Sale should be remapped to the MasterContract');
    }
}