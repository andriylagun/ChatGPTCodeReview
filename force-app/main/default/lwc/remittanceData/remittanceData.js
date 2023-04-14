import { LightningElement, api, track, wire  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';

import getPayees from '@salesforce/apex/RemittanceDataController.getPayees';
import getContracts from '@salesforce/apex/RemittanceDataController.getContracts';
import getSSNums from '@salesforce/apex/RemittanceDataController.getSSNums';
import getFilteredRPs from '@salesforce/apex/RemittanceDataController.getFilteredRPs';
import createRI from '@salesforce/apex/RemittanceDataController.createRI';

import REMITTANCE_OBJECT from '@salesforce/schema/FIN_RemittanceSchedule__c';
import REMITTANCESCHEDULE_ID from '@salesforce/schema/FIN_RemittanceSchedule__c.Id';
import REMITTANCESCHEDULE_STATUS from '@salesforce/schema/FIN_RemittanceSchedule__c.Status__c';

import {
    COLUMNS_DEFINITION_BASIC,
} from './sampleData';


export default class RemittanceData extends LightningElement {
    @api remittanceId;
    objectApiName = REMITTANCE_OBJECT;
    fields = [REMITTANCESCHEDULE_STATUS];

    remittanceDate = null;
    dueDate = null;
    payees = '';
    contracts = '';
    ssNums = '';
    currentSelectedRows = [];
    allSelectedRPs = [];

    @track filteredData = [];
    @track payeeMap = [];
    @track contractMap = [];
    @track ssNumMap = [];

    disabledConfirm = false;

    @track isModalOpen = false;
    @track isFormOpen = false;
    @track isListOpen = false;
    @track isMessageOpen = false;
    @track selectedRows = [];
    // @track currentExpandedRows;
    gridColumns = COLUMNS_DEFINITION_BASIC

    @track error;

    handleFormInputChange(event) {
        this[event.target.name] = event.target.value;
    }

    handleUndoClick(event) {
        this[event.target.name] = '';
    }

    @wire(getPayees, {contractId: null})
    wiredPayees({data, error}) {
        if (data) {
            for (let i = 0; i < data.length; i++) {
                this.payeeMap = [...this.payeeMap, {value: data[i].Id, label: data[i].FIN_LegalName__c}];
            }
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.payees = undefined;
        }
    }

    get payeesOptions() {
        return this.payeeMap;
    }

    @wire(getContracts, {contractId: null})
    wiredContracts({data, error}) {
        if (data) {
            for (let i = 0; i < data.length; i++) {
                this.contractMap = [...this.contractMap, {value: data[i].Id, label: data[i].ContractNumber}];
            }
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.contracts = undefined;
        }
    }

    get contractsOptions() {
        return this.contractMap;
    }

    @wire(getSSNums, {contractId: null})
    wiredSSNums({data, error}) {
        if (data) {
            for (let i = 0; i < data.length; i++) {
                this.ssNumMap = [...this.ssNumMap, {value: data[i].Id, label: data[i].Name}];
            }
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.ssNums = undefined;
        }
    }

    get ssNumsOptions() {
        return this.ssNumMap;
    }
    
    handleClick(event) {
        this.getData();

        if (this.allSelectedRPs.length > 0) {
            this.selectedRows = this.allSelectedRPs;
        }
    }

    getData() {
        getFilteredRPs({
            remittanceDate: this.remittanceDate,
            dueDate: this.dueDate,
            payees: this.payees,
            contracts: this.contracts,
            ssNums: this.ssNums
        })
            .then((result) => {
                this.filteredData = [];

                for (const rp of result) {
                    this.filteredData.push(
                        {
                            id: rp.Id,
                            remPayoutNumber: rp.Name,
                            payeeLegalName: rp.Payee__r?.FIN_LegalName__c,
                            remittanceAccount: rp.FIN_RemittanceAccount__r?.Name,
                            remittanceAmount: rp.FIN_RemittancePayoutAmount__c,
                            dueDate: rp.Due_Date__c,
                            status: rp.Status__c,
                            contractNumber: rp.Contract__r.ContractNumber,
                            remittanceDate: rp.FIN_PublishDate__c, //
                            settlementStatus: rp.FIN_SettlementScheduleStatus__c,
                            settlementProcess: rp.FIN_SettlementSchedule__r?.Name,
                        }
                    );
                }

                if (this.filteredData.length > 0) {
                    this.selectedRows = this.allSelectedRPs;
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
                if (this.allSelectedRPs.indexOf(currentRows[i]) < 0) {
                    this.allSelectedRPs.push(currentRows[i])
                }
            }

            if (unselectedRows.length > 0) {
                this.allSelectedRPs = this.allSelectedRPs.filter(function (obj) {
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
        if (this.remittanceId === undefined) {
            this.openModal();
            this.openForm();
        } else {
            this.handleSuccess();
        }
    }

    handleSuccess(event) {
        this.closeModal();

        if (this.remittanceId === undefined) {
            let parseStr = JSON.parse(JSON.stringify(event.detail));

            const fields = {};
            fields[REMITTANCESCHEDULE_ID.fieldApiName] = parseStr.id;

            const recordInput = {fields};

            updateRecord(recordInput)
                .then(() => {
                    if (this.filteredData.length === 0) {
                        this.disabledConfirm = false
                    }
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Remittance Shedule was created',
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
        let remittanceShId;

        if (this.remittanceId === undefined) {
            remittanceShId = event.detail.id;
            message = " Remittance Items created successfully!";
        } else {
            remittanceShId = this.remittanceId;
            message = " Remittance Items added successfully!";
        }

        createRI({
            rps: this.allSelectedRPs.map(function (obj) {
                return obj.id;
            }), remittanceSh: remittanceShId
        })
            .then((result) => {
                if (result > 0) {
                    const temp = this.filteredData.filter((el) => !this.allSelectedRPs.find(sel => sel.id === el.id));
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
    }

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
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