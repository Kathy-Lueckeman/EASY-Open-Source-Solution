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
    public  String fieldName {get;set;}
    public String value;
    public Boolean checkboxValue;
    public Decimal decimalValue;
    public Datetime datetimeValue;
    public Date dateValue;
    public Integer integerValue;
    public String placeholder {get;private set;}
    public Integer length {get;set;}
    public Schema.DisplayType displayType {get;set;}
    public Contact con {get;set;}
    public Account acc {get;set;}
    public Boolean placeholderQuestion{get;set;}
    public Object resp{get;set;}
    private Requirement_Response__c reqResponse;
    /*******************************************************************************
    * @description Returns the list of selct options for picklists/multiselect picklists and radios. For Intended Programs we also filter out programs that should not be shown.
    ********************************************************************************/
    public List<SelectOption> options {
        get { 
            if(intendedPrograms != null){
                options = new List<SelectOption>();
                options.add(new SelectOption('','--None--'));
                for(Program__c ip : intendedPrograms){
                    if(showIntendedProgram(ip)){
                        options.add(new SelectOption(ip.Id,(String.isNotBlank(ip.Program_Name_on_Application__c)?ip.Program_Name_on_Application__c:ip.Name)));
                    }
                }
                return options;
            }else if (dependentOptions == null){
                return options;
            }
            return dependentOptions.get(controllingQuestion.response.ValueText__c);
    	}
        private set;
    }

    public List<String> multiPicklistValues;
    public Question__c question {get;set;}
    private Boolean tableBased {get;set;}
    public Question_Response__c response {get;set;}
    public String helpText {get;set;}

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

    public static Boolean stateAndCountryPicklistEnabled = false;
    public static Boolean getStateAndCountryPicklistEnabled(){return stateAndCountryPicklistEnabled;}
    static{
        Map<String, Schema.SObjectField> accountFields = Account.sObjectType.getDescribe().fields.getMap();
		stateAndCountryPicklistEnabled = accountFields.containsKey('BillingCountryCode');
    }

    private Boolean forceShowQuestion = false;
    public Boolean showRelatedLabel{get;private set;}

    /*******************************************************************************
    * @description Determines if this question is editable based on the application status
    ********************************************************************************/
    public Boolean isEditable{
        get{
            if(UserInfo.getUserType() != 'Standard'){
                if(application != null && String.isNotBlank(application.Application_Status__c)){
                    if(question != null && (String.isBlank(question.Editable_Application_Status__c) || (String.isNotBlank(question.Editable_Application_Status__c) && new Set<String>(question.Editable_Application_Status__c.split(';')).contains(application.Application_Status__c)))){
                        return true;
                    }
                    return false;
                }
            }
            return true;
        }
    }

    /*******************************************************************************
    * @description calculates if this specific program should be shown
    ********************************************************************************/
    public Boolean showIntendedProgram(Program__c ip){
        if (String.isNotBlank(ip.Hide_Applicant_Type__c) && (String.isNotBlank(application.Applicant_Type__c) && (new Set<String>(ip.Hide_Applicant_Type__c.split(';'))).contains(application.Applicant_Type__c)))
            return false;

        if (String.isNotBlank(ip.Hide_Citizenship__c) && (String.isNotBlank(application.Citizenship__c) && (new Set<String>(ip.Hide_Citizenship__c.split(';'))).contains(application.Citizenship__c)))
            return false;

        if (String.isNotBlank(ip.Hide_Student_Type__c) && (String.isNotBlank(application.Student_Type__c) && (new Set<String>(ip.Hide_Student_Type__c.split(';'))).contains(application.Student_Type__c)))
            return false;

        return true;
    }
    /*******************************************************************************
    * @description checks the answer to multiple questions to decide if a dependent question should be shown
    ********************************************************************************/
    public Boolean checkMultiControllingQuestion(){
        Boolean retValue = true;
        if(multiControllingQuestions != null){
            for(ApplicationQuestion aq : multiControllingQuestions.keySet()){
                if(aq.response == null || String.isBlank(aq.response.ValueText__c) || !multiControllingQuestions.get(aq).contains(aq.response.ValueText__c)){
                    retValue = false;
                }
            }
        }
        return retValue;
    }

    /*******************************************************************************
    * @description Calculates whether to render the question or not
    ********************************************************************************/
    public Boolean showQuestion {
        get {
            if(obj!=null && String.isNotBlank(fieldName) && response != null && fieldType != fieldTypes.get(Schema.DisplayType.ADDRESS)){
                obj.put(fieldName,response.ValueText__c);
            }
            if(forceShowQuestion == true){
                return true;
            }
            if(application != null && question != null && !ApplicationFilter.filter(application,question)){
                return false;
            }
            //Are the answers to controlling questions the right answer to render this question
            if (!tableBased){
                return (controllingQuestion == null && multiControllingQuestions == null) || ( controllingQuestion != null && String.isNotBlank(controllingQuestion.response.ValueText__c) && showValues.contains(controllingQuestion.response.ValueText__c) || (multiControllingQuestions != null && checkMultiControllingQuestion()));
            }
            if (dQuestions == null || controllingQuestions == null || dQuestions.isEmpty() || controllingQuestions.isEmpty())
                return true;
            //Based on Question_Dependency records, should this question be shown.
            if (String.isBlank(question.Dependency_Logic__c) || question.Dependency_Logic__c.equals('AND')) {
                for (Question_Dependency__c qd:dQuestions) {
                    if (controllingQuestions.containsKey(qd.Controlling_Question__c))
                        if (qd.RecordType.DeveloperName.equals('Checkbox') && controllingQuestions.get(qd.Controlling_Question__c).response != null && Boolean.valueOf(qd.ValueCheckbox__c) != controllingQuestions.get(qd.Controlling_Question__c).response.ValueCheckbox__c){
                            return String.isNotBlank(question.Dependency_Behavior__c) && question.Dependency_Behavior__c.equals('Hide');
                        }else if (qd.RecordType.DeveloperName.equals('Picklist') && (String.isBlank(controllingQuestions.get(qd.Controlling_Question__c).response.ValueText__c) || !qd.Value__c.equals(controllingQuestions.get(qd.Controlling_Question__c).response.ValueText__c)))
                        	return String.isNotBlank(question.Dependency_Behavior__c) && question.Dependency_Behavior__c.equals('Hide');
                        else if (qd.RecordType.DeveloperName.equals('Multi_Select_Picklist')){
                            if(String.isNotBlank(controllingQuestions.get(qd.Controlling_Question__c).response.ValueText__c) && String.isNotBlank(qd.Value__c)){
                                Set<String> multiItems = new Set<String>(controllingQuestions.get(qd.Controlling_Question__c).response.ValueText__c.split(';'));
                                Boolean foundValue = false;
                                for(String controlItem : qd.Value__c.split(';')){
                                    if(multiItems.contains(controlItem)){
                                        foundValue = true;
                                        break;
                                    }
                                }
                                if(!foundValue){
                                    return String.isNotBlank(question.Dependency_Behavior__c) && question.Dependency_Behavior__c.equals('Hide');
                                }
                            }else{
                                return String.isNotBlank(question.Dependency_Behavior__c) && question.Dependency_Behavior__c.equals('Hide');
                            }
                        }
                }
                return String.isBlank(question.Dependency_Behavior__c) || question.Dependency_Behavior__c.equals('Show');
            } else {
                for (Question_Dependency__c qd:dQuestions) {
                    if (!controllingQuestions.containsKey(qd.Controlling_Question__c))
                        return String.isBlank(question.Dependency_Behavior__c) || question.Dependency_Behavior__c.equals('Show');
                    else if (qd.RecordType.DeveloperName.equals('Checkbox') && Boolean.valueOf(qd.ValueCheckbox__c) == controllingQuestions.get(qd.Controlling_Question__c).response.ValueCheckbox__c)
                        return String.isBlank(question.Dependency_Behavior__c) || question.Dependency_Behavior__c.equals('Show');
                    else if (qd.RecordType.DeveloperName.equals('Picklist') && String.isNotBlank(controllingQuestions.get(qd.Controlling_Question__c).response.ValueText__c) && qd.Value__c.equals(controllingQuestions.get(qd.Controlling_Question__c).response.ValueText__c))
                        return String.isBlank(question.Dependency_Behavior__c) || question.Dependency_Behavior__c.equals('Show');
                    else if (qd.RecordType.DeveloperName.equals('Multi_Select_Picklist')){
                        if(String.isNotBlank(controllingQuestions.get(qd.Controlling_Question__c).response.ValueText__c) && String.isNotBlank(qd.Value__c)){
                            Set<String> multiItems = new Set<String>(controllingQuestions.get(qd.Controlling_Question__c).response.ValueText__c.split(';'));
                            Boolean foundValue = false;
                            for(String controlItem : qd.Value__c.split(';')){
                                if(multiItems.contains(controlItem)){
                                    foundValue = true;
                                    break;
                                }
                            }
                            if(foundValue){
                                return String.isBlank(question.Dependency_Behavior__c) || question.Dependency_Behavior__c.equals('Show');
                            }
                        }
                    }
                }
                return String.isNotBlank(question.Dependency_Behavior__c) && question.Dependency_Behavior__c.equals('Hide');
            }
        }
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
        if(!fsm.getFieldPath().contains('.')){
            Schema.DescribeFieldResult dfr = objType.getDescribe().fields.getMap().get(fsm.getFieldPath().toLowerCase()).getDescribe();
            if (displayType == Schema.DisplayType.PICKLIST) {
                options = new List<SelectOption>{new SelectOption('', '--None--')};
                for (Schema.PicklistEntry ple:dfr.getPicklistValues())
                    options.add(new SelectOption(ple.getValue(), ple.getLabel()));
            }

            if (displayType == Schema.DisplayType.MULTIPICKLIST) {
                options = new List<SelectOption>();
                for (Schema.PicklistEntry ple:dfr.getPicklistValues())
                    options.add(new SelectOption(ple.getValue(), ple.getLabel()));
            }
        }
    }
    public ApplicationQuestion(SObject obj, Question__c question, Question_Response__c response) {
        if(obj.getSObjectType() == Application__c.sObjectType){
            this.application = (Application__c)obj;
        }else{
            this.obj = obj;
        }
        this.question = question;
        this.tableBased = true;
        if(obj == null){
            this.obj = response;
        }
        this.response = response;

        //this.fieldName = fieldNames.get(question.RecordType.DeveloperName);
        if (question.Length__c == null || (question.Length__c > 255 && !fieldType.equals('LongTextArea')))
            this.length = 255;
        else
            this.length = (Integer)question.Length__c;

        this.placeholder = question.Placeholder__c;

        this.label = question.Label__c;

        this.helpText = question.Help_Text__c;
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
                if(stateAndCountryPicklistEnabled == true){
                    this.con.put('MailingStateCode', this.response.State__c);
                    this.con.put('MailingCountryCode', this.response.Country__c);
                }else{
                    this.con.put('MailingState', this.response.State__c);
                    this.con.put('MailingCountry', this.response.Country__c);
                }
            }
        }
    }
    public ApplicationQuestion(Application__c app, String label, sObject obj, String fieldName, Schema.DisplayType displayType, Boolean placeholderQuestion) {
        init(label, obj, fieldName, '',displayType);
        this.application = app;
        this.placeholderQuestion = placeholderQuestion;
    }
    public ApplicationQuestion(Application__c app, String label, sObject obj, String fieldName) {
        init(label, obj, fieldName, '',null);
        this.application = app;
    }

    public ApplicationQuestion(Application__c app, String label, sObject obj, String fieldName, String placeholder) {
        init(label, obj, fieldName, placeholder,null);
        this.application = app;
    }
    /*******************************************************************************
    * @description Sets up the question based on the input object and display type
    ********************************************************************************/
    private void init(String label, sObject obj, String fieldName, String placeholder, Schema.DisplayType dType) {
        this.tableBased = false;

        this.label = label;
        this.obj = obj;
        this.fieldName = fieldName;
        this.placeholder = placeholder;
        this.con = new Contact();
        this.response = new Question_Response__c();
        Schema.DescribeFieldResult dfr = obj.getSObjectType().getDescribe().fields.getMap().get(fieldName).getDescribe();
        if(dType == null){
            displayType = dfr.getType();
            this.length = dfr.getLength();
        }else{
            displayType = dType;
        }

        if (displayType == Schema.DisplayType.PICKLIST) {
            options = new List<SelectOption>{new SelectOption('', '--None--')};
            for (Schema.PicklistEntry ple:dfr.getPicklistValues())
                options.add(new SelectOption(ple.getValue(), ple.getLabel()));
        }

        if (displayType == Schema.DisplayType.MULTIPICKLIST) {
            options = new List<SelectOption>();
            for (Schema.PicklistEntry ple:dfr.getPicklistValues())
                options.add(new SelectOption(ple.getValue(), ple.getLabel()));
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
        if(response != null){
            if (fieldType.equals('Address')) {
                if(stateAndCountryPicklistEnabled == true){
                    response.State__c = (String)con.get('MailingStateCode');
                    response.Country__c = (String)con.get('MailingCountryCode');
                }else{
                    response.State__c = (String)con.get('MailingState');
                    response.Country__c = (String)con.get('MailingCountry');
                }
            }
            response.IsShown__c = showQuestion;
            if(question!=null){
                response.IsRequired__c = (application != null && String.isNotBlank(question.Required__c) && new Set<String>(question.Required__c.split(';')).contains(application.Application_Status__c));
            }
            response.IsPopulated__c = false;
            if(String.isNotBlank(response.ValueText__c) || (question != null && question.RecordType.DeveloperName == 'Checkbox') || String.isNotBlank(response.ValuePhone__c) || String.isNotBlank(response.ValueEmail__c) || response.ValueCurrency__c != null ||
                response.ValueDate__c != null || response.ValueDateTime__c != null || response.ValueNumber__c != null || response.ValuePercent__c != null || String.isNotBlank(response.ValueTextArea__c) ||
                    String.isNotBlank(response.ValueLongTextArea__c) || String.isNotBlank(response.ValueURL__c) || String.isNotBlank(response.ValueTextEncrypted__c) || (String.isNotBlank(response.Street__c) && String.isNotBlank(response.State__c) && String.isNotBlank(response.City__c) && String.isNotBlank(response.Country__c) && String.isNotBlank(response.PostalCode__c))){
                        response.IsPopulated__c = true;
            }
            if(String.isNotBlank(response.ValueText__c)){
                resp = response.ValueText__c;
            }
            if(displayType == Schema.DisplayType.BOOLEAN){
                resp = response.ValueCheckbox__c?response.ValueCheckbox__c:false;
            }
            if(String.isNotBlank(response.ValuePhone__c)){
                resp = response.ValuePhone__c;
            }
            if(String.isNotBlank(response.ValueEmail__c)){
                resp = response.ValueEmail__c;
            }
            if(response.ValueCurrency__c != null){
                resp = response.ValueCurrency__c;
            }
            if(response.ValueDate__c != null){
                resp = response.ValueDate__c;
            }
            if(response.ValueDateTime__c != null){
                resp = response.ValueDateTime__c;
            }
            if(response.ValueNumber__c != null){
                resp = response.ValueNumber__c;
            }
            if(response.ValuePercent__c != null){
                resp = response.ValuePercent__c;
            }
            if(String.isNotBlank(response.ValueTextArea__c)){
                resp = response.ValueTextArea__c;
            }
            if(String.isNotBlank(response.ValueLongTextArea__c)){
                resp = response.ValueLongTextArea__c;
            }
            if(String.isNotBlank(response.ValueURL__c)){
                resp = response.ValueURL__c;
            }
            if(String.isNotBlank(response.ValueTextEncrypted__c)){
                resp = response.ValueTextEncrypted__c;
            }
        }
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
        system.debug('SENDREMINDER');
        system.debug(question);
        system.debug(reqResponse);
        if(question != null && question.External_EmaiL_Field__c == true && reqResponse != null && String.isNotBlank(reqResponse.External_Email__c) && reqResponse.Id != null){
            update new Requirement_Response__c(Id=reqResponse.Id, Send_Reminder__c = !reqResponse.Send_Reminder__c);
        }
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
}