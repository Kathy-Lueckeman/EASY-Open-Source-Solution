/*****************************************
* File: INT_OpportunityContactRoleHandler
* Author: Kyle Schmid, Huron Consulting Group
* Description: Creates/updates primary Opportunity Contact Roles based on the Contact__c lookup field.
* Re-worked from Sierra-Cedar's implementation included in the Interactions for Student Recruitment package.
******************************************/
public class INT_OpportunityContactRoleHandler {

    @testVisible private static final String ROLE_NAME = 'Opportunity Contact'; // Value to set the Role picklist on Opportunity Contact Role

    // Set of Opportunity Record Type IDs that are excluded from processing based on the OpportunityContactRoleExclusion__c custom setting
    private static Set<Id> excludeTypeIds {
        get {
            if (excludeTypeIds == null) {
                excludeTypeIds = new Set<Id>(); // Instantiate new set

                // Get record type name map for Opportunity and retain all exclusion names from custom setting
                Map<String, Schema.RecordTypeInfo> opportunityRecordTypes = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
                opportunityRecordTypes.keySet().retainAll(OpportunityContactRoleExclusion__c.getAll().keySet());

                // Loop over record types that still exist and add record type id to exclusion set
                for (Schema.RecordTypeInfo recordType:opportunityRecordTypes.values())
                    excludeTypeIds.add(recordType.getRecordTypeId());
            }

            return excludeTypeIds;
        } private set;
    }

    public static void run(List<Opportunity> newList) {

        // Get list of non-excluded opportunities
        List<Opportunity> nonExcludedOpps = new List<Opportunity>();
        for (Opportunity opp:newList)
            if (!excludeTypeIds.contains(opp.RecordTypeId))
                nonExcludedOpps.add(opp);

        // Exit if nothing to do here
        if (nonExcludedOpps.isEmpty()) return;

        // Re-query opportunities to get existing Opportunity Contact Roles from child relationship
        Map<Id, Opportunity> oppsWithRoles = new Map<Id, Opportunity>([SELECT Id, (SELECT Id, ContactId, IsPrimary, Role FROM OpportunityContactRoles) FROM Opportunity WHERE Id IN :nonExcludedOpps]);

        List<OpportunityContactRole> rolesToUpsert = new List<OpportunityContactRole>(); // List of Opportunity Contact Roles to upsert
        List<OpportunityContactRole> rolesToDelete = new List<OpportunityContactRole>(); // List of Opportunity Contact Roles to delete

        // Loop over opportunities and add roles to upsert/delete lists
        for (Opportunity opp:nonExcludedOpps) {

            // Get list of existing roles for opportunity
            List<OpportunityContactRole> existingRoles = oppsWithRoles.get(opp.Id).OpportunityContactRoles;

            // Delete all existing roles if Contact on Opportunity is null
            if (opp.Contact__c == null) {
                rolesToDelete.addAll(existingRoles);
                continue;
            }

            // Create new Opportunity Contact Role
            OpportunityContactRole role = new OpportunityContactRole(OpportunityId = opp.Id, ContactId = opp.Contact__c);

            // Loop over existing roles and add to delete list if different Contact or identify existing role for contact
            for (OpportunityContactRole ocr:existingRoles) {
                if (ocr.ContactId == opp.Contact__c && role.Id == null)
                    role = ocr;
                else
                        rolesToDelete.add(ocr);
            }

            // Add to upsert list if new role or need to set IsPrimary to true or Role not ROLE_NAME
            if (role.Id == null || !role.IsPrimary || role.Role != ROLE_NAME) {
                role.IsPrimary = true;
                role.Role = ROLE_NAME;
                rolesToUpsert.add(role);
            }
        }

        delete rolesToDelete; // Delete Opportunity Contact Roles
        upsert rolesToUpsert; // Upsert Opportunity Contact Roles
    }
}