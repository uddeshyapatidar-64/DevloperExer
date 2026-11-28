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
                        'Multiple primary Contacts were selected for ' +
                        'the same Account. Only one is allowed.'
                    );
                }
            }
        }
    }
}