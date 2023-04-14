import { LightningElement, api, track, wire  } from 'lwc';
import {refreshApex} from "@salesforce/apex";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {getFieldValue, getRecord} from 'lightning/uiRecordApi';

import getRelatedSubContractsWithPDs from '@salesforce/apex/SettleDataController.getRelatedSubContractsWithPDs';
import removeRelatedSIs from '@salesforce/apex/SettleDataController.removeRelatedSIs';

import CONTRACT_FIELD from '@salesforce/schema/FIN_SettlementSchedule__c.FIN_Contract__c';
const fields = [CONTRACT_FIELD];

import {
    COLUMNS_DEFINITION_BASIC,
} from './sampleData';

export default class SettlementItems extends LightningElement {
    @api recordId;
    @track pdData = [];
    @track error;
    @track isListOpen = false;
    @track isModalOpen = false;
    gridColumns = COLUMNS_DEFINITION_BASIC
    settlement;

    @wire(getRecord, {recordId: '$recordId', fields})
    settlementSh;
    refreshTable = []

    @wire(getRelatedSubContractsWithPDs, {settlementSh: "$recordId"})
    wiredPDs(response) {
        if (response.data) {
            console.log('response.data',response.data)
            this.refreshTable = response;
            this.pdData = [];

            for (const contract of response.data) {
                this.pdData.push(
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
            console.log('this.pdData',this.pdData)

            this.openList();
            this.error = undefined;
        } else if (response.error) {
            console.log('response.error',response.error)
            this.error = response.error;
            this.data = undefined;
        }
    }

    handleRemove() {
        let currentRows = this.template.querySelector('lightning-datatable').getSelectedRows();

        removeRelatedSIs({
            listSubContracts: currentRows.map(function (obj) {
                return obj.id;
            }), settlementSh: this.recordId
        })
            .then((result) => {
                if (result > 0) {
                    refreshApex(this.refreshTable);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: result + ' Settlemet Items was deleted',
                            message: 'Settlemet Items was deleted',
                            variant: 'success',
                        })
                    );
                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'No records for removing',
                            variant: 'error'
                        })
                    );
                }
            })
            .catch(error => {
                console.error(error)
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error of records removing ',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                refreshApex(this.pdData);
            });
    }

    handleAdd() {
        this.settlement = getFieldValue(this.settlementSh.data, CONTRACT_FIELD);
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