import {LightningElement, api, track} from 'lwc';
import getLibraryAssociations from '@salesforce/apex/RelatedLibraryAssociationHelper.getLibraryAssociations';

export default class RelatedLibraryAssociationsController extends LightningElement {
    @api recordId;
    @api recordsToDisplay = 5;
    @api maxRecordsToDisplay = 500;
    @api listName = "Contract's Library Associations";
    @api showFromMasterContract = false;
    @track relatedAssociations = [];
    isViewAll = false;
    loading = false;

    connectedCallback() {
        this.loading = true;
        this.loadLibraryAssociations();
    }

    // returns a unique list of Library Associations records, related to
    // the Contract's Sale Transactions, Payments and Payment Distributions records
    loadLibraryAssociations() {
        getLibraryAssociations({
            contractId: this.recordId,
            maxRecordsToDisplay: this.maxRecordsToDisplay,
            showFromMasterContract: this.showFromMasterContract
        })
            .then(result => {
                this.relatedAssociations = result.map(row => {

                    // get the lookup values and it's URLs
                    const nameUrl = `/lightning/r/${row.Id}/view`;
                    const feeUrl = row.FIN_Fee__c === undefined ? '' : `/lightning/r/${row.FIN_Fee__c}/view`;
                    const feeName = row.FIN_Fee__c === undefined ? '' : row.FIN_Fee__r.Name;
                    const contextUrl = row.FIN_Context__c === undefined ? '' : `/lightning/r/${row.FIN_Context__c}/view`;
                    const contextName = row.FIN_Context__c === undefined ? '' : row.FIN_Context__r.Name;
                    const feeComponentUrl = row.FIN_Fee_Component__c === undefined ? '' : `/lightning/r/${row.FIN_Fee_Component__c}/view`;
                    const feeComponentName = row.FIN_Fee_Component__c === undefined ? '' : row.FIN_Fee_Component__r.Name;

                    // Get the image URL value and the Status from the formula field
                    const regex = /<img src="(.*?)"[^>]*?>\s*(Active|Inactive)$/;
                    const matches = row.FIN_Status__c.match(regex);
                    const imageURL = matches ? matches[1] : '';
                    const status = matches ? matches[2] : '';

                    return {
                        ...row,
                        feeUrl,
                        feeName,
                        nameUrl,
                        imageURL,
                        status,
                        contextUrl,
                        contextName,
                        feeComponentUrl,
                        feeComponentName
                    };
                })
                this.loading = false;
            })
            .catch((error) => {
                this.loading = false;
                console.log(error);
            });
    }

    // display onload only configured in App builder number of records when 'View all' button is not clicked
    get displayedAssociations() {
        return this.isViewAll
            ? this.relatedAssociations
            : this.relatedAssociations.slice(0, this.recordsToDisplay);
    }

    // change the value on 'View all' button to show more or less records
    handleViewAll() {
        this.isViewAll = !this.isViewAll;
    }

    // change label of the 'Vew all' button based on current state
    get viewAllLabel() {
        return this.isViewAll ? 'View less' : 'View all';
    }

    // refresh data table with fresh data
    refreshData() {
        this.loading = true;
        this.loadLibraryAssociations();
    }
    get returnedRecords() {
        return this.relatedAssociations.length > 0
    }
}