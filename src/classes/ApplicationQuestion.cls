/*******************************************************************************
@description This class controls the visibility and behavior of Questions
@author Huron Consulting Group

Revision (s): 
*******************************************************************************/
public class ApplicationQuestion {

    public static final Map<Schema.DisplayType, String> fieldTypes = new Map<Schema.DisplayType, String> {
        Schema.DisplayType.ADDRESS => 'Address',
        Schema.DisplayType.BOOLEAN => 'Checkbox',
        Schema.DisplayType.CURRENCY => 'Currency',
        Schema.DisplayType.DATE => 'Date',
        Schema.DisplayType.DATETIME => 'DateTime',
        Schema.DisplayType.DOUBLE => 'Decimal',
        Schema.DisplayType.EMAIL => 'Email',
        Schema.DisplayType.ENCRYPTEDSTRING => 'TextEncrypted',
        Schema.DisplayType.INTEGER => 'Integer',
        Schema.DisplayType.MULTIPICKLIST => 'MultiPicklist',
        Schema.DisplayType.PERCENT => 'Percent',
        Schema.DisplayType.PHONE => 'Phone',
        Schema.DisplayType.PICKLIST => 'Picklist',
        Schema.DisplayType.REFERENCE => 'Reference',
        Schema.DisplayType.STRING => 'Text',
        Schema.DisplayType.TEXTAREA => 'TextArea',
        Schema.DisplayType.URL => 'URL'
    };

    public String fieldType { get { return tableBased ? question.RecordType.DeveloperName : fieldTypes.get(displayType); } }

    public String label {get;private set;}
    public sObject obj {get;set;}
    public String fieldName {get;set;}
    public String value;
    public Boolean checkboxValue;
    public Decimal decimalValue;
    public Datetime datetimeValue;
    public Date dateValue;
    public String textEncryptedValue;
    public Integer integerValue;
    public String placeholder {get; set;}
    public Integer length {get;set;}
    public Schema.DisplayType displayType {get;set;}
    public Contact con {get;set;}
    public Account acc {get;set;}
    public Boolean placeholderQuestion{get;set;}
    public Object resp{get;set;}
    private Requirement_Response__c reqResponse;
    public ApplicationQuestionSection section {private get; set;}
    
    /*******************************************************************************
    * @description Returns the list of selct options for picklists/multiselect picklists and radios. For Intended Programs we also filter out programs that should not be shown.
    ********************************************************************************/
    public List<SelectOption> options {
        get {
            
            if (intendedPrograms != null) {
                if (section != null) section.pushValuesToObjects();
                options = new List<SelectOption>{new SelectOption('', '--None--')};
                
                for (Program__c ip:intendedPrograms)
                    if (showIntendedProgram(ip))
                        options.add(new SelectOption(ip.Id, String.isNotBlank(ip.Program_Name_on_Application__c) ? ip.Program_Name_on_Application__c : ip.Name));
                
                return options;
                
            } else if (dependentOptions == null) {
                return options;
            }
            
            return dependentOptions.get(controllingQuestion.response.ValueText__c);
    	}
        private set;
    }
	
   	public List<String> multiPicklistValues;
   	public Question__c question { get;
        set {
            
            this.question = value;
            
            if (String.isNotBlank(value.URL_Parameter__c) && ApexPages.currentPage().getParameters().keySet().contains(question.URL_Parameter__c))
                this.writeResponse(ApexPages.currentPage().getParameters().get(value.URL_Parameter__c));
            
            if (question.RecordType != null && question.RecordType.DeveloperName.equals('Reference') && String.isNotBlank(question.Lookup_Object__c) && question.Display_as_Picklist__c) {
				
                options = new List<SelectOption>{new SelectOption('', '--None--')};
                
                String nameField = String.isBlank(question.Name_Field_API_Name__c) ? 'Name' : question.Name_Field_API_Name__c;
                
                String queryString = 'SELECT ' + nameField + ', Id FROM ' + question.Lookup_object__c;
                if (String.isNotBlank(question.Lookup_Where_Clause__c))
                    queryString += ' WHERE ' + question.Lookup_Where_Clause__c + ' ORDER BY ' + nameField;
                
                for (SObject sObj:database.query(queryString))
                    options.add(new SelectOption(sObj.Id, String.isBlank((String)sObj.get(nameField)) ? String.valueOf(sObj.Id) : (String)sObj.get(nameField)));
            }
        }
    }
    private Boolean tableBased {get;set;}
    public Question_Response__c response {get;set;}
    public String helpText {get;set;}
	
    public Contact contact {get;set;}
    public Application__c application {get;set;}
    public ApplicationQuestion controllingQuestion {get;set;}
    public List<SObject> filteringValues;
    public String filteringLabel;
    public String filteringValue;
    public Map<ApplicationQuestion,Set<String>> multiControllingQuestions;
    public List<Program__c> intendedPrograms;
    public Set<String> showValues {get;set;}
    public Map<String, List<SelectOption>> dependentOptions {get;set;}
    public Boolean radio {get;set;}
    public List<Question_Dependency__c> dQuestions {get;set;}
    public Map<Id, ApplicationQuestion> controllingQuestions {get;set;}
    private Map<Id, Object> controllingResponses {get;set;}

    public static Boolean stateAndCountryPicklistEnabled = false;
    public static Boolean getStateAndCountryPicklistEnabled() { return stateAndCountryPicklistEnabled; }
    static{
        Map<String, Schema.SObjectField> accountFields = Account.sObjectType.getDescribe().fields.getMap();
		stateAndCountryPicklistEnabled = accountFields.containsKey('BillingCountryCode');
    }

    private Boolean forceShowQuestion = false;
    public Boolean showRelatedLabel{get;private set;}

    /*******************************************************************************
    * @description Determines if this question is editable based on the application status
    ********************************************************************************/
    public Boolean isEditable {
        get {
            if (!UserInfo.getUserType().equals('Standard') || Test.isRunningTest()) {
                if (application != null && String.isNotBlank(application.Application_Status__c)) {
                    if (question != null && (String.isBlank(question.Editable_Application_Status__c) || (String.isNotBlank(question.Editable_Application_Status__c) && new Set<String>(question.Editable_Application_Status__c.split(';')).contains(application.Application_Status__c))))
                        return true;
                    
                    return question == null;
                }
            }
            return true;
        }
    }

    /*******************************************************************************
    * @description calculates if this specific program should be shown
    ********************************************************************************/
    public Boolean showIntendedProgram(Program__c ip) {
        if ((String.isNotBlank(ip.Hide_Applicant_Type__c) && (String.isNotBlank(application.Applicant_Type__c) && (new Set<String>(ip.Hide_Applicant_Type__c.split(';'))).contains(application.Applicant_Type__c))) || (String.isNotBlank(ip.Applicant_Type__c) && (String.isBlank(application.Applicant_Type__c) || !(new Set<String>(ip.Applicant_Type__c.split(';'))).contains(application.Applicant_Type__c))))
            return false;

        if ((String.isNotBlank(ip.Hide_Citizenship__c) && (String.isNotBlank(application.Citizenship__c) && (new Set<String>(ip.Hide_Citizenship__c.split(';'))).contains(application.Citizenship__c))) || (String.isNotBlank(ip.Citizenship__c) && (String.isBlank(application.Citizenship__c) || !(new Set<String>(ip.Citizenship__c.split(';'))).contains(application.Citizenship__c))))
            return false;

        if ((String.isNotBlank(ip.Hide_Student_Type__c) && (String.isNotBlank(application.Student_Type__c) && (new Set<String>(ip.Hide_Student_Type__c.split(';'))).contains(application.Student_Type__c))) || (String.isNotBlank(ip.Student_Type__c) && (String.isBlank(application.Student_Type__c) || !(new Set<String>(ip.Student_Type__c.split(';'))).contains(application.Student_Type__c))))
            return false;
        
        if (String.isNotBlank(ip.School_College__c) && (String.isBlank(application.School_College__c) || !(new Set<String>(ip.School_College__c.split(';'))).contains(application.School_College__c)))
            return false;
        
        if (String.isNotBlank(ip.Delivery_Type__c) && (String.isBlank(application.Delivery_Type__c) || !(new Set<String>(ip.Delivery_Type__c.split(';'))).contains(application.Delivery_Type__c)))
            return false;
        
        if (String.isNotBlank(ip.Degree_Type__c) && (String.isBlank(application.Degree_Type__c) || !(new Set<String>(ip.Degree_Type__c.split(';'))).contains(application.Degree_Type__c)))
            return false;
        
        if (String.isNotBlank(ip.Residency__c) && (String.isBlank(application.Residency__c) || ip.Residency__c.equals(application.Residency__c)))
            return false;

        return true;
    }
    /*******************************************************************************
    * @description checks the answer to multiple questions to decide if a dependent question should be shown
    ********************************************************************************/
    public Boolean checkMultiControllingQuestion() {
        
        if (multiControllingQuestions != null)
            for (ApplicationQuestion aq:multiControllingQuestions.keySet())
                if (aq.response == null || String.isBlank(aq.response.ValueText__c) || !multiControllingQuestions.get(aq).contains(aq.response.ValueText__c))
                    return false;
		
        return true;
    }
	
    public Boolean getShowQuestion() {
        return this.showQuestion;
    }
    
    /*******************************************************************************
    * @description Calculates whether to render the question or not
    ********************************************************************************/
    public Boolean dependencyCalculated = false;
    public Boolean showQuestion {
        get {
            return dependencyCalculated ? showQuestion : getShowQuestion(null);
    	}
        set;
    }
    
    public Boolean getShowQuestion(SObject obj) {

        if (dependencyCalculated)
            return showQuestion;

        if (forceShowQuestion == true)
            return returnShowQuestion(true, obj);
        
        if (application != null && question != null && !ApplicationFilter.filter(application, question))
            return returnShowQuestion(false, obj);
        
        if (dQuestions == null || controllingQuestions == null || dQuestions.isEmpty() || controllingQuestions.isEmpty())
            return returnShowQuestion(true, obj);
        
        Boolean satisfied;
        if (controllingResponses == null)
            controllingResponses = new Map<Id, Object>();
        
        // Based on Question_Dependency records, should this question be shown.
        if (String.isBlank(question.Dependency_Logic__c) || question.Dependency_Logic__c.equals('AND')) {
            
            satisfied = true;
            
            for (Question_Dependency__c qd:dQuestions) {
                
                if (controllingQuestions.containsKey(qd.Controlling_Question__c)) {
                    
                    ApplicationQuestion cq = controllingQuestions.get(qd.Controlling_Question__c);
                    
                    if (!controllingResponses.containsKey(qd.Controlling_Question__c)) {
                    	cq.getShowQuestion(obj);
                    	controllingResponses.put(qd.Controlling_Question__c, cq.getResponseObject(obj));
                    }
                    
                    Object resp = controllingResponses.get(qd.Controlling_Question__c);
                    
                    if (qd.RecordType.DeveloperName.equals('Checkbox') && Boolean.valueOf(qd.ValueCheckbox__c) != (Boolean)resp) {
                        satisfied = false;
                        break;
                    } else if (qd.RecordType.DeveloperName.equals('Picklist') && (String.isBlank(String.valueOf(resp)) || !qd.Value__c.equals((String)resp))) {
                        satisfied = false;
                        break;
                    } else if (qd.RecordType.DeveloperName.equals('Multi_Select_Picklist')) {
                        
                        if (String.isNotBlank(String.valueOf(resp)) && String.isNotBlank(qd.Value__c)) {
                            
                            Set<String> multiItems = new Set<String>(((String)resp).split(';'));
                            
                            Boolean foundValue = false;
                            for (String controlItem : qd.Value__c.split(';')) {
                                if (multiItems.contains(controlItem)) { 
                                    foundValue = true;
                                    break;
                                }
                            }
                            
                            if (!foundValue) {
                                satisfied = false;
                                break;
                            }
                            
                        } else {
                            satisfied = false;
                            break;
                        }
                    }
                }
            }
            
        } else {
            
            satisfied = false;
            
            for (Question_Dependency__c qd:dQuestions) {
                
                if (!controllingQuestions.containsKey(qd.Controlling_Question__c)) {
                    satisfied = true;
                    break;
                }
                
                ApplicationQuestion cq = controllingQuestions.get(qd.Controlling_Question__c);
                
                if (!controllingResponses.containsKey(qd.Controlling_Question__c)) {
                    cq.getShowQuestion(obj);
                    controllingResponses.put(qd.Controlling_Question__c, cq.getResponseObject(obj));
                }
                
                Object resp = controllingResponses.get(qd.Controlling_Question__c);
                
                if (qd.RecordType.DeveloperName.equals('Checkbox') && Boolean.valueOf(qd.ValueCheckbox__c) == (Boolean)resp) {
                    satisfied = true;
                    break;
                } else if (qd.RecordType.DeveloperName.equals('Picklist') && String.isNotBlank(String.valueOf(resp)) && qd.Value__c.equals((String)resp)) {
                    satisfied = true;
                    break;
                } else if (qd.RecordType.DeveloperName.equals('Multi_Select_Picklist')) {
                    
                    if (String.isNotBlank(String.valueOf(resp)) && String.isNotBlank(qd.Value__c)) {
                        
                        Set<String> multiItems = new Set<String>(((String)resp).split(';'));
                        
                        Boolean foundValue = false;
                        for (String controlItem : qd.Value__c.split(';')) {
                            if (multiItems.contains(controlItem)) {
                                foundValue = true;
                                break;
                            }
                        }
                        
                        if (foundValue) {
                            satisfied = true;
                            break;
                        }
                    }
                }
            }
        }
        
        Boolean showBehavior = String.isBlank(question.Dependency_Behavior__c) || question.Dependency_Behavior__c.equals('Show');
        Boolean ret = (satisfied && showBehavior) || (!satisfied && !showBehavior);
        
        return returnShowQuestion(ret, obj);
    }
    
    private Boolean returnShowQuestion(Boolean ret, SObject obj) {

        dependencyCalculated = true;
        
        if (!ret && isEditable) {
            
            if (response != null) {
                
                response.ValueCheckbox__c = false;
                response.ValueCurrency__c = null;
                response.ValueDate__c = null;
                response.ValueDateTime__c = null;
                response.ValueEmail__c = null;
                response.ValueNumber__c = null;
                response.ValuePercent__c = null;
                response.ValuePhone__c = null;
                response.ValueText__c = null;
                response.ValueTextEncrypted__c = null;
                response.ValueTextArea__c = null;
                response.ValueLongTextArea__c = null;
                response.ValueURL__c = null;
            }
            
            if (obj != null && String.isNotBlank(question.Related_Object_Field__c))
                obj.put(question.Related_Object_Field__c, null);
            
            if (String.isNotBlank(question.Contact_Field__c) && !fieldType.equals('Address')) {
                if (obj != null && obj instanceof Contact) obj.put(question.Contact_Field__c, null);
                if (contact != null) contact.put(question.Contact_Field__c, null);
            }
            
            if (String.isNotBlank(question.Application_Field__c)) {
                if (obj != null && obj instanceof Application__c) obj.put(question.Application_Field__c, null);
                if (application != null) application.put(question.Application_Field__c, null);
            }
            
        } else if (question != null && String.isNotBlank(question.Hardcoded_Value__c) && (fieldType.equals('Text') || fieldType.equals('Radio') || fieldType.contains('Picklist'))) {
            
            if (response != null)
                response.ValueText__c = question.Hardcoded_Value__c;
            
            ret = false;
        }
        
        resp = getResponseObject();
        controllingResponses = null;
        showQuestion = ret;
        return ret;
    }

    public ApplicationQuestion(Schema.FieldSetMember fsm, SObject obj, Schema.SObjectType objType){
        question = new Question__c(Related_Object_Field__c=fsm.getFieldPath(), Label__c = fsm.getLabel());
        this.con = new Contact();
        label = question.Label__c;
        this.displayType = fsm.getType();
        this.obj = obj;
        forceShowQuestion = true;
        showRelatedLabel = true;
        tableBased = false;
        if (!fsm.getFieldPath().contains('.') || Test.isRunningTest()) {
            Schema.DescribeFieldResult dfr = !fsm.getFieldPath().contains('.') ? objType.getDescribe().fields.getMap().get(fsm.getFieldPath().toLowerCase()).getDescribe() : Account.Industry.getDescribe();
            this.displayType = dfr.getType();
            if (displayType == Schema.DisplayType.PICKLIST || displayType == Schema.DisplayType.MULTIPICKLIST) {
                options = new List<SelectOption>();
                if (displayType == Schema.DisplayType.PICKLIST)
                    options.add(new SelectOption('', '--None--'));
                for (Schema.PicklistEntry ple:dfr.getPicklistValues())
                    options.add(new SelectOption(ple.getValue(), ple.getLabel()));
            }
        }
    }
    public ApplicationQuestion(SObject obj, Question__c question, Question_Response__c response) {
        
        this.response = response;
		
        if (obj != null && obj.getSObjectType() == Schema.getGlobalDescribe().get('Contact')) {
            this.contact = (Contact)obj;
            if (String.isNotBlank(question.Contact_Field__c))
                fieldName = question.Contact_Field__c;
            if (String.isNotBlank(question.Contact_Field__c) && String.isNotBlank(question.Hardcoded_Value__c)) {
                this.response.ValueText__c = question.Hardcoded_Value__c;
                this.contact.put(question.Contact_Field__c, question.Hardcoded_Value__c);
            }
        } else if (obj != null && obj.getSObjectType() == Application__c.SObjectType) {
            this.application = (Application__c)obj;
            if (String.isNotBlank(question.Application_Field__c))
                fieldName = question.Application_Field__c;
            if (String.isNotBlank(question.Application_Field__c) && String.isNotBlank(question.Hardcoded_Value__c)) {
                this.response.ValueText__c = question.Hardcoded_Value__c;
                this.application.put(question.Application_Field__c, question.Hardcoded_Value__c);
            }
        } else {
            this.obj = obj;
        }
        
        this.question = question;
        this.tableBased = true;
		
        if (question.Length__c == null || (question.Length__c > 255 && !fieldType.equals('LongTextArea')))
            this.length = 255;
        else
            this.length = (Integer)question.Length__c;
		
        this.placeholder = question.Placeholder__c;
		
        this.label = question.Label__c;
		
        this.helpText = question.Help_Text__c;
        
        populateContactFieldOnResponse();
        
        this.con = new Contact();
        if(String.isNotBlank(fieldType)){
            if (fieldType.contains('Picklist') || fieldType.equals('Radio')) {
                options = new List<SelectOption>();
                if (fieldType.equals('Picklist')) options.add(new SelectOption('', '--None--'));
                if(String.isNotBlank(question.Picklist_Values__c)){
                    for (String str:question.Picklist_Values__c.split('\n')){
                        options.add(new SelectOption(str.trim(), str.trim()));
                    }
                }
            }
            if (fieldType.equals('Address') && this.response != null) {
                this.con.put(stateAndCountryPicklistEnabled ? 'MailingStateCode' : 'MailingState', this.response.State__c);
                this.con.put(stateAndCountryPicklistEnabled ? 'MailingCountryCode' : 'MailingCountry', this.response.Country__c);
            }
        }
    }
    
    public ApplicationQuestion(Contact con, Application__c app, String label, sObject obj, String fieldName) {
        init(con, app, label, obj, fieldName, '', null);
    }
    
    public ApplicationQuestion(Contact con, Application__c app, String label, sObject obj, String fieldName, String placeholder) {
        init(con, app, label, obj, fieldName, placeholder, null);
    }
    
    public ApplicationQuestion(Contact con, Application__c app, String label, sObject obj, String fieldName, Schema.DisplayType displayType, Boolean placeholderQuestion) {
        init(con, app, label, obj, fieldName, '', displayType);
        this.placeholderQuestion = placeholderQuestion;
    }
    
    /*******************************************************************************
    * @description Sets up the question based on the input object and display type
    ********************************************************************************/
    private void init(Contact con, Application__c app, String label, sObject obj, String fieldName, String placeholder, Schema.DisplayType dType) {
        
        this.tableBased = false;
        this.contact = con;
		this.application = app;
        this.label = label;
        this.obj = obj;
        this.fieldName = fieldName;
        this.placeholder = placeholder;
        this.con = new Contact();
        this.response = new Question_Response__c();
        
        Schema.DescribeFieldResult dfr = obj.getSObjectType().getDescribe().fields.getMap().get(fieldName).getDescribe();
        if (dType == null) {
            displayType = dfr.getType();
            this.length = dfr.getLength();
        } else {
            displayType = dType;
        }

        if (displayType == Schema.DisplayType.PICKLIST || displayType == Schema.DisplayType.MULTIPICKLIST) {
            options = new List<SelectOption>();
            if (displayType == Schema.DisplayType.PICKLIST)
                options.add(new SelectOption('', '--None--'));
            for (Schema.PicklistEntry ple:dfr.getPicklistValues())
                options.add(new SelectOption(ple.getValue(), ple.getLabel()));
        }
        
        populateContactFieldOnResponse();
    }
    public void updateOptions(String gfilter, String applicantType) {
        System.debug('gfilter: ' + gfilter);
        System.debug('FIELD: ' + this.fieldName);
        if (String.isBlank(gfilter)) return;

        if (this.fieldName == 'Intended_Program__c') {
            Academic_Term__c at = [SELECT Id, Name, Term_Start_Date__c, Term_End_Date__c FROM Academic_Term__c WHERE Id = :gfilter];

            String q = 'SELECT Id, Name, Academic_Level__c, Program_Name_on_Application__c, Active__c, Applicant_Type__c,'+
                    'Citizenship__c, Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c, Student_Type__c,'+
                    'Hide_Applicant_Type__c, Hide_Citizenship__c, Hide_Student_Type__c, Number_of_Applications_Limit__c,'+
                    'Generic_Filter_1__c, Generic_Filter_2__c, Generic_Filter_3__c, Generic_Filter_4__c '+
                    'FROM Program__c '+
                    'WHERE Hide_from_Application__c = false AND Active__c = true ';

            List<String> dateStrings = new List<String>{
                    '\'In the future\'', '\'Right away\''
            };
            if (String.isNotBlank(applicantType)) {
                q += 'AND Career__c = :applicantType ';
            }
            if (!'Undecided-- show me all programs'.equalsIgnoreCase(at.Name)) {
                while (at.Term_Start_Date__c <= at.Term_End_Date__c) {
                    dateStrings.add('\'' + at.Term_Start_Date__c.format() + '\'');
                    at.Term_Start_Date__c = at.Term_Start_Date__c.addDays(1);
                }
                System.debug(dateStrings);
                q +=
                String.format('AND Generic_Filter_1__c INCLUDES ({0}) ORDER BY Name ASC',
                    new List<String> {
                            String.join(dateStrings, ',')
                    });
            } else {
                q += 'ORDER BY Name ASC';
            }

            System.debug(q);
            List<Program__c> progs = Database.query(q);

            this.addIntendedProgramFilteringList(progs);
        } else if (this.fieldName == 'Generic_Filter_1__c') {// to update options for start date

            Map<String, String> optionsMap = new Map<String, String> {
                    'In the future' => 'In the future',
                    'Right away' => 'Right away'
            };

            List<String> term_program_ids = gfilter.split(';');
            if (term_program_ids.size() < 2) {
                System.debug('__DEBUG__');
                this.setPicklistOptions(optionsMap);
                return;
            }
            Id termId = term_program_ids.get(0);
            Id programId = term_program_ids.get(1);

            Academic_Term__c at = [SELECT Id, Term_Start_Date__c, Term_End_Date__c FROM Academic_Term__c WHERE Id = :termId];
            List<String> dateStrings = new List<String>();
            while(at.Term_Start_Date__c <= at.Term_End_Date__c) {
                dateStrings.add(at.Term_Start_Date__c.format());
                at.Term_Start_Date__c = at.Term_Start_Date__c.addDays(1);
            }
            System.debug(JSON.serialize(dateStrings));
            Program__c p = [SELECT Generic_Filter_1__c FROM Program__c  WHERE Id = :programId ORDER BY Name ASC];
            System.debug(p.Generic_Filter_1__c);

            for (String d : dateStrings) {
                if (p.Generic_Filter_1__c.contains(d)) {
                    optionsMap.put(d, d);
                }
            }
            this.setPicklistOptions(optionsMap);
        }

    }
    public void populateContactFieldOnResponse() {
        
        try {
        	if (String.isNotBlank(fieldName) && response != null) {
            	
                if (contact != null && contact.get(fieldName) != null) {
                    
                    if (fieldName == 'MailingAddress' || fieldName == 'OtherAddress') {
                        String prefix = question.Contact_Field__c.equals('MailingAddress') ? 'Mailing' : 'Other';
                    	response.Street__c = (String)contact.get(prefix + 'Street');
                    	response.City__c = (String)contact.get(prefix + 'City');
                    	response.PostalCode__c = (String)contact.get(prefix + 'PostalCode');
                    	response.State__c = (String)contact.get(prefix + (stateAndCountryPicklistEnabled ? 'StateCode' : 'State'));
                    	response.Country__c = (String)contact.get(prefix + (stateAndCountryPicklistEnabled ? 'CountryCode' : 'Country'));
                    } else {
                    	writeResponse(String.valueOf(contact.get(fieldName)));
                    }
                } else if (application != null && application.get(fieldName) != null) {
                    writeResponse(String.valueOf(application.get(fieldName)));
                }
            }
        } catch (Exception e) {}
    }
    
    public void addQuestionObject(Question__c question) {
        
        this.question = question;
        this.placeholder = question.Placeholder__c;
        this.label = question.Label__c;
        this.helpText = question.Help_Text__c;
        
        if (String.isNotBlank(fieldType)) {
            if (fieldType.contains('Picklist') || fieldType.equals('Radio')) {
                options = new List<SelectOption>();
                if (fieldType.equals('Picklist'))
                    options.add(new SelectOption('', '--None--'));
                if (String.isNotBlank(question.Picklist_Values__c))
                    for (String str:question.Picklist_Values__c.split('\n'))
                        options.add(new SelectOption(str.trim(), str.trim()));
            }
        }
    }
    
    /*******************************************************************************
    * @description Should we render this question's label
    ********************************************************************************/
    public void showRelatedLabel(Boolean showLabel){
        showRelatedLabel = showLabel;
    }
    /*******************************************************************************
    * @description Sets the picklist options for this question
    ********************************************************************************/
    public void setPicklistOptions(Map<String, String> options) {
        this.options = new List<SelectOption>{new SelectOption('', '--None--')};
        for (String k:options.keySet())
            this.options.add(new SelectOption(k, options.get(k)));
    }
    /*******************************************************************************
    * @description Sets the picklist options based on a lookup field
    ********************************************************************************/
    public void setReferenceOptions(Map<Id, String> refOptions) {
        this.options = new List<SelectOption>{new SelectOption('', '--None--')};
        for (Id k:refOptions.keySet())
            this.options.add(new SelectOption(String.valueOf(k), refOptions.get(k)));
    }
    /*******************************************************************************
    * @description Sets the picklist options based on a lookup field
    ********************************************************************************/
    public void setReferenceOptions(List<Id> optionValues, List<String> optionLabels) {
        this.options = new List<SelectOption>{new SelectOption('', '--None--')};
        for (Integer i = 0; i < optionValues.size(); i++)
            this.options.add(new SelectOption(String.valueOf(optionValues[i]), optionLabels[i]));
    }
    /*******************************************************************************
    * @description Sets which question controls the rendering of this question
    ********************************************************************************/
    public void addControllingQuestion(ApplicationQuestion controllingQuestion, Set<String> showValues) {
        this.controllingQuestion = controllingQuestion;
        this.showValues = showValues;
    }
    /*******************************************************************************
    * @description Sets which questions controls the rendering of this question
    ********************************************************************************/
    public void addControllingQuestions(Map<ApplicationQuestion,Set<String>> controllingQuestions) {
        this.multiControllingQuestions = controllingQuestions;
    }
    /*******************************************************************************
    * @description Set up the list of question dependencies to control the rendering of this question
    ********************************************************************************/
    public void addQuestionDependencies(List<Question_Dependency__c> dQuestions, Map<Id, ApplicationQuestion> controllingQuestions) {
        this.dQuestions = dQuestions;
        this.controllingQuestions = controllingQuestions;
    }

    /*******************************************************************************
    * @description Set up the list of dependency options in the form of a map to determine the rendering of this question
    ********************************************************************************/
    public void addDependentOptions(Map<String, Map<String, String>> depOptions) {
        this.dependentOptions = new Map<String, List<SelectOption>>();
        for (String k:depOptions.keySet()) {
            List<SelectOption> ops = new List<SelectOption>{new SelectOption('', '--None--')};
            for (String dk:depOptions.get(k).keySet()){
                if(depOptions.get(k).get(dk) != null){
                ops.add(new SelectOption(dk, depOptions.get(k).get(dk)));
                }
            }
            this.dependentOptions.put(k, ops);
        }
    }
    /*******************************************************************************
    * @description Add the list of all Program records
    ********************************************************************************/
    public void addIntendedProgramFilteringList(List<Program__c> intendedPrograms){
        this.intendedPrograms = intendedPrograms;
    }
    /*******************************************************************************
    * @description Turns a picklist field into a radio
    ********************************************************************************/
    public void makeRadio() {
        this.options.remove(0);
        this.radio = true;
    }

    /*******************************************************************************
    * @description Find the relevant response value and prepares the question response to be saved
    ********************************************************************************/
    public void processValue() {

        if (response != null) {
            
            if (fieldType.equals('Address')) {
                response.State__c = (String)con.get(stateAndCountryPicklistEnabled ? 'MailingStateCode' : 'MailingState');
                response.Country__c = (String)con.get(stateAndCountryPicklistEnabled ? 'MailingCountryCode' : 'MailingCountry');
                
                if (contact != null && question != null && (question.Contact_Field__c == 'MailingAddress' || question.Contact_Field__c == 'OtherAddress')) {
                    String prefix = question.Contact_Field__c.equals('MailingAddress') ? 'Mailing' : 'Other';
                    contact.put(prefix + 'Street', response.Street__c);
                    contact.put(prefix + 'City', response.City__c);
                    contact.put(prefix + 'PostalCode', response.PostalCode__c);
                    contact.put(prefix + (stateAndCountryPicklistEnabled ? 'StateCode' : 'State'), response.State__c);
                    contact.put(prefix + (stateAndCountryPicklistEnabled ? 'CountryCode' : 'Country'), response.Country__c);
                }
            }
            
            response.IsShown__c = showQuestion;
            if (question != null)
                response.IsRequired__c = (application != null && String.isNotBlank(question.Required__c) && new Set<String>(question.Required__c.split(';')).contains(application.Application_Status__c));
            
            resp = getResponseObject();
            if (resp == null)
                response.PopulatedOn__c = null;
            else if (response.IsShown__c && response.IsRequired__c && (!response.IsPopulated__c || response.PopulatedOn__c == null))
                response.PopulatedOn__c = System.NOW();
            
            response.IsPopulated__c = resp != null;
            if (obj != null) {
                try {
                    obj.put(fieldName, resp);
                } catch (Exception e) {}
            }
        }
    }
    
    public Object getResponseObject() {
        return getResponseObject(null);
    }
    
    public Object getResponseObject(SObject obj) {
        
        if (obj != null && question != null && String.isNotBlank(question.Related_Object_Field__c))
            return obj.get(question.Related_Object_Field__c);
        else if (response == null)
            return null;
        else if (String.isNotBlank(response.ValueText__c))
			return response.ValueText__c;
		else if (fieldType != null && fieldType.equals('Checkbox'))
			return response.ValueCheckbox__c;
		else if (String.isNotBlank(response.ValuePhone__c))
			return response.ValuePhone__c;
		else if (String.isNotBlank(response.ValueEmail__c))
			return response.ValueEmail__c;
		else if (response.ValueCurrency__c != null)
			return response.ValueCurrency__c;
		else if (response.ValueDate__c != null)
			return response.ValueDate__c;
		else if (response.ValueDateTime__c != null)
			return response.ValueDateTime__c;
		else if (response.ValueNumber__c != null)
			return response.ValueNumber__c;
		else if (response.ValuePercent__c != null)
			return response.ValuePercent__c;
		else if (String.isNotBlank(response.ValueTextArea__c))
			return response.ValueTextArea__c;
		else if (String.isNotBlank(response.ValueLongTextArea__c))
			return response.ValueLongTextArea__c;
		else if (String.isNotBlank(response.ValueURL__c))
			return response.ValueURL__c;
		else if (String.isNotBlank(response.ValueTextEncrypted__c))
			return response.ValueTextEncrypted__c;
        else if (String.isNotBlank(response.Country__c) && ((!response.Country__c.equals('US') && !response.Country__c.equals('United States')) || String.isNotBlank(response.State__c)) && String.isNotBlank(response.Street__c) && String.isNotBlank(response.PostalCode__c) && String.isNotBlank(response.City__c))
            return response.Street__c + ', ' + response.City__c + ', ' + (String.isBlank(response.State__c) ? '' : response.State__c + ', ') + response.Country__c + ', ' + response.PostalCode__c;
        return null;
    }
    
    // Writes a string to the response based on the questions type
    public void writeResponse(String resp) {
        try {
            
            if (fieldType.equals('Checkbox') && (resp.toLowerCase().equals('true') || resp.toLowerCase().equals('false')))
                response.ValueCheckbox__c = Boolean.valueOf(resp);
            else if (fieldType.equals('Currency'))
                response.ValueCurrency__c = Double.valueOf(resp);
            else if (fieldType.equals('Date'))
                response.ValueDate__c = Date.valueOf(resp);
            else if (fieldType.equals('DateTime'))
                response.ValueDateTime__c = Datetime.valueOfGmt(resp);
            else if (fieldType.equals('Email'))
                response.ValueEmail__c = resp;
            else if (fieldType.equals('Number') || fieldType.equals('Decimal') || fieldType.equals('Integer'))
                response.ValueNumber__c = Double.valueOf(resp);
            else if (fieldType.equals('Percent'))
                response.ValuePercent__c = Double.valueOf(resp);
            else if (fieldType.equals('Phone'))
                response.ValuePhone__c = resp;
            else if (fieldType.equals('Picklist') || fieldType.equals('MultiPicklist') || fieldType.equals('Radio') || fieldType.equals('Text'))
                response.ValueText__c = resp;
            else if (fieldType.equals('TextEncrypted'))
                response.ValueTextEncrypted__c = resp;
            else if (fieldType.equals('TextArea'))
                response.ValueTextArea__c = resp;
            else if (fieldType.equals('LongTextArea'))
                response.ValueLongTextArea__c = resp;
            else if (fieldType.equals('URL'))
                response.ValueURL__c = resp;
            
            if (response.PopulatedOn__c == null)
                response.PopulatedOn__c = System.NOW();
            response.IsPopulated__c = true;
        } catch (Exception e) {}
    }
	
    /*******************************************************************************
    * @description Set the Requirement Response for this Application Question
    ********************************************************************************/
    public void setRequirementResponse(Requirement_Response__c reqResponse){
        this.reqResponse = reqResponse;
    }
    /*******************************************************************************
    * @description Send a reminder email for Exteral Requirements
    ********************************************************************************/
    public void sendReminder(){
        // Deprecated
    }
    public Datetime getDatetimeValue() {
        return response.ValueDateTime__c;
    }

    public void setDatetimeValue(Datetime v) {
        response.ValueDateTime__c = v;
    }

    public Date getDateValue() {
        return response.ValueDate__c;
    }

    public void setDateValue(Date v) {
        response.ValueDate__c = v;
    }

    public List<String> getMultiPicklistValues() {
        return String.isNotBlank(response.ValueText__c) ? response.ValueText__c.split(';') : new List<String>();
    }

    public void setMultiPicklistValues(List<String> v) {
        response.ValueText__c = String.join(v, ';');
    }
    
    public String getTextEncryptedValue() {
        return response.ValueTextEncrypted__c;
    }

    public void setTextEncryptedValue(String v) {
        response.ValueTextEncrypted__c = v;
    }
}