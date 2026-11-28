/**
 * @author Uddeshya Patidar
 * @date 2026-11-28
 *
 * @group General
 *
 * @description Entry point for Contact trigger events.
 *              Delegates Contact processing to ContactTriggerHandler.
 *
 * @see ContactTriggerHandler
 */
trigger ContactTrigger on Contact (
    before insert,
    before update,
    after insert,
    after update,
    after delete,
    after undelete
) {
    if (Trigger.isBefore) {
        ContactTriggerHandler.handleBeforeSave(Trigger.new);
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUndelete) {
            ContactTriggerHandler.handleAfterSave(Trigger.new, null);
        } else if (Trigger.isUpdate) {
            ContactTriggerHandler.handleAfterSave(Trigger.new, Trigger.old);
        } else if (Trigger.isDelete) {
            ContactTriggerHandler.handleAfterDelete(Trigger.old);
        }
    }
}