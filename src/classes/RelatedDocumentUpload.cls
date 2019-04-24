/*******************************************************************************
@description This class allows an admissions user to upload a supporting document onto a related object requirement item.
@author Huron Consulting Group

Revision (s): 
*******************************************************************************/
public class RelatedDocumentUpload {
    public SObject obj{get;set;}
    public ApplicationQuestionGroup aqg{get;set;}
    public String objName{
        get{
            if(obj != null){
                return (String)obj.get('Name');
            }
            return '';
        }set;}

    public Application_Control__c appControl{
        get{
            if(appControl == null){
                appControl = ApplicationUtilities.getApplicationControls(ApexPages.currentPage().getParameters().get('at'));
            }
            return appControl;
        }set;
    }

    public transient String additionalDataString{get;set;}

    public RelatedDocumentUpload() {
        if(ApexPages.currentPage().getParameters().containsKey('Id')){
            Id objId = ApexPages.currentPage().getParameters().get('Id');
            obj = database.query('Select Id,Name, (SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title FROM ContentDocumentLinks Where ContentDocument.Description = \'Supporting Document\') from ' + objId.getSObjectType() + ' WHERE Id =\''+String.escapeSingleQuotes(objId)+'\'');
            aqg = new ApplicationQuestionGroup(obj);
        }
    }
    /*******************************************************************************
    * @description Saves the ContentDocument
    ********************************************************************************/
    public void submit(){
        transient Map<String,Object> additionalDataMap;
        transient ContentVersion att = new ContentVersion();
        system.debug(additionalDataString);
        if(String.isNotBlank(additionalDataString)){
            additionalDataMap = (Map<String,Object>)JSON.deserializeUntyped(additionalDataString);
        } 
        if(additionalDataMap != null && additionalDataMap.containsKey('')){
            Map<String,Object> additionalData = (Map<String,Object>)additionalDataMap.get('');
            if(additionalData.containsKey('attData')){
                Map<String,Object> attData = (Map<String,Object>)additionalData.get('attData');
                if(attData.containsKey('fileName')){
                    att.Title = (String)attData.get('fileName');
                }
                if(attData.containsKey('data')){
                    att.VersionData = Blob.valueOf((String)attData.get('data'));
                }
                att.PathOnClient = att.Title;
                att.firstPublishLocationId = obj.Id;
                if(!Test.isRunningTest()){
                    att.put('NetworkId',Network.getNetworkId());
                }
                att.Description = 'Supporting Document';
                insert att;
                if(aqg.oldAttLink != null && aqg.oldAttLink.ContentDocumentId != null){
                    delete new ContentDocument(Id=aqg.oldAttLink.ContentDocumentId);
                }
                att.VersionData = null;
            }
        }
    }
}