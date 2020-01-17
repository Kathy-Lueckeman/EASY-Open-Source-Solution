/*******************************************************************************
@description This controller is used to create a new application for a user who already has a community account
@author Huron Consulting Group
*******************************************************************************/
public class ApplicationCreate {
	
    public Id contactId {get;set;}
    public Contact con {get;set;}
    public Application__c app {get;set;}
    public ApplicationQuestionSection section {get;set;}
    public List<Requirement_Item__c> items {get;set;}
    public Map<Id, Program__c> intendedPrograms {get;set;}
    public transient String additionalDataString {get;set;}
    public Set<String> contactFields {get;set;}
   	
    public Application_Control__c appControl {
        get {
            if (appControl == null)
                appControl = ApplicationUtilities.getApplicationControls(ApexPages.currentPage().getParameters().get('at'));
            return appControl;
        } set;
    }
    
    /*******************************************************************************
    * @description Initialize the page - Sets up requirements
    ********************************************************************************/
    public PageReference init() {
		
        // Exit if there is no Application Control to reference
        if (appControl == null)
            return null;
        
        // Get contact id from user or URL parameter if standard user
        contactId = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;
        if (UserInfo.getUserType().equals('Standard'))
            contactId = Id.valueOf(ApexPages.currentPage().getParameters().get('contactId'));
        
        setup(null, null); // Do setup of all objects
        
        app.Contact__c = contactId; // Assign contact to application
        
        // Take user straight to checklist if we don't want to ask any questions
		if (section.groups.isEmpty())
            return save();
        
        return null; // Return null by default
    }
    
    /*******************************************************************************
    * @description 
    ********************************************************************************/
    public void setup(ApplicationQuestionGroup firstGroup, ApplicationQuestionGroup lastGroup) {
        
        // Initialize contact and application
        con = new Contact();
        app = new Application__c(Application_Control__c = appControl.Id, Application_Status__c = appControl.Application_Start_Status__c);
		
        // List of question groups to display
        List<ApplicationQuestionGroup> groups = new List<ApplicationQuestionGroup>();
        
        // Add first group to beginning
        if (firstGroup != null)
            groups.add(firstGroup);
        
        // Query for Requirement Items and Questions to display on Application Creation
        items = [SELECT Id, File_Types__c, Requirement__r.Application_Creation_Display_Order__c, Active__c, Required__c, Required_Number_of_Children__c, Maximum_Number_of_Children__c, Requirement__r.Name, Name, Label__c,
                 Instructions__c, Intended_Program__c, Application_Status__c, Applicant_Type__c, Citizenship__c, Degree_Type__c, Delivery_Type__c,
                 Residency__c, School_College__c, Student_Type__c, RecordType.DeveloperName, Allow_Text_Entry__c, Related_List_Object__c, Related_List_Object_Master__c,
                 Related_List_Object_Master_Field__c, Related_List_Where_Clause__c, Holding_Record_Id__c, Internal_Requirement_Item__c, Editable_Application_Status__c,
                 Internal_Only__c, Requirement__r.Internal_Only__c, Internal_Only_Applicant_Instructions__c, Allow_Supporting_Documentation_Upload__c, Required_Supporting_Documentation__c,
                 Generic_Filter_1__c, Generic_Filter_2__c, Generic_Filter_3__c, Generic_Filter_4__c,
                 (SELECT Id, Active__c, Required__c, Label__c, Intended_Program__c, Application_Status__c, Applicant_Type__c, Citizenship__c,
                  Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c, Student_Type__c, RecordType.DeveloperName,
                  Picklist_Values__c, Placeholder__c, Length__c, Help_Text__c, Dependency_Logic__c, Dependency_Behavior__c, Related_Object_Field__c, Name_Field_API_Name__c,
                  Lookup_Object__c, Lookup_Where_Clause__c, New_Reference_Field__c, Contact_Field__c, Application_Field__c, External_Email_Field__c, Hardcoded_Value__c, Static_Text__c,
                  URL_Parameter__c, Editable_Application_Status__c, Display_as_Picklist__c, Generic_Filter_1__c, Generic_Filter_2__c, Generic_Filter_3__c, Generic_Filter_4__c
                  FROM Questions__r WHERE Active__c = :true ORDER BY Display_Order__c ASC NULLS LAST)
                 FROM Requirement_Item__c WHERE Requirement__r.Application_Control__c = :appControl.Id AND Requirement__r.Show_on_Application_Creation__c = :true
                 AND Requirement__r.Active__c = :true AND Active__c = :true ORDER BY Display_Order__c ASC NULLS LAST];
        
        
        
        // Query for contact if we have one
        if (contactId != null) {
            
            // Loop over questions and get contact fields
        	contactFields = new Set<String>();
        	for (Requirement_Item__c ri:items)
            	for (Question__c q:ri.Questions__r)
            		if (String.isNotBlank(q.Contact_Field__c))
            			contactFields.add(q.Contact_Field__c.toLowerCase());
            
            // Query for contact
            if (!contactFields.isEmpty()) {
                contactFields.addAll(new Set<String>{'id', 'mailingstreet', 'mailingcity', 'mailingpostalcode', 'otherstreet', 'othercity', 'otherpostalcode'});
        		if (Account.sObjectType.getDescribe().fields.getMap().containsKey('BillingCountryCode'))
            		contactFields.addAll(new Set<String>{'mailingstatecode', 'mailingcountrycode', 'otherstatecode', 'othercountrycode'});
        		else
            		contactFields.addAll(new Set<String>{'mailingstate', 'mailingcountry', 'otherstate', 'othercountry'});
                String query = 'SELECT ' + String.join(new List<String>(contactFields), ',') + ' FROM Contact WHERE Id = :contactId';
                con = ((List<Contact>)Database.query(query)).get(0);
            }
        }
        
        // Get map of requirement responses
        Map<Id, Requirement_Response__c> responses = new Map<Id, Requirement_Response__c>();
        Map<String, Map<String, SObjectField>> fields = new Map<String, Map<String, SObjectField>>();
        for (Requirement_Item__c i:items) {
            responses.put(i.Id, new Requirement_Response__c(Requirement_Item__c = i.Id));
            if (i.RecordType.DeveloperName == 'Related_Object')
                fields.put(i.Related_List_Object__c, Schema.getGlobalDescribe().get(i.Related_List_Object__c).getDescribe().fields.getMap());
        }
        
        // Create question groups for requirements we should display
        for (Requirement_Item__c i:items)
            if ((String.isBlank(i.Requirement__r.Application_Creation_Display_Order__c) || i.Requirement__r.Application_Creation_Display_Order__c.equals('Before Term/Program Questions')) && ApplicationFilter.filter(app, i))
                groups.add(ApplicationQuestionSection.createQuestionGroup(con, app, i, null, responses.get(i.Id), null, fields, true));
        
        ApplicationQuestion programQuestion;
        
        // Add term and program questions if not hidden
        if (!appControl.Hide_Term_Program__c) {
            
            // Get map of intended programs with id as key
            List<Program__c> progs = [SELECT Id, Name, Academic_Level__c, Program_Name_on_Application__c, Active__c, Applicant_Type__c, Citizenship__c, Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c, Student_Type__c, Hide_Applicant_Type__c, Hide_Citizenship__c, Hide_Student_Type__c, Number_of_Applications_Limit__c, Generic_Filter_1__c, Generic_Filter_2__c, Generic_Filter_3__c, Generic_Filter_4__c FROM Program__c WHERE Hide_from_Application__c = :false AND Active__c = :true ORDER BY Name ASC];
            intendedPrograms = new Map<Id, Program__c>(progs);
            
            // Create new program question and add to list
            programQuestion = new ApplicationQuestion(con, app, '', app, 'Intended_Program__c');
            programQuestion.addQuestionObject(new Question__c(Label__c = 'What program are you applying to?', Required__c = app.Application_Status__c, Active__c = true, URL_Parameter__c = 'Program'));
            programQuestion.addIntendedProgramFilteringList(progs);
            
            // Get map of term names with id as key
            List<Id> termIds = new List<Id>();
            List<String> termNames = new List<String>();
            for (Academic_Term__c at:[SELECT Id, Name FROM Academic_Term__c WHERE Application_Status__c = :'Active' ORDER BY Activate_Application_Date__c ASC]) {
                termIds.add(at.Id);
                termNames.add(at.Name);
            }
            
            // Create new term question and add to list
            ApplicationQuestion termQuestion = new ApplicationQuestion(con, app, '', app, 'Intended_Term_of_Entry__c');
            termQuestion.addQuestionObject(new Question__c(Label__c = 'What term are you applying for?', Required__c = app.Application_Status__c, Active__c = true, URL_Parameter__c = 'Term'));
            termQuestion.setReferenceOptions(termIds, termNames);
                        
            
            // Create silent start date question
            String silentStartDate; 
            silentStartDate = app.Generic_Filter_1__c;
          //  app.Generic_Filter_1__c = silentStartDate;
         
            // Create new startdate question and add to list
             ApplicationQuestion startDateQuestion = new ApplicationQuestion(con, app, '', app, 'Generic_Filter_1__c');
             startDateQuestion.addQuestionObject(new Question__c(Label__c = 'Select a Start Date', Required__c = app.Application_Status__c, Active__c = true, URL_Parameter__c = 'StartDate'));
             startDateQuestion.writeResponse(silentStartDate); 
            
            
            // Create question group out of term/program questions and add to list
            groups.add(new ApplicationQuestionGroup(new List<ApplicationQuestion>{ termQuestion, programQuestion, startDateQuestion}));
        }
        
        // Create question groups for requirements we should display
        for (Requirement_Item__c i:items)
            if (String.isNotBlank(i.Requirement__r.Application_Creation_Display_Order__c) && i.Requirement__r.Application_Creation_Display_Order__c.equals('After Term/Program Questions') && ApplicationFilter.filter(app, i))
                groups.add(ApplicationQuestionSection.createQuestionGroup(con, app, i, null, responses.get(i.Id), null, fields, true));
        
        // Get map of Question Dependencies with Question ids as key
        Map<Id, List<Question_Dependency__c>> dQuestions = new Map<Id, List<Question_Dependency__c>>();
        for (Question_Dependency__c dq:[SELECT Id, Question__c, Controlling_Question__c, Value__c, ValueCheckbox__c, RecordType.DeveloperName
                                		FROM Question_Dependency__c WHERE Question__r.Requirement_Item__r.Requirement__r.Application_Control__c = :appControl.Id
                                		AND Question__r.Requirement_Item__r.Requirement__r.Show_on_Application_Creation__c = :true]) {
            
            // Add new list to map if we don't have one yet
            if (!dQuestions.containsKey(dq.Question__c))
                dQuestions.put(dq.Question__c, new List<Question_Dependency__c>());
            
            // Add Question Dependency to list
            dQuestions.get(dq.Question__c).add(dq);
        }
        
        // Add last group to end
        if (lastGroup != null)
            groups.add(lastGroup);
        
        // Create new section out of groups
        section = new ApplicationQuestionSection(groups);
        section.addDependencies(dQuestions, null);
        
        if (programQuestion != null)
            programQuestion.section = section;
    }
	
    /*******************************************************************************
    * @description Saves a new application based on the answers from the VisualForce page
    ********************************************************************************/
    public PageReference save() {
        
        section.pushValuesToObjects();
        Savepoint sp = Database.setSavepoint(); // Set savepoint in case we need to roll-back
        Boolean dmlException = false;
        
        // Try to do save and catch exceptions
        try {
            
            // Throw exception if not all required fields have been filled-out
            String errorMessage = checkFields();
            if (errorMessage != null)
                throw new ApplicationUtilities.ApplicationException(errorMessage, false, true);
            
            return new PageReference(saveApplication());
        
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
        
        return null; // Return null if exception caught
    }
    
    /*******************************************************************************
    * @description Returns error message if not all fields required fields are filled-out, null otherwise
    ********************************************************************************/
    public String checkFields() {
        
        // Populates the application based on answers from the visualforce page
        for (ApplicationQuestionGroup aqg:section.groups) {
            if (aqg.questionGroup) {
                for (ApplicationQuestion question:aqg.questions) {
                    if (String.isNotBlank(question.fieldName) && question.response != null) {
                        
                        question.processValue();
                        
                        if (question.question != null && String.isNotBlank(question.question.Required__c) && question.ShowQuestion && String.isBlank(String.valueOf(question.resp)))
                            return question.label + ' is required to start your application.';
                    }
                }
            } else if (aqg.relatedObject) {
                if (ApplicationUtilities.containsValue(aqg.item.Required__c, app.Application_Status__c) && aqg.item.Required_Number_of_Children__c != null && (aqg.relatedObjects == null || aqg.relatedObjects.size() < aqg.item.Required_Number_of_Children__c))
                    return 'At least ' + aqg.item.Required_Number_of_Children__c + ' ' + (String.isBlank(aqg.item.Label__c) ? aqg.item.Name : aqg.item.Label__c) + ' record' + (aqg.item.Required_Number_of_Children__c > 1 ? 's are' : ' is') + ' required to start your application.';
            }
        }
        
        section.pushValuesToObjects();
        
        // Check to see if term/program are valid if not hidden
        if (!appControl.Hide_Term_Program__c) {
            
            // Throw exception if invalid program was selected
            String programError = 'The selected program is not available.';
            Program__c ip = intendedPrograms.get(app.Intended_Program__c);
            if (!ApplicationFilter.filter(app, ip, false))
                return programError;
            if (String.isNotBlank(ip.Hide_Applicant_Type__c) && String.isNotBlank(app.Applicant_Type__c) && (new Set<String>(ip.Hide_Applicant_Type__c.split(';'))).contains(app.Applicant_Type__c))
                return programError;
            if (String.isNotBlank(ip.Hide_Student_Type__c) && String.isNotBlank(app.Student_Type__c) && (new Set<String>(ip.Hide_Student_Type__c.split(';'))).contains(app.Student_Type__c))
                return programError;
            if (String.isNotBlank(ip.Hide_Citizenship__c) && String.isNotBlank(app.Citizenship__c) && (new Set<String>(ip.Hide_Citizenship__c.split(';'))).contains(app.Citizenship__c))
                return programError;
            
            // Throw exception if invalid term was selected
            Boolean termLocked = false;
            for (Intended_Program_Term__c ipt:[SELECT Id, Applicant_Type__c, Application_Status__c, Citizenship__c, Degree_Type__c, Delivery_Type__c,
                                               Residency__c, School_College__c, Student_Type__c, Intended_Program__c, Generic_Filter_1__c,
                                               Generic_Filter_2__c, Generic_Filter_3__c, Generic_Filter_4__c FROM Intended_Program_Term__c
                                               WHERE Academic_Term__c = :app.Intended_Term_of_Entry__c AND Application_Status__c = :'Inactive'
                                               AND (Intended_Program__c = :app.Intended_Program__c OR Intended_Program__c = :null)]) {
                
                if (ApplicationFilter.filter(app, ipt, false))
                    return 'The selected program is not available for this term.';
            }
            
            // Check to make sure selections are valid for number of applications limit
            if (app.Contact__c != null && String.isNotBlank(ip.Number_of_Applications_Limit__c)) {
                for (Application__c a:[SELECT Id, Intended_Program__c, Intended_Term_of_Entry__c FROM Application__c WHERE Contact__c = :app.Contact__c]) {
                    if (ip.Number_of_Applications_Limit__c.equals('One Application'))
                        return 'You already have an application. Only one application is allowed.';
                    else if ((ip.Number_of_Applications_Limit__c.equals('One Application Per Term') || ip.Number_of_Applications_Limit__c.equals('One Application Per Term Per Program')) && app.Intended_Term_of_Entry__c == a.Intended_Term_of_Entry__c)
                        return 'You already have an application for this term. Only one application per term is allowed.';
                    else if (ip.Number_of_Applications_Limit__c.equals('One Application Per Program') && app.Intended_Program__c == a.Intended_Program__c)
                        return 'You already have an application for this program. Only one application per program is allowed.';
                    else if (ip.Number_of_Applications_Limit__c.equals('One Application Per Term and Program') && app.Intended_Program__c == a.Intended_Program__c && app.Intended_Term_of_Entry__c == a.Intended_Term_of_Entry__c)
                        return 'You already have an application for this program and term. Only one application per program and term is allowed.';
                }
            }
        }
        
        return null;
    }
    
    /*******************************************************************************
    * @description Saves application and returns URL to new application checklist
    ********************************************************************************/
    public String saveApplication() {
        
        app.Id = null;
        insert app; // Insert application
        
        if (con.Id != null) update con; // Update contact
        
        // Serialize additionalData if we have it
        transient Map<String, Object> additionalData;
        if (String.isNotBlank(additionalDataString))
            additionalData = (Map<String, Object>)JSON.deserializeUntyped(additionalDataString);
        
        // Process all values for section
        section.processValues(additionalData);
        
        // Get list of requirement responses to insert
        List<Requirement_Response__c> rrLst = new List<Requirement_Response__c>();
        for (ApplicationQuestionGroup aqg:section.groups) {
            if (aqg.response != null) {
                aqg.response.Application__c = app.Id;
                aqg.response.Id = null;
                rrLst.add(aqg.response);
            }
        }
        
        upsert rrLst; // Insert requirement responses
        
        // Get list of question responses to insert
        List<Question_Response__c> qResponses = new List<Question_Response__c>();
        List<SObject> relatedObjects = new List<SObject>();
        for (ApplicationQuestionGroup g:section.groups) {
            if (g.questionGroup && g.response != null && g.questions != null) {
                for (ApplicationQuestion q:g.questions) {
                    if (q.response != null) {
                        q.response.Requirement_Response__c = g.response.Id;
                        q.response.Id = null;
                        qResponses.add(q.response);
                    }
                }
            }
        }
        
        upsert qResponses; // Insert question responses
        
        // Return URL for checklist page for new application
        return '/apex/ApplicationChecklist?applicationId=' + app.Id + '&contactId=' + app.Contact__c + (String.isBlank(appControl.URL_Parameter__c) ? '' : ('&at=' + appControl.URL_Parameter__c));
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