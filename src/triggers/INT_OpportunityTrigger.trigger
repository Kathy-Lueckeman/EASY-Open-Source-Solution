trigger INT_OpportunityTrigger on Opportunity (before update, after insert) {
	INT_OpportunityContactRoleHandler h = new INT_OpportunityContactRoleHandler();
    h.run(Trigger.new, Trigger.old);
}