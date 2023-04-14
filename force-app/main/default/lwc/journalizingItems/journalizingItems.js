import { LightningElement, api, track, wire  } from 'lwc';
import {refreshApex} from "@salesforce/apex";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {getFieldValue, getRecord} from 'lightning/uiRecordApi';

import getRelatedRecords from '@salesforce/apex/JournalizingDataController.getRelatedRecords';
import removeRelatedJIs from '@salesforce/apex/JournalizingDataController.removeRelatedJIs';

import CONTRACT_FIELD from '@salesforce/schema/Journalizing_Schedule__c.FIN_Contract__c';
import TYPE_FIELD from '@salesforce/schema/Journalizing_Schedule__c.FIN_Type__c';
const fields = [CONTRACT_FIELD, TYPE_FIELD];

import {
    COLUMNS_DEFINITION_BASIC
}  from 'c/journalizingData';

export default class JournalizingItems extends LightningElement {
    @api recordId;
    @track recordsData = [];
    @track error;
    @track isListOpen = false;
    @track isModalOpen = false;
    gridColumns = COLUMNS_DEFINITION_BASIC
    refreshTable;
    disabledRemove = true;

    @wire(getRecord, {recordId: '$recordId', fields})
    journalizingSh;

    get type() {
        return getFieldValue(this.journalizingSh.data, TYPE_FIELD);
    }

    get title() {
        // return 'List of selected ' + this.type;
        return 'List of selected Sub-Contracts';
    }

    @wire(getRelatedRecords, {journalizingSh: "$recordId"})
    wiredRecords(response) {
        if (response.data) {
            console.log('response.data',response.data)
            console.log('this.type',this.type)
            this.refreshTable = response;
            this.recordsData = [];

            if (this.type === 'PDs') {
                for (const contract of response.data) {
                    this.recordsData.push(
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
            } else if (this.type === 'Payments') {
                for (const contract of response.data) {
                    this.recordsData.push(
                        {
                            id: contract.Id,
                            scNumber: contract?.ContractNumber,
                            scName: contract?.Name,
                            child: contract?.Payments__r.map(pd => pd.Id),
                            total: contract?.Payments__r
                                .reduce((prev, pd) => pd.FIN_JournalEntryAmount__c ? prev+pd.FIN_JournalEntryAmount__c : prev, 0)
                        }
                    );
                }
            }
            console.log('this.recordsData',this.recordsData)


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
        removeRelatedJIs({
            listSubContracts: currentRows.map(function (obj) {
                return obj.id;
            }), journalizingSh: this.recordId
        })
            .then((result) => {
                console.log('result',result)
                if (result > 0) {
                    refreshApex(this.refreshTable);

                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: result + 'Journalizing Items was deleted',
                            message: 'Journalizing Items was deleted',
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
        this.journalizing = getFieldValue(this.journalizingSh.data, CONTRACT_FIELD);
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