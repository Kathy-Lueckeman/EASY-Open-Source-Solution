@isTest
public class UserApplicationTriggerHandlerTest {
	public static TestMethod void testUserCreation(){
		Application_Setting__c setting = new Application_Setting__c();
		setting.Community_URL__c = 'test';
		setting.Community_Profile_Ids__c = UserInfo.getProfileId();
		setting.Permission_Set_Id__c = [SELECT Id FROM PermissionSet WHERE Name = 'Application_Community' limit 1].Id;
		insert setting;
		User u = new User();
		Test.startTest();
		u.username = 'testcreateuser@example.com';
		u.email = 'testcreateuser@example.com';
		u.lastName = 'testlastname';
		u.alias = 'testcomm';
		u.languagelocalekey = UserInfo.getLanguage();
		u.localesidkey = UserInfo.getLocale();
		u.emailEncodingKey = 'UTF-8';
		u.timeZoneSidKey = 'GMT';
		u.profileId = UserInfo.getProfileId();
		UserApplicationTriggerHandler.forceCreateUser = true;
		insert u;
		Test.stopTest();
		Integer psaCount = [SELECT count() FROM PermissionSetAssignment WHERE AssigneeId=:u.Id and PermissionSetId=:setting.Permission_Set_Id__c limit 1];
		System.assertEquals(1,psaCount);
	}
}