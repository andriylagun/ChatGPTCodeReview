import {LightningElement, api, track, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {updateRecord} from 'lightning/uiRecordApi';

import getFilteredSubContractsWithPDs from '@salesforce/apex/SettleDataController.getFilteredSubContractsWithPDs';
import createSI from '@salesforce/apex/SettleDataController.createSI';

import SETTLEMENT_OBJECT from '@salesforce/schema/FIN_SettlementSchedule__c';
import SETTLEMENTSCHEDULE_STATUS from '@salesforce/schema/FIN_SettlementSchedule__c.FIN_Status__c';
import SETTLEMENTSCHEDULE_GENERATIONDATE
    from '@salesforce/schema/FIN_SettlementSchedule__c.FIN_SettlementReport_GenerationDate__c';
import SETTLEMENTSCHEDULE_PUBLISHINGDATE from '@salesforce/schema/FIN_SettlementSchedule__c.FIN_PublishingDate__c';
import SETTLEMENTSCHEDULE_REMITTANCEDATE from '@salesforce/schema/FIN_SettlementSchedule__c.FIN_RemittanceDate__c';
import SETTLEMENTSCHEDULE_CONTRACT from '@salesforce/schema/FIN_SettlementSchedule__c.FIN_Contract__c';
import SETTLEMENTSCHEDULE_ID from '@salesforce/schema/FIN_SettlementSchedule__c.Id';

import {
    COLUMNS_DEFINITION_BASIC,
} from './sampleData';

export default class SettlementData extends LightningElement {
    @api recordId;
    @api settlementId;
    objectApiName = SETTLEMENT_OBJECT;
    fields = [SETTLEMENTSCHEDULE_GENERATIONDATE, SETTLEMENTSCHEDULE_STATUS, SETTLEMENTSCHEDULE_PUBLISHINGDATE, SETTLEMENTSCHEDULE_REMITTANCEDATE];
    contract = SETTLEMENTSCHEDULE_CONTRACT;

    eventDateFrom = null;
    eventDateTo = null;
    transactionDateFrom = null;
    transactionDateTo = null;
    sales = '';
    events = '';
    zones = '';
    currentSelectedRows = [];
    allSelectedContracts = [];

    @track filteredData = [];
    @track eventMap = [];
    @track zoneMap = [];

    disabledConfirm = false;

    @track isModalOpen = false;
    @track isFormOpen = false;
    @track isListOpen = false;
    @track isMessageOpen = false;
    @track selectedRows = [];
    @track currentExpandedRows;
    gridColumns = COLUMNS_DEFINITION_BASIC

    @track error;

    handleFormInputChange(event) {
        this[event.target.name] = event.target.value;
    }

    handleUndoClick(event) {
        this[event.target.name] = '';
    }

    lookupSale(event) {
        if (event.detail.selectedRecord) {
            this.sales = event.detail.selectedRecord.Id;
        } else {
            this.sales = ''
        }
    }

    lookupEvent(event) {
        if (event.detail.selectedRecord) {
            this.events = event.detail.selectedRecord.Id;
        } else {
            this.events = ''
        }
    }

    lookupZone(event) {
        if (event.detail.selectedRecord) {
            this.zones = event.detail.selectedRecord.FIN_ZoneDesc__c;
        } else {
            this.zones = ''
        }
    }

    handleClick(event) {
        this.getData();

        if (this.allSelectedContracts.length > 0) {
            this.selectedRows = this.allSelectedContracts;
        }
    }

    getData() {
        getFilteredSubContractsWithPDs({
            objectName: 'settlement',
            contractId: this.recordId,
            eventDateFrom: this.eventDateFrom,
            eventDateTo: this.eventDateTo,
            sale: this.sales,
            event: this.events,
            transactionDateFrom: this.transactionDateFrom,
            transactionDateTo: this.transactionDateTo,
            zone: this.zones,
            context: '',
            region: ''
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
                                .reduce((prev, pd) => pd.FIN_DistributionAmount__c ? prev + pd.FIN_DistributionAmount__c : prev, 0)
                        }
                    );
                }

                if (this.filteredData.length > 0) {
                    this.selectedRows = this.allSelectedContracts;
                    this.openList();
                    this.closeMessage();
                } else {
                    this.openMessage();
                    this.closeList();
                }
                this.error = undefined;
            })
            .catch((error) => {
                console.error(error);
                this.error = error;
                this.filteredData = undefined;
                this.openMessage();
                this.closeList();
            });
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
                if (this.allSelectedContracts.indexOf(currentRows[i]) < 0) {
                    this.allSelectedContracts.push(currentRows[i])
                }
            }

            if (unselectedRows.length > 0) {
                this.allSelectedContracts = this.allSelectedContracts.filter(function (obj) {
                    return obj.id !== unselectedRows[0].id;
                });
            }

            this.currentSelectedRows = currentRows;

        } catch (error) {
            console.error(error);
            this.error = error;
            this.filteredData = undefined;
            this.openMessage();
            this.closeList();
        }
    }

    handleConfirmClick(event) {
        this.disabledConfirm = true;
        if (this.settlementId === undefined) {
            this.openModal();
            this.openForm();
        } else {
            this.handleSuccess();
        }
    }

    handleSuccess(event) {
        this.closeModal();

        let message;
        let settlementShId;

        if (this.settlementId === undefined) {
            let parseStr = JSON.parse(JSON.stringify(event.detail));

            const fields = {};
            fields[SETTLEMENTSCHEDULE_ID.fieldApiName] = parseStr.id;
            fields[SETTLEMENTSCHEDULE_CONTRACT.fieldApiName] = this.recordId;

            const recordInput = {fields};

            updateRecord(recordInput)
                .then(() => {
                    if (this.filteredData.length === 0) {
                        this.disabledConfirm = false
                    }
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Settlemet Shedule was created',
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
            settlementShId = event.detail.id;
            message = " Settlement Items created successfully!";
        } else {
            settlementShId = this.settlementId;
            message = " Settlement Items added successfully!";
        }


        if (this.allSelectedContracts.length > 0) {
            createSI({
                pdIds: this.allSelectedContracts.reduce((prev, ctr) => prev.concat(ctr.child), []),
                settlementSh: settlementShId
            })
                .then((result) => {
                    if (result > 0) {
                        const temp = this.filteredData.filter((el) => !this.allSelectedContracts.find(sel => sel.id === el.id));
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
                    });
                    this.dispatchEvent(closeChildWindow);
                    this.closeModal();
                });
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "",
                    message: "No Settlement Items were created",
                    variant: "success"
                })
            );
        }
    }


    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
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