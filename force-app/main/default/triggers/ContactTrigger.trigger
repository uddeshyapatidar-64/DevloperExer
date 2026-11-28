/**
 * @author Uddeshya
 * @date 2026-11-28
 *
 * @group General
 *
 * @description Entry point for Contact trigger events.
 *              Delegates before-save processing to ContactTriggerHandler.
 *
 * @see ContactTriggerHandler
 */
trigger ContactTrigger on Contact (before insert, before update) {

    ContactTriggerHandler.handleBeforeSave(Trigger.new);

}