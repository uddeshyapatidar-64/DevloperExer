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
}