/**
 * @author Uddeshya Patidar
 * @date 2026-11-28
 *
 * @group General
 *
 * @description Handles Contact trigger events and delegates
 *              business logic to the ContactDomain class.
 *
 * @see ContactTrigger
 * @see ContactDomain
 */
public with sharing class ContactTriggerHandler {

    /**
     * @description Handles Contact before insert and before update events.
     *
     * @param newContacts List of incoming Contact records.
     *
     * @return void
     *
     * @example
     * ContactTriggerHandler.handleBeforeSave(Trigger.new);
     *
     * @see ContactDomain.validatePrimaryContact
     */
    public static void handleBeforeSave(List<Contact> newContacts) {

        ContactDomain.validatePrimaryContact(newContacts);

    }

    /**
     * @description Handles Contact after insert, after update,
     *              and after undelete events.
     *
     * @param newContacts The new versions of the Contact records.
     * @param oldContacts The previous versions of the Contact records.
     * @return void
     *
     * @see ContactDomain.synchronizePrimaryContactEmail
     */
    public static void handleAfterSave(
        List<Contact> newContacts,
        List<Contact> oldContacts
    ) {
        ContactDomain.synchronizePrimaryContactEmail(newContacts, oldContacts);
    }
    
    /**
     * @description Handles Contact after delete events.
     *
     * @param deletedContacts The Contact records that were deleted.
     * @return void
     *
     * @see ContactDomain.synchronizePrimaryContactEmail
     */
    public static void handleAfterDelete(
        List<Contact> deletedContacts
    ) {
        ContactDomain.synchronizePrimaryContactEmail(null, deletedContacts);
    }
}