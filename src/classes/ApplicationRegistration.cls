/*******************************************************************************
@description This controller is used to create a new contact, account, and application for a user without community access
@author Huron Consulting Group
*******************************************************************************/
public class ApplicationRegistration {
    
    public ApplicationCreate appCreate {get;set;}
    public Interaction__c interaction {get;set;}
    public Interaction__c extraFields {get;set;}
    private User loginUser {get;set;}
    private String loginPassword {get;set;}
    private String loginUrl {get;set;}
    
    /*******************************************************************************
    * @description Initialize the page - Sets up all of the requirements and pulls Requirements with the flag (Show on Application Creation)
    ********************************************************************************/
    public ApplicationRegistration() {
        
        // Initialize objects
        appCreate = new ApplicationCreate();
        interaction = new Interaction__c();
        extraFields = new Interaction__c();
        
        // Exit if there is no Application Control to reference
        if (appCreate.appControl == null)
            return;
        
        // Create questions for first name, last name, email, password, and password confirmation
        ApplicationQuestion firstName = new ApplicationQuestion(appCreate.con, appCreate.app, '', interaction, 'First_Name__c');
        firstName.addQuestionObject(new Question__c(Label__c = 'First Name', Required__c = appCreate.app.Application_Status__c, Active__c = true));
        ApplicationQuestion lastName = new ApplicationQuestion(appCreate.con, appCreate.app, '', interaction, 'Last_Name__c');
        lastName.addQuestionObject(new Question__c(Label__c = 'Last Name', Required__c = appCreate.app.Application_Status__c, Active__c = true));
        ApplicationQuestion email = new ApplicationQuestion(appCreate.con, appCreate.app, '', interaction, 'Email__c');
        email.addQuestionObject(new Question__c(Label__c = 'Email', Required__c = appCreate.app.Application_Status__c, Active__c = true));
        ApplicationQuestion portalPassword = new ApplicationQuestion(appCreate.con, appCreate.app, '', extraFields, 'Last_Name__c', Schema.DisplayType.ENCRYPTEDSTRING, true);
        portalPassword.addQuestionObject(new Question__c(Label__c = 'What password would you like to use for saving your application?', Required__c = appCreate.app.Application_Status__c, Active__c = true, Length__c = 40));
        ApplicationQuestion portalPasswordConfirmation = new ApplicationQuestion(appCreate.con, appCreate.app, '', extraFields, 'First_Name__c', Schema.DisplayType.ENCRYPTEDSTRING, true);
        portalPasswordConfirmation.addQuestionObject(new Question__c(Label__c = 'Please enter your password again.', Required__c = appCreate.app.Application_Status__c, Active__c = true, Length__c = 40));
        
        // Create question groups
        ApplicationQuestionGroup firstGroup = new ApplicationQuestionGroup(new List<ApplicationQuestion>{firstName, lastName, email});
        ApplicationQuestionGroup lastGroup = new ApplicationQuestionGroup(new List<ApplicationQuestion>{portalPassword, portalPasswordConfirmation});
        
        // Setup other questions
        appCreate.setup(firstGroup, lastGroup);
    }
    
    /*******************************************************************************
    * @description populates fields on the contact and application through the interactions object.
    ********************************************************************************/
    public void submit() {
        
        System.SavePoint sp = Database.setSavepoint();
        Boolean dmlException = false;
        interaction.Id = null;
        interaction.Contact__c = null;
        loginUser = null;
        loginPassword = null;
        loginUrl = null;
        
        try {
            
            // Throw exception if not all required fields have been filled-out
            String errorMessage = appCreate.checkFields();
            if (errorMessage != null)
                throw new ApplicationUtilities.ApplicationException(errorMessage, false, true);
            
            // Insert interaction to create/update Contact
            insert interaction;
            interaction = [SELECT Id, Contact__c, First_Name__c, Last_Name__c, Email__c FROM Interaction__c WHERE Id = :interaction.Id];
            Contact con = [SELECT Id, FirstName, LastName, Email, AccountId, Account.OwnerId FROM Contact WHERE Id = :interaction.Contact__c];
            appCreate.con.Id = con.Id;
            
            // Exit and roll-back if User with Email or Contact already exists
            if (![SELECT Id FROM User WHERE Username = :con.Email OR ContactId = :con.Id LIMIT 1].isEmpty())
                throw new ApplicationUtilities.ApplicationException('An account with this email already exists.', true, false);
            
            // Update Account owner to Site admin if owner is current user (guest user)
            if (con.Account.OwnerId == UserInfo.getUserId())
                update new Account(Id = con.AccountId, OwnerId = Test.isRunningTest() ? UserInfo.getUserId() : Site.getAdminId());
            
            // Assign contact to application and save
            appCreate.app.Contact__c = con.Id;
            String checklistUrl = appCreate.saveApplication();
            
            // Create user object
            User u = new User();
            u.FirstName = con.FirstName;
            u.LastName = con.LastName;
            u.Email = con.Email;
            u.Username = con.Email;
            u.CommunityNickname = (u.Email.length() > 40) ? u.Email.substring(0, 40) : u.Email;
            u.ContactId = con.Id;
            
            // Create user
            String pass = extraFields.Last_Name__c;
            String passConfirm = extraFields.First_Name__c;
            if (!Test.isRunningtest()) Site.validatePassword(u, pass, passConfirm);
            
            Id uId;
            if (!Test.isRunningTest() && pass.equals(passConfirm)) {
                uId = Site.createExternalUser(u, con.AccountId, pass, true);
                if (uId == null)
                    throw new ApplicationUtilities.ApplicationException('Error occured when creating user.', true, true);
                loginUser = new User(Id = uId, Username = u.Username);
                loginPassword = pass;
                loginUrl = checklistUrl;
            }
            
        } catch (DmlException err) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, err.getDMLMessage(0)));
            dmlException = true;
            Database.rollback(sp);
        } catch (ApplicationUtilities.ApplicationException err) {
            
            ApexPages.addMessage(new ApexPages.Message(err.isError ? ApexPages.Severity.ERROR : ApexPages.Severity.CONFIRM, err.getMessage()));
            if (err.doRollback)
                Database.rollback(sp);
            
        } catch (Exception err) {
            if (!dmlException) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, err.getMessage()));
                Database.rollback(sp);
            }
            dmlException = false;
        }
    }
    
    public PageReference login() {
        
        if (String.isNotBlank(loginUrl)) {
            insert new PermissionSetAssignment(AssigneeId = loginUser.Id, PermissionSetId = Application_Setting__c.getOrgDefaults().Permission_Set_Id__c);
            return Site.login(loginUser.Username, loginPassword, loginUrl);
        }
        
        return null;
    }
    
    @RemoteAction
    public static List<SObject> lookupSearch(String sObj, String sObjFilter, String sObjNameField, String term) {
        return new ActionWithSharing().lookupSearchWithSharing(sObj,sObjFilter,sObjNameField,term);
    }
    
    public with sharing class ActionWithSharing {
        public List<SObject> lookupSearchWithSharing(String sObj, String sObjFilter, String sObjNameField, String term) {
            if (Schema.getGlobalDescribe().get(sObj).getDescribe().isAccessible()) {
                if (String.isBlank(sObjNameField))
                    sObjNameField = 'Name';
                
                String query = 'Select Id, ' + sObjNameField + ' FROM ' + sObj + ' WHERE ' + sObjNameField+' like \'%' + String.escapeSingleQuotes(term) + '%\'';
                if (String.isNotBlank(sObjFilter))
                    query += ' AND (' + sObjFilter + ')';
                
                query += ' ORDER BY ' + sObjNameField + ' ASC';
                try {
                    return database.query(query);
                } catch(Exception e){
                    return new List<SObject>();
                }
            }
            return new List<SObject>();
        }
    }
}