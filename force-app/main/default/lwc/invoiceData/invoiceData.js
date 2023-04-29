import {LightningElement, api, track, wire} from 'lwc';
import {getPicklistValues, getObjectInfo} from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {updateRecord} from 'lightning/uiRecordApi';
import {PAYMENT_SOBJECT_API, PAYMENT_DISTRIBUTION_SOBJECT_API, SALES_TRANSACTIONS_SOBJECT_API} from '../utilits/constants'
import getFilteredSubContractsWithPDs from '@salesforce/apex/SettleDataController.getFilteredSubContractsWithPDs';
import getFilteredSubContractsWithPayments
    from '@salesforce/apex/InvoiceDataController.getFilteredSubContractsWithPayments';
import getFilteredSubContractsWithSalesTransactions
    from '@salesforce/apex/InvoiceDataController.getFilteredSubContractsWithSalesTransactions';
import createInvoiceItems from '@salesforce/apex/InvoiceDataController.createInvoiceItems';
import INVOICE_OBJECT from '@salesforce/schema/FIN_InvoiceSchedule__c';
import INVOICE_ACCUMULATORS from '@salesforce/schema/FIN_InvoiceSchedule__c.FIN_ApplyAccumulators__c';
import INVOICE_MODE from '@salesforce/schema/FIN_InvoiceSchedule__c.FIN_Mode__c';
import INVOICE_DESCRIPTION from '@salesforce/schema/FIN_InvoiceSchedule__c.FIN_Description__c';
import INVOICE_TERMS from '@salesforce/schema/FIN_InvoiceSchedule__c.FIN_Terms__c';
import INVOICE_PO from '@salesforce/schema/FIN_InvoiceSchedule__c.FIN_CustomerPO__c';
import INVOICE_PUBLISHDATE from '@salesforce/schema/FIN_InvoiceSchedule__c.FIN_PublishDate__c';
import INVOICE_CONTRACT from '@salesforce/schema/FIN_InvoiceSchedule__c.FIN_Contract__c';
import INVOICE_TYPE from '@salesforce/schema/FIN_InvoiceSchedule__c.FIN_Type__c';

import {
    COLUMNS_DEFINITION_BASIC, COLUMNS_SALESTR_BASIC
} from './sampleData'

export {
    COLUMNS_DEFINITION_BASIC, COLUMNS_SALESTR_BASIC
} from './sampleData'

export default class InvoiceData extends LightningElement {
    @api recordId
    @api invoiceId
    @api invoiceType
    objectApiName = INVOICE_OBJECT
    fields = [INVOICE_DESCRIPTION, INVOICE_TERMS, INVOICE_PO, INVOICE_PUBLISHDATE, INVOICE_ACCUMULATORS]
    contract = INVOICE_CONTRACT

    eventDateFrom = null
    eventDateTo = null
    transactionDateFrom = null
    transactionDateTo = null
    sales = ''
    events = ''
    zones = ''
    currentSelectedRows = []
    allSelectedRecords = []

    @track filteredData = []
    @track eventMap = []
    @track zoneMap = []

    disabledConfirm = false;

    @track isModalOpen = false
    @track isFormOpen = false
    @track isListOpen = false
    @track isMessageOpen = false
    @track selectedRows = []
    @track currentExpandedRows
    gridColumns = COLUMNS_DEFINITION_BASIC

    @track error

    @track value
    @track options = []

    get noRecords() {
        return "No Filtered Sub-Contracts"
        // return "No Filtered " + this.value
    }

    get title() {
        return 'Filtered Sub-Contracts'
        // return 'Filtered ' + this.value
    }

    get isTabsOpen() {
        return this.invoiceId === undefined;
    }

    handleFormInputChange(event) {
        this[event.target.name] = event.target.value
    }

    handleUndoClick(event) {
        this[event.target.name] = ''
    }

    @wire(getObjectInfo, {objectApiName: INVOICE_OBJECT})
    objectInfo

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

    @wire(getPicklistValues, {recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: INVOICE_TYPE})
    wiredPicklistValues({error, data}) {
        if (data) {
            this.options = data.values
            if (this.invoiceType === null) {
                this.value = this.options[0].value
            } else {
                this.value = this.invoiceType
            }

            this.error = undefined
        } else if (error) {
            this.error = error
            this.options = undefined
        }
    }

    handleClick(event) {
        this.getData()

        if (this.allSelectedRecords.length > 0) {
            this.selectedRows = this.allSelectedRecords
        }
    }

    getData() {
        console.log(this.value);
        if (this.value === PAYMENT_DISTRIBUTION_SOBJECT_API) {
            this.gridColumns = COLUMNS_DEFINITION_BASIC

            getFilteredSubContractsWithPDs({
                objectName: 'invoice',
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
                    this.filteredData = []

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
        } else if (this.value === PAYMENT_SOBJECT_API) {
            this.gridColumns = COLUMNS_DEFINITION_BASIC

            getFilteredSubContractsWithPayments({
                objectName: 'invoice',
                contractId: this.recordId,
                sale: this.sales,
                event: this.events,
                zone: this.zones,
                context: '',
                region: ''
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
                                    .reduce((prev, pd) => pd.FIN_PaymentAmount__c ? prev + pd.FIN_PaymentAmount__c : prev, 0)
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
        } else if (this.value === SALES_TRANSACTIONS_SOBJECT_API) {
            this.gridColumns = COLUMNS_SALESTR_BASIC

            getFilteredSubContractsWithSalesTransactions({
                contractId: this.recordId,
                sale: this.sales,
                event: this.events,
                zone: this.zones
            })
                .then((result) => {
                    console.log('result', result)
                    this.filteredData = []
                    const data = result;

                    for (const key in data) {
                        const contract = JSON.parse(key);
                        console.log('contract', contract);
                        console.log('data[key]', data[key]);
                        this.filteredData.push(
                            {
                                id: contract.Id,
                                scNumber: contract?.ContractNumber,
                                scName: contract?.Name,
                                child: data[key].map(pd => pd.Id),
                                total: data[key]
                                    .reduce((prev, pd) => pd.FIN_TotalNetAmount__c ? prev + pd.FIN_TotalNetAmount__c : prev, 0),
                                qty: data[key]
                                    .reduce((prev, pd) => pd.Quantity ? prev + pd.Quantity : prev, 0)
                            }
                        )
                    }

                    if (this.filteredData.length > 0) {
                        this.selectedRows = this.allSelectedRecords
                        console.log('this.filteredData', this.filteredData)
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
        let unselectedRows = []

        try {
            let currentRows = event.detail.selectedRows
            if (currentRows.length > 0) {
                let selectedIds = currentRows.map(row => row.id)
                unselectedRows = this.currentSelectedRows.filter(row => !selectedIds.includes(row.id))
            }

            for (let i = 0; i < currentRows.length; i++) {
                if (this.allSelectedRecords.indexOf(currentRows[i]) < 0) {
                    this.allSelectedRecords.push(currentRows[i])
                }
            }

            if (unselectedRows.length > 0) {
                this.allSelectedRecords = this.allSelectedRecords.filter(function (obj) {
                    return obj.id !== unselectedRows[0].id
                })
            }

            this.currentSelectedRows = currentRows
        } catch (error) {
            console.error(error)
            this.error = error
            this.filteredData = undefined
            this.openMessage()
            this.closeList()
        }
    }

    handleConfirmClick(event) {
        if (this.allSelectedRecords.length > 0) {
            this.disabledConfirm = true;
            if (this.invoiceId === undefined) {
                this.openModal();
                this.openForm();
            } else {
                this.handleSubmit(event);
            }
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: "Please choose at least one sub-contract",
                    variant: "error"
                })
            )
        }
    }

    handleSubmit(event) {
        this.value
        this.closeModal()
        let message = ''
        let invoiceSh
        const mapObj = {};
        this.allSelectedRecords.forEach((value) => {
            mapObj[value.id] = value.child;
        });


        if (this.invoiceId === undefined) {
            message = " Invoice Items created successfully!"
            invoiceSh = event.detail.fields
        } else {
            message = " Invoice Items added successfully!"
            invoiceSh = null
        }

        createInvoiceItems({
            jsonString: JSON.stringify(mapObj),
            type: this.value,
            invoiceSh: invoiceSh,
            currentInvoiceSh: this.invoiceId
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
                    )
                }
            })
            .catch((error) => {
                console.error(error)
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error creating record",
                        message: error,
                        variant: "error"
                    })
                )
            })
            .finally(() => {
                const closeChildWindow = new CustomEvent("closechild", {
                    detail: false
                })
                this.dispatchEvent(closeChildWindow)
                this.closeModal()
            })
    }

    handleTypeChange(event) {
        this.closeMessage()
        this.selectedRows = []
        this.value = event.target.value

        if (this.value === SALES_TRANSACTIONS_OBJECT.objectApiName) {
            this.fields = [INVOICE_DESCRIPTION, INVOICE_TERMS, INVOICE_PO, INVOICE_PUBLISHDATE, INVOICE_ACCUMULATORS, INVOICE_MODE]
        } else {
            this.fields = [INVOICE_DESCRIPTION, INVOICE_TERMS, INVOICE_PO, INVOICE_PUBLISHDATE, INVOICE_ACCUMULATORS]
        }
        this.getData()
    }

    openModal() {
        this.isModalOpen = true
    }

    closeModal() {
        this.isModalOpen = false
        this.disabledConfirm = false
    }

    openForm() {
        this.isFormOpen = true
    }

    openList() {
        this.isListOpen = true
    }

    closeList() {
        this.isListOpen = false
    }

    openMessage() {
        this.isMessageOpen = true
    }

    closeMessage() {
        this.isMessageOpen = false
    }
}