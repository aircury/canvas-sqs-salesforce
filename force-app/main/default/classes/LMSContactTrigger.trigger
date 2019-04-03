trigger LMSContactTrigger on Contact (after update) {
    if (system.isFuture()) {
        return;
    }

    for (Id contactId : Trigger.newMap.keySet() ) {
        Contact oldContact = Trigger.oldMap.get(contactId), newContact = Trigger.newMap.get(contactId);

        if (oldContact.FirstName != newContact.FirstName  ||
            oldContact.LastName != newContact.LastName  ||
            oldContact.Prefered_Name__c != newContact.Prefered_Name__c ||
            oldContact.Email != newContact.Email
        ) {
            LMS.onContactUpdate(contactId, oldContact.Email, newContact.Email);
        }
    }
}

