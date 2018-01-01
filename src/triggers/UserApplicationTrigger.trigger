/*******************************************************************************
@description This is a generic trigger that will call the UserApplicationTriggerHandler methods.
@author Huron Consulting Group

Revision (s): 
*******************************************************************************/
trigger UserApplicationTrigger on User (after insert) {
    if(Trigger.isAfter && Trigger.isInsert){
        UserApplicationTriggerHandler.afterInsert(Trigger.newMap);
    }
}