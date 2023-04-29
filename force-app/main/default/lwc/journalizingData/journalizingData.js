import { LightningElement, api, track, wire  } from 'lwc';
import { getPicklistValues, getObjectInfo} from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';

import getFilteredSubContractsWithPDs from '@salesforce/apex/SettleDataController.getFilteredSubContractsWithPDs';
import getFilteredSubContractsWithPayments from '@salesforce/apex/InvoiceDataController.getFilteredSubContractsWithPayments';
import getRegionPickListValues from '@salesforce/apex/JournalizingDataController.getRegionPickListValues';
import createJI from '@salesforce/apex/JournalizingDataController.createJI';

import Id from '@salesforce/user/Id';
import USER_CURRENTREGION from '@salesforce/schema/User.FIN_Current_Region__c';

import JOURNALIZING_OBJECT from '@salesforce/schema/Journalizing_Schedule__c';
import JOURNALIZINGSCHEDULE_STATUS from '@salesforce/schema/Journalizing_Schedule__c.FIN_Status__c';
import JOURNALIZINGSCHEDULE_GENERATIONDATE from '@salesforce/schema/Journalizing_Schedule__c.FIN_Journal_Report_Generation_Date__c';
import JOURNALIZINGSCHEDULE_PUBLISHINGDATE from '@salesforce/schema/Journalizing_Schedule__c.FIN_Publishing_Date__c';
import JOURNALIZINGSCHEDULE_REMITTANCEDATE from '@salesforce/schema/Journalizing_Schedule__c.FIN_Remittance_Date__c';
import JOURNALIZINGSCHEDULE_STARTDATE from '@salesforce/schema/Journalizing_Schedule__c.FIN_StartDate__c';
import JOURNALIZINGSCHEDULE_ENDDATE from '@salesforce/schema/Journalizing_Schedule__c.FIN_EndDate__c';
import JOURNALIZINGSCHEDULE_GLDATE from '@salesforce/schema/Journalizing_Schedule__c.FIN_GLDate__c';
import JOURNALIZINGSCHEDULE_EXPLANATION from '@salesforce/schema/Journalizing_Schedule__c.FIN_Explanation__c';
import JOURNALIZINGSCHEDULE_TYPE from '@salesforce/schema/Journalizing_Schedule__c.FIN_Type__c';
import JOURNALIZINGSCHEDULE_ID from '@salesforce/schema/Journalizing_Schedule__c.Id';
import JOURNALIZINGSCHEDULE_BATCHNUMBER from '@salesforce/schema/Journalizing_Schedule__c.FIN_JDEdwardsBatchNumber__c';

import {
    COLUMNS_DEFINITION_BASIC
} from './sampleData';

export {
    COLUMNS_DEFINITION_BASIC
} from './sampleData';

export default class JournalizingData extends LightningElement {
    @api journalizingId
    @api journalizingType
    objectApiName = JOURNALIZING_OBJECT
    fields = [JOURNALIZINGSCHEDULE_STATUS, JOURNALIZINGSCHEDULE_GENERATIONDATE, JOURNALIZINGSCHEDULE_PUBLISHINGDATE, JOURNALIZINGSCHEDULE_REMITTANCEDATE, JOURNALIZINGSCHEDULE_STARTDATE, JOURNALIZINGSCHEDULE_ENDDATE, JOURNALIZINGSCHEDULE_GLDATE, JOURNALIZINGSCHEDULE_EXPLANATION, JOURNALIZINGSCHEDULE_BATCHNUMBER]

    regions = ''
    contexts = ''
    contracts = ''
    transactionDateFrom = null
    transactionDateTo = null
    currentSelectedRows = []
    allSelectedRecords = []

    @track contextMap = []
    @track contractMap = []
    @track filteredData = []

    disabledConfirm = false;

    @track isModalOpen = false;
    @track isFormOpen = false;
    @track isListOpen = false;
    @track isMessageOpen = false;
    @track selectedRows = [];
    @track currentExpandedRows;

    gridColumns = COLUMNS_DEFINITION_BASIC

    @track error;

    // @track userMetadata;
    @track value
    @track options = []
    @track availableRegions = []

    get noRecords() {
        // return "No Filtered " + this.value
        return "No Filtered Sub-Contracts"
    }

    get title() {
        // return 'Filtered ' + this.value
        return "Filtered Sub-Contracts"
    }

    get isTabsOpen() {
        return this.journalizingId === undefined;
    }

    handleFormInputChange(event) {
        this[event.target.name] = event.target.value;
    }

    handleUndoClick(event) {
        this[event.target.name] = '';
    }

    lookupContract(event) {
        if (event.detail.selectedRecord) {
            this.contracts = event.detail.selectedRecord.Id;
        } else {
            this.contracts = ''
        }
    }

    lookupContext(event) {
        if (event.detail.selectedRecord) {
            this.contexts = event.detail.selectedRecord.Id;
        } else {
            this.contexts = ''
        }
    }

    @wire(getObjectInfo, {objectApiName: JOURNALIZING_OBJECT})
    objectInfo

    @wire(getPicklistValues, {recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: JOURNALIZINGSCHEDULE_TYPE})
    wiredPicklistValues({error, data}) {
        if (data) {
            this.options = data.values
            if (this.journalizingType === null) {
                this.value = this.options[0].value
            } else {
                this.value = this.journalizingType
            }

            this.error = undefined
        } else if (error) {
            this.error = error
            this.options = undefined
        }
    }

    @wire(getRegionPickListValues)
    wiredRegions({data, error}) {
        if(data) {
            for (let i = 0; i < data.length; i++) {
                this.availableRegions =[...this.availableRegions, {value: data[i], label:data[i]}]
            }
            this.error = undefined
        } else if (error) {
            console.error(error)
            this.error = error
            this.availableRegions = undefined
        }
    }

    @wire(getRecord, { recordId: Id, fields: [USER_CURRENTREGION]})
    currentUserInfo({error, data}) {
        if (data) {
            this.regions = data.fields.FIN_Current_Region__c.value
        } else if (error) {
            console.error(error)
            this.error = error
        }
    }

    handleClick() {
        this.getData();

        if (this.allSelectedRecords.length > 0) {
            this.selectedRows = this.allSelectedRecords;
        }
    }

    handleReset() {
        this.contexts = ''
        this.contracts = ''
        this.transactionDateFrom = null
        this.transactionDateTo = null
    }

    getData() {
        if (this.value === 'PDs') {
            getFilteredSubContractsWithPDs({
                objectName: 'journalizing',
                contractId: this.contracts,
                eventDateFrom: null,
                eventDateTo: null,
                sale: '',
                event: '',
                transactionDateFrom: this.transactionDateFrom,
                transactionDateTo: this.transactionDateTo,
                zone: '',
                context: this.contexts,
                region: this.regions
            })
                .then((result) => {
                    this.filteredData = [];

                    for (const contract of result) {
                        this.filteredData.push(
                            {
                                id: contract.Id,
                                scNumber: contract?.ContractNumber,
                                scName: contract?.Name,
                                child: contract?.Payment_Distributions__r.map(pd => pd.Id),
                                total: contract?.Payment_Distributions__r
                                    .reduce((prev, pd) => pd.FIN_JournalEntryAmount__c ? prev+pd.FIN_JournalEntryAmount__c : prev, 0)
                            }
                        );
                    }

                    if (this.filteredData.length > 0) {
                        this.selectedRows = this.allSelectedRecords
                        this.openList()
                        this.closeMessage()
                    } else {
                        this.openMessage()
                        this.closeList()
                    }
                    this.error = undefined
                })
                .catch((error) => {
                    console.error(error)
                    this.error = error
                    this.filteredData = undefined
                    this.openMessage()
                    this.closeList()
                });
        } else if (this.value === 'Payments') {
            getFilteredSubContractsWithPayments({
                objectName: 'journalizing',
                contractId: this.contracts,
                sale: '',
                event: '',
                zone: '',
                context: this.contexts,
                region: this.regions
            })
                .then((result) => {
                    this.filteredData = []

                    for (const contract of result) {
                        this.filteredData.push(
                            {
                                id: contract.Id,
                                scNumber: contract?.ContractNumber,
                                scName: contract?.Name,
                                child: contract?.Payments__r.map(pd => pd.Id),
                                total: contract?.Payments__r
                                    .reduce((prev, pd) => pd.FIN_JournalEntryAmount__c ? prev+pd.FIN_JournalEntryAmount__c : prev, 0)
                            }
                        )
                    }

                    if (this.filteredData.length > 0) {
                        this.selectedRows = this.allSelectedRecords
                        this.openList()
                        this.closeMessage()
                    } else {
                        this.openMessage()
                        this.closeList()
                    }
                    this.error = undefined
                })
                .catch((error) => {
                    console.error(error)
                    this.error = error
                    this.filteredData = undefined
                    this.openMessage()
                    this.closeList()
                })
        }
    }

    handleRowSelection(event) {
        let unselectedRows = [];

        try {
            let currentRows = event.detail.selectedRows;
            if (currentRows.length > 0) {
                let selectedIds = currentRows.map(row => row.id);
                unselectedRows = this.currentSelectedRows.filter(row => !selectedIds.includes(row.id));
            }

            for (let i = 0; i < currentRows.length; i++) {
                if (this.allSelectedRecords.indexOf(currentRows[i]) < 0) {
                    this.allSelectedRecords.push(currentRows[i])
                }
            }

            if (unselectedRows.length > 0) {
                this.allSelectedRecords = this.allSelectedRecords.filter(function (obj) {
                    return obj.id !== unselectedRows[0].id;
                });
            }

            this.currentSelectedRows = currentRows;

        } catch (error) {
            console.error(error)
            console.log('error 4')
            this.error = error;
            this.filteredData = undefined;
            this.openMessage();
            this.closeList();
        }
    }

    handleConfirmClick(event) {
        this.disabledConfirm = true
        if (this.journalizingId === undefined) {
            this.openModal();
            this.openForm();
        } else {
            this.handleSuccess();
        }
    }

    handleSuccess(event) {
        this.closeModal();

        if (this.journalizingId === undefined) {
            let parseStr = JSON.parse(JSON.stringify(event.detail));

            const fields = {};
            fields[JOURNALIZINGSCHEDULE_ID.fieldApiName] = parseStr.id;
            fields[JOURNALIZINGSCHEDULE_TYPE.fieldApiName] = this.value;

            const recordInput = {fields};

            updateRecord(recordInput)
                .then(() => {
                    if (this.filteredData.length === 0) {
                        this.disabledConfirm = false
                    }
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Journalizing Shedule was created',
                            message: 'Record Name: ' + parseStr.fields.Name.value,
                            variant: 'success',
                        })
                    );
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error creating record',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
        }

        let message;
        let journalizingSheduleId;

        if (this.journalizingId === undefined) {
            journalizingSheduleId = event.detail.id;
            message = " Journalizing Items created successfully!";
        } else {
            journalizingSheduleId = this.journalizingId;
            message = " Journalizing Items added successfully!";
        }

        createJI({
            listIDs: this.allSelectedRecords.reduce((prev, ctr) => prev.concat(ctr.child), []),
            type: this.value,
            journalizingSh: journalizingSheduleId
        })
            .then((result) => {
                if (result > 0) {
                    const temp = this.filteredData.filter((el) => !this.allSelectedRecords.find(sel => sel.id === el.id));
                    this.filteredData = temp

                    if (this.filteredData.length > 0) {
                        this.openList()
                        this.closeMessage()
                    } else {
                        this.openMessage()
                        this.closeList()
                    }

                    this.disabledConfirm = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Success",
                            message: result + message,
                            variant: "success"
                        })
                    );
                }
            })
            .catch((error) => {
                console.error(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error creating record",
                        message: error,
                        variant: "error"
                    })
                );
            })
            .finally(() => {
                const closeChildWindow = new CustomEvent("closechild", {
                    detail: false
                })
                this.dispatchEvent(closeChildWindow)
                this.closeModal();
            });
    }

    handleTypeChange(event) {
        this.closeMessage()
        this.selectedRows = []
        this.value = event.target.value
        this.closeList()
    }

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false
        this.disabledConfirm = false
    }

    openForm() {
        this.isFormOpen = true;
    }

    openList() {
        this.isListOpen = true;
    }

    closeList() {
        this.isListOpen = false;
    }

    openMessage() {
        this.isMessageOpen = true;
    }

    closeMessage() {
        this.isMessageOpen = false;
    }
}