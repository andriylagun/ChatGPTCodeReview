import {ShowToastEvent} from "lightning/platformShowToastEvent";

export function handlePlatformEvent(event) {
        const { Status__c, Message__c } = event.data.payload;

        const toastEvent = new ShowToastEvent({
            title: Status__c === 'success' ? 'Success' : 'Error',
            message: Message__c,
            variant: Status__c
        });

        this.dispatchEvent(toastEvent);
}