/*******************************************************************************
@description This controller is used to allow internal users the ability to edit an application.
@author Huron Consulting Group

Revision (s): 
*******************************************************************************/
public class ApplicationRequirementPreview {

        public List<Requirement__c> reqs {get;set;}
    public Id contactId {get;set;}
    public Id applicationId {get;set;}
        public Id requirementId {get;set;}
        public ApplicationRequirement req{get;set;}
    public Application__c app {get;set;}

        public Map<String,ApplicationQuestion> questionHolderMap{get;set;}

        public Application_Control__c appControl{
        get{
            if(appControl == null){
                appControl = ApplicationUtilities.getApplicationControls(ApexPages.currentPage().getParameters().get('at'));
            }
            return appControl;
        }set;
    }
        
        public ApplicationRequirementPreview(){
                questionHolderMap = new Map<String,ApplicationQuestion>();
                app = new Application__c();
        }

        /*******************************************************************************
    * @description Initialize the page - Creates ApplicationRequirement for each requirement that is applicible to this application
    ********************************************************************************/
        public void init() {
                requirementId = ApexPages.currentPage().getParameters().get('Id');
                if(requirementId == null){
                        return;
                }
                String appType = '';
                if(String.isNotBlank(app.Applicant_Type__c)){
                        appType = app.Applicant_Type__c;
                }
                req = new ApplicationRequirement(requirementId,app,true);
                req.init();

                Set<String> fieldSetFields = new Set<String>();
                for(FieldSetMember f : SObjectType.Application__c.FieldSets.Application_Preview_Filters.getFields()){
                        fieldSetFields.add(f.getFieldPath());
                        questionHolderMap.put(f.getFieldPath(),new ApplicationQuestion(f,app, Application__c.SObjectType));
                        questionHolderMap.get(f.getFieldPath()).application = new Application__c(Application_Status__c='NULL');
                }
        }
}