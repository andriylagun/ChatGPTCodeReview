import { LightningElement, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import ID_FIELD from '@salesforce/schema/User.Id';
import CURRENT_REGION_FIELD from '@salesforce/schema/User.FIN_Current_Region__c';
import AVALIABLE_REGION_FIELD from '@salesforce/schema/User.FIN_Available_Regions__c';
import Id from '@salesforce/user/Id';

const FIELDS  = [CURRENT_REGION_FIELD, AVALIABLE_REGION_FIELD];

export default class RegionSelect extends LightningElement {
    avaliableRegions;
    options = [];
    disableRegionEdit = true;
    value;
    baseRegion;

    @wire(getRecord, { recordId: Id, fields: FIELDS }) 
    currentUser({error, data}) {
        if (data) {
            this.value = data.fields.FIN_Current_Region__c.value;
            this.baseRegion = data.fields.FIN_Current_Region__c.value;
            this.avaliableRegions = data.fields.FIN_Available_Regions__c.value.split(';');

            for(var region of this.avaliableRegions) {
                this.options.push({label: region, value: region});
            }

            if (this.options.length > 1) {
                this.disableRegionEdit = false;
            }
        } else if (error) {
            this.error = error;
        }
    }

    handleChange(event) {
        if (event.detail.value != this.baseRegion) {
            const fields = {};
            fields[ID_FIELD.fieldApiName] = Id;
            fields[CURRENT_REGION_FIELD.fieldApiName] = event.detail.value;

            const recordInput = { fields };

            updateRecord(recordInput)
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Region was updated',
                            variant: 'success'
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
    }
}