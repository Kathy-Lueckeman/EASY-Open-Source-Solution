/*****************************************
* File: INT_OpportunityContactRoleHandler
* Author: Sierra-Cedar
******************************************/
public class INT_OpportunityContactRoleHandler {
    public void run(List<SObject> newlist, List<SObject> oldlist) {
        
        List<OpportunityContactRole> rolesToInsert = new List<OpportunityContactRole>();
        List<Opportunity> nonExcludedOpps = new List<Opportunity>();
        List<Opportunity> allOpportunities = new List<Opportunity>();
        Map<String, String> contactAccountIdMap = new Map<String, String>();
        List<String> contactIds = new List<String>();

        // Select all of the custom setting exclusions and gather the names in a list
        List<String> exclusionNames = new List<String>();

        for (OpportunityContactRoleExclusion__c anExclusion : OpportunityContactRoleExclusion__c.getall().values()) {
            exclusionNames.add(anExclusion.Name);
        }

        // Find the record types which match the names
        Map<String, RecordType> excludeTypeMap = new Map<String, RecordType>();

        // Add exclude record types to map
        for (RecordType aType : [
            SELECT Id, Name, SobjectType
            FROM RecordType
            WHERE SobjectType = 'Opportunity'
            AND Name IN :exclusionNames
        ]) {
            excludeTypeMap.put(aType.Id, aType);
        }

        for (SObject anSObject : newlist) {
            Opportunity anOpportunity = (Opportunity) anSObject;
            allOpportunities.add(anOpportunity);

            if (anOpportunity.Contact__c != null) {
                contactIds.add(anOpportunity.Contact__c);
            }
        }

        if (contactIds.size() > 0) {
            for (Contact aContact : [SELECT AccountId FROM Contact WHERE Id IN :contactIds]) {
                contactAccountIdMap.put(aContact.Id, aContact.AccountId);
            }
        }

        for (SObject anSObject : newlist) {
            Opportunity anOpportunity = (Opportunity) anSObject;

            if (anOpportunity.Contact__c != null && excludeTypeMap.get(anOpportunity.recordTypeId) == null) {
                nonExcludedOpps.add(anOpportunity);
                OpportunityContactRole newRole = new OpportunityContactRole(
                    ContactId = anOpportunity.Contact__c,
                    OpportunityId = anOpportunity.Id,
                    IsPrimary = true,
                    Role = 'Opportunity Contact'
                );
                rolesToInsert.add(newRole);
            }
        }

        // Identify roles to delete
        List<OpportunityContactRole> rolesToDelete = [
            SELECT Id, ContactId, IsPrimary, OpportunityId, Role
            FROM OpportunityContactRole
            WHERE OpportunityId IN :nonExcludedOpps
        ];

        // Insert Opportunity Contact Roles
        insert rolesToInsert;

        // Retrieve Inserted Role Ids to upate primary, doesn't work in same context as Lead Convert
        // Keep an eye on Idea Exchange below, @future context is handling this for now
        // https://success.salesforce.com/ideaview?id=08730000000HKbnAAG
        List<String> roleIds = new List<String>();

        for (OpportunityContactRole aRole : rolesToInsert) {
            roleIds.add(aRole.Id);
        }

        if (roleIds.size() > 0) {
            if (System.isBatch()) {
                updateRoles(roleIds);
            } else {
                updateRolesFuture(roleIds);
            }
        }

        // Delete the roles
        delete rolesToDelete;
    }

    // Update opportunity contact roles in another context, Salesforce currently not setting primary
    @future
    public static void updateRolesFuture(List<String> roleIds) {
        updateRoles(roleIds);
    }

    public static void updateRoles(List<String> roleIds) {
        List<OpportunityContactRole> roles = [SELECT Id, IsPrimary FROM OpportunityContactRole WHERE Id IN :roleIds];

        for (OpportunityContactRole aRole : roles) {
            aRole.IsPrimary = true;
        }

        update roles;
    }
}