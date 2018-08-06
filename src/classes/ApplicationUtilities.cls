/*******************************************************************************
@description This class is a set of helpful utility methods
@author Huron Consulting Group
*******************************************************************************/
public class ApplicationUtilities {
    
    /*******************************************************************************
    * @description Returns the application control based on urlParameter or the default one if no param is found.
    ********************************************************************************/
	public static Application_Control__c getApplicationControls(String param) {
        
        Application_Control__c appControl;
        Application_Control__c defaultControl;
        
        if (String.isBlank(param))
            param = '';
        
        try {
            Id acId = Id.valueOf(param);
            return [SELECT Id, Hide_Term_Program__c, Application_Start_Status__c, Allow_Cancel_From__c, Allow_Submit_From__c, Allow_Withdraw_From__c, Arrow_Color__c, Button_Color__c, Button_Text_Color__c, Cancel_Status__c, Line_Color__c, Link_Color__c, Logo_Static_Resource__c, Logo_Static_Resource_Path__c, Submit_Status__c, Withdraw_Status__c, Text_Color__c, URL_Parameter__c, Default__c FROM Application_Control__c WHERE Id = :acId];
        } catch (Exception e) {}
        
        for (Application_Control__c ac:[SELECT Id, Hide_Term_Program__c, Application_Start_Status__c, Allow_Cancel_From__c, Allow_Submit_From__c, Allow_Withdraw_From__c, Arrow_Color__c, Button_Color__c, Button_Text_Color__c, Cancel_Status__c, Line_Color__c, Link_Color__c, Logo_Static_Resource__c, Logo_Static_Resource_Path__c, Submit_Status__c, Withdraw_Status__c, Text_Color__c, URL_Parameter__c, Default__c FROM Application_Control__c WHERE Active__c = :true AND (URL_Parameter__c = :param OR Default__c = :true)]) {
            if (ac.Default__c)
                defaultControl = ac;
            else if (ac.URL_Parameter__c.equals(param))
                appControl = ac;
        }
        
		return appControl == null ? defaultControl : appControl;
	}
    
    public static Boolean containsValue(String multiPicklistValue, String value) {
        return String.isNotBlank(multiPicklistValue) && (new Set<String>(multiPicklistValue.split(';'))).contains(value);
    }
    
    public class AdditionalDataWrapper {
        Map<String, Map<String,Object>> additionalData;
    }
    
    // Custom exception class for validation
    public class ApplicationException extends Exception {
        
        public Boolean doRollback = false;
        public Boolean isError = true;
        
        public ApplicationException(String e, Boolean doRollback) {
            this(e);
            this.doRollback = doRollback;
        }
        
        public ApplicationException(String e, Boolean doRollback, Boolean isError) {
            this(e, doRollback);
            this.isError = isError;
        }
    }
}