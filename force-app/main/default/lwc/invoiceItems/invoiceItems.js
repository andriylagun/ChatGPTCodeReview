import { LightningElement, api, track, wire  } from 'lwc';
import {refreshApex} from "@salesforce/apex";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {getFieldValue, getRecord} from 'lightning/uiRecordApi';

import getRelatedRecords from '@salesforce/apex/InvoiceDataController.getRelatedRecords';
import removeRelatedIIs from '@salesforce/apex/InvoiceDataController.removeRelatedIIs';

import CONTRACT_FIELD from '@salesforce/schema/FIN_InvoiceSchedule__c.FIN_Contract__c';
import TYPE_FIELD from '@salesforce/schema/FIN_InvoiceSchedule__c.FIN_Type__c';
const fields = [CONTRACT_FIELD, TYPE_FIELD];

import {
    COLUMNS_DEFINITION_BASIC, COLUMNS_SALESTR_BASIC
} from 'c/invoiceData';

export default class InvoiceItems extends LightningElement {
    @api recordId;
    @track recordsData = [];
    @track error;
    @track isListOpen = false;
    @track isModalOpen = false;
    gridColumns = COLUMNS_DEFINITION_BASIC
    invoice;
    refreshTable;
    disabledRemove = true;

    @wire(getRecord, {recordId: '$recordId', fields})
    invoiceSh;

    get type() {
        return getFieldValue(this.invoiceSh.data, TYPE_FIELD);
    }

    get title() {
        // return 'List of selected ' + this.type;
        return 'List of selected Sub-Contracts';
    }

    @wire(getRelatedRecords, {invoiceSh: "$recordId"})
    wiredRecords(response) {
        if (response.data) {
            this.refreshTable = response;
            this.recordsData = [];

            if (this.type === 'PDs') {
                this.gridColumns = COLUMNS_DEFINITION_BASIC;

                for (const contract of response.data) {
                    this.recordsData.push(
                        {
                            id: contract.Id,
                            scNumber: contract?.ContractNumber,
                            scName: contract?.Name,
                            child: contract?.Payment_Distributions__r.map(pd => pd.Id),
                            total: contract?.Payment_Distributions__r
                                .reduce((prev, pd) => pd.FIN_DistributionAmount__c ? prev+pd.FIN_DistributionAmount__c : prev, 0)
                        }
                    );
                }
            } else if (this.type === 'Payments') {
                this.gridColumns = COLUMNS_DEFINITION_BASIC;

                for (const contract of response.data) {
                    this.recordsData.push(
                        {
                            id: contract.Id,
                            scNumber: contract?.ContractNumber,
                            scName: contract?.Name,
                            child: contract?.Payments__r.map(pd => pd.Id),
                            total: contract?.Payments__r
                                .reduce((prev, pd) => pd.FIN_PaymentAmount__c ? prev+pd.FIN_PaymentAmount__c : prev, 0)
                        }
                    );
                }
            } else if (this.type === 'SalesTransactions') {
                this.gridColumns = COLUMNS_SALESTR_BASIC;

                for (const contract of response.data) {
                    this.recordsData.push(
                        {
                            id: contract.Id,
                            scNumber: contract?.ContractNumber,
                            scName: contract?.Name,
                            child: contract?.SBQQ__OrderProducts__r.map(pd => pd.Id),
                            total: contract?.SBQQ__OrderProducts__r
                                .reduce((prev, pd) => pd.FIN_TotalNetAmount__c ? prev+pd.FIN_TotalNetAmount__c : prev, 0),
                            qty: contract?.SBQQ__OrderProducts__r
                                .reduce((prev, pd) => pd.Quantity ? prev+pd.Quantity : prev, 0)
                        }
                    );
                }
            }

            if (this.recordsData.length > 0) {
                this.disabledRemove = false;
                this.openList();
            } else {
                this.disabledRemove = true;
                this.closeList();
            }
            this.error = undefined;
        } else if (response.error) {
            console.error(response.error);
            this.error = response.error;
            this.data = undefined;
            this.closeList();
        }
    }

    handleRemove() {
        this.disabledRemove = true;
        let currentRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        removeRelatedIIs({
            listSubContracts: currentRows.map(function (obj) {
                return obj.id;
            }), invoiceSh: this.recordId
        })
            .then((result) => {
                console.log('result',result)
                if (result > 0) {
                    refreshApex(this.refreshTable);

                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: result + ' Invoice Items was deleted',
                            message: 'Invoice Items was deleted',
                            variant: 'success',
                        })
                    );
                }
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error of records removing ',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            })
    }

    handleAdd() {
        this.invoice = getFieldValue(this.invoiceSh.data, CONTRACT_FIELD);
        this.openModal();
    }

    handleCloseWindow(event) {
        this.closeModal();
    }

    openList() {
        this.isListOpen = true;
    }

    closeList() {
        this.isListOpen = false;
    }

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }
}