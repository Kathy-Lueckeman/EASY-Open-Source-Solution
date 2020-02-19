trigger INT_OpportunityTrigger on Opportunity (before update, after insert) {
    INT_OpportunityContactRoleHandler.run(Trigger.new);
}