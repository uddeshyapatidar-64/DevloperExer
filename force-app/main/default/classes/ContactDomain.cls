/**
 * @author Uddeshya Patidar
 * @date 2026-11-28
 *
 * @group General
 *
 * @description Contains Contact business rules and validations.
 *              Ensures that an Account has at most one primary Contact.
 *
 * @see ContactTrigger
 * @see ContactTriggerHandler
 */
public without sharing class ContactDomain {

    /**
     * @description Validates that an Account does not have more than
     *              one primary Contact. Handles both existing records
     *              and multiple incoming Contacts in bulk operations.
     *
     * @param contacts List of incoming Contact records to validate.
     *
     * @return void
     *
     * @example
     * ContactDomain.validatePrimaryContact(Trigger.new);
     *
     * @see ContactTriggerHandler
     */
    public static void validatePrimaryContact(List<Contact> contacts) {

        Set<Id> accountIds = new Set<Id>();
        Set<Id> incomingContactIds = new Set<Id>();
        Map<Id, List<Contact>> primaryContactsByAccount = new Map<Id, List<Contact>>();
        for (Contact con : contacts) {
            if (con.Id != null) {
                incomingContactIds.add(con.Id);
            }

            if (con.AccountId != null && con.Is_Primary__c == true) {
                accountIds.add(con.AccountId);

                if (!primaryContactsByAccount.containsKey(con.AccountId)) {
                    primaryContactsByAccount.put(con.AccountId, new List<Contact>());
                }
                primaryContactsByAccount.get(con.AccountId).add(con);
            }
        }

        if (accountIds.isEmpty()) {
            return;
        }

        Set<Id> accountsWithExistingPrimary = new Set<Id>();
        for (Contact existingContact : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds AND Is_Primary__c = true]) {
            if (!incomingContactIds.contains(existingContact.Id)) {
                accountsWithExistingPrimary.add(existingContact.AccountId);
            }
        }

        for (Id accountId : primaryContactsByAccount.keySet()) {
            List<Contact> incomingPrimaryContacts =primaryContactsByAccount.get(accountId);
            if (accountsWithExistingPrimary.contains(accountId)) {

                for (Contact con : incomingPrimaryContacts) {
                    con.addError(
                        'This Account already has a primary Contact. Only one primary Contact is allowed per Account.'
                    );
                }
            }
            else if (incomingPrimaryContacts.size() > 1) {
                for (Contact con : incomingPrimaryContacts) {
                    con.addError(
                        'Multiple primary Contacts were selected for the same Account. Only one is allowed.'
                    );
                }
            }
        }
    }

    /**
     * @description Synchronizes the Account's Primary Contact Email
     *              with the Email of its primary Contact.
     *              Clears the Account field when no primary Contact exists.
     *
     *              Handles Contact insertion, updates, deletion,
     *              undelete, and reparenting in bulk.
     *
     * @param newContacts The new versions of Contact records.
     * @param oldContacts The previous versions of Contact records.
     * @return void
     *
     * @example
     * ContactDomain.synchronizePrimaryContactEmail(
     *     Trigger.new,
     *     Trigger.old
     * );
     *
     * @see ContactTriggerHandler
     */
    public static void synchronizePrimaryContactEmail(List<Contact> newContacts,
        List<Contact> oldContacts
    ) {
        Set<Id> affectedAccountIds = new Set<Id>();
        if (newContacts != null) {
            for (Contact con : newContacts) {
                if (con.AccountId != null) {
                    affectedAccountIds.add(con.AccountId);
                }
            }
        }
    
        if (oldContacts != null) {
            for (Contact con : oldContacts) {
                if (con.AccountId != null) {
                    affectedAccountIds.add(con.AccountId);
                }
            }
        }
    
        if (affectedAccountIds.isEmpty()) {
            return;
        }
    
        Map<Id, String> primaryEmailByAccount = new Map<Id, String>();
    
        for (Contact con : [SELECT Id, AccountId, Email FROM Contact WHERE AccountId IN :affectedAccountIds AND Is_Primary__c = true ORDER BY CreatedDate ASC, Id ASC]) {

            if (!primaryEmailByAccount.containsKey(con.AccountId)) {
                primaryEmailByAccount.put(con.AccountId, con.Email);
            }
        }
        
        List<Account> accountsToUpdate = new List<Account>();
    
        for (Account acc : [SELECT Id, Primary_Contact_Email__c FROM Account WHERE Id IN :affectedAccountIds]) {
            String expectedEmail = primaryEmailByAccount.get(acc.Id);
    
            if (acc.Primary_Contact_Email__c != expectedEmail) {
                accountsToUpdate.add(new Account(Id = acc.Id, Primary_Contact_Email__c = expectedEmail));
            }
        }
 
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    /**
     * @description Recalculates and synchronizes the Contact Count
     *              for all Accounts affected by Contact changes.
     *
     *              Handles insertion, updates, deletion, undelete,
     *              and reparenting of Contacts in bulk.
     *
     * @param newContacts The new versions of Contact records.
     * @param oldContacts The previous versions of Contact records.
     * @return void
     *
     * @example
     * ContactDomain.updateAccountContactCount(
     *     Trigger.new,
     *     Trigger.old
     * );
     *
     * @see ContactTriggerHandler
     */
    public static void updateAccountContactCount(
        List<Contact> newContacts,
        List<Contact> oldContacts
    ) {
        Set<Id> affectedAccountIds = new Set<Id>();
    
        if (newContacts != null) {
            for (Contact con : newContacts) {
                if (con.AccountId != null) {
                    affectedAccountIds.add(con.AccountId);
                }
            }
        }
    
        if (oldContacts != null) {
            for (Contact con : oldContacts) {
                if (con.AccountId != null) {
                    affectedAccountIds.add(con.AccountId);
                }
            }
        }
    
        if (affectedAccountIds.isEmpty()) {
            return;
        }
    
        Map<Id, Integer> contactCountByAccount = new Map<Id, Integer>();
    
        for (AggregateResult result : [SELECT AccountId, COUNT(Id) contactCount FROM Contact
            WHERE AccountId IN :affectedAccountIds
            GROUP BY AccountId
        ]) {
            contactCountByAccount.put(
                (Id) result.get('AccountId'),
                (Integer) result.get('contactCount')
            );
        }
    
        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : [SELECT Id, Contact_Count__c
            FROM Account
            WHERE Id IN :affectedAccountIds
        ]) {
            Integer expectedCount = contactCountByAccount.containsKey(acc.Id)
                ? contactCountByAccount.get(acc.Id)
                : 0;
    
            if (acc.Contact_Count__c != expectedCount) {
                accountsToUpdate.add(
                    new Account(
                        Id = acc.Id,
                        Contact_Count__c = expectedCount
                    )
                );
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}