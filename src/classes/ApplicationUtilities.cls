/*******************************************************************************
@description This class is a set of helpful utility methods
@author Huron Consulting Group

Revision (s): 
*******************************************************************************/
public class ApplicationUtilities {
    /*******************************************************************************
    * @description Returns the application control based on urlParameter or the default one if no urlParam is found.
    ********************************************************************************/
	public static Application_Control__c getApplicationControls(String urlParam){
        Application_Control__c appControl;
        String param = urlParam;
        if(String.isBlank(param)){
            param = '';
        }
        Map<String,Object> appControlFields = Application_Control__c.sObjectType.getDescribe().fields.getMap();
        for(Application_Control__c ac : [Select Id, Hide_Term_Program__c,Application_Start_Status__c,Allow_Cancel_From__c, Allow_Submit_From__c, Allow_Withdraw_From__c, Arrow_Color__c, Button_Color__c, Button_Text_Color__c, Cancel_Status__c, Line_Color__c, Link_Color__c, Logo_Static_Resource__c, Logo_Static_Resource_Path__c, Submit_Status__c, Withdraw_Status__c, Text_Color__c,URL_Parameter__c,Default__c from Application_Control__c where Active__c = true and (URL_Parameter__c=:urlParam OR Default__c = true) LIMIT 2]){
            if((ac.Default__c == true && appControl == null) || ac.Default__c == false){
                appControl = ac;
            }
        }
		return appControl;
	}
    public class AdditionalDataWrapper{
        Map<String,Map<String,Object>> additionalData;
    }
}