/*******************************************************************************
@description This is a basic trigger handler for the User Object.
@author Huron Consulting Group

Revision (s): 
*******************************************************************************/
public class UserApplicationTriggerHandler {
	@testVisible
	public static Boolean forceCreateUser = false;
	//Assigns community users the Application Community permission set.
	public static void afterInsert(Map<Id,User> newMap){
		Application_Setting__c setting = Application_Setting__c.getOrgDefaults();
		Set<Id> userIds = new Set<Id>();
		for(User usr : newMap.values()){
			if(forceCreateUser == true || Site.getSiteId() != null){
				Set<Id> profileIds = new Set<Id>();
				for(String s : setting.Community_Profile_Ids__c.split(';')){
					profileIds.add((Id)s);
				}
				if(profileIds.contains(usr.profileId)){
					userIds.add(usr.Id);
				}
			}
		}
		if(userIds.size()>0){
			createPermissionAssignments(userIds,setting.Permission_Set_Id__c);
		}
	}
	
	@future
	public static void createPermissionAssignments(Set<Id> userIds, Id permissionSetId){
		List<PermissionSetAssignment> permissionAssignments = new List<PermissionSetAssignment>();
		for(Id usrId : userIds){
			permissionAssignments.add(new PermissionSetAssignment(AssigneeId=usrId,PermissionSetId=permissionSetId));
		}
		if(permissionAssignments.size()>0){
			insert permissionAssignments;
		}
	}
}