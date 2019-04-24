/*******************************************************************************
@description This controller is used to filter a generic object, requirements, requirement items and questions against the application
@author Huron Consulting Group
*******************************************************************************/
public class ApplicationFilter {
	
    public static Boolean filter(Application__c app, SObject obj) {
        return filter(app, obj, true);
    }
    
    public static Boolean filter(Application__c app, SObject obj, Boolean checkStatus) {
        
        Set<String> objFields = new Set<String>();
        for (String fn:obj.getSObjectType().getDescribe().fields.getMap().keySet())
            objFields.add(fn.toLowerCase());
        
        Boolean active = objFields.contains('active__c') ? (Boolean)obj.get('active__c') : true;
        String programId = objFields.contains('intended_program__c') ? String.valueOf(obj.get('intended_program__c')) : null;
        String applicantTypes = objFields.contains('applicant_type__c') ? String.valueOf(obj.get('applicant_type__c')) : null;
        String citizenships = objFields.contains('citizenship__c') ? String.valueOf(obj.get('citizenship__c')) : null;
        String schoolCollege = objFields.contains('school_college__c') ? String.valueOf(obj.get('school_college__c')) : null;
        String deliveryTypes = objFields.contains('delivery_type__c') ? String.valueOf(obj.get('delivery_type__c')) : null;
        String residency = objFields.contains('residency__c') ? String.valueOf(obj.get('residency__c')) : null;
        String studentTypes = objFields.contains('student_type__c') ? String.valueOf(obj.get('student_type__c')) : null;
        String degreeTypes = objFields.contains('degree_type__c') ? String.valueOf(obj.get('degree_type__c')) : null;
        String genericFilters1 = objFields.contains('generic_filter_1__c') ? String.valueOf(obj.get('generic_filter_1__c')) : null;
        String genericFilters2 = objFields.contains('generic_filter_2__c') ? String.valueOf(obj.get('generic_filter_2__c')) : null;
        String genericFilters3 = objFields.contains('generic_filter_3__c') ? String.valueOf(obj.get('generic_filter_3__c')) : null;
        String genericFilters4 = objFields.contains('generic_filter_4__c') ? String.valueOf(obj.get('generic_filter_4__c')) : null;
        String appStatuses = objFields.contains('application_status__c') ? String.valueOf(obj.get('application_status__c')) : null;
        
        if (app == null)
            return true;
        if (!active)
            return false;
        if (String.isNotBlank(programId) && (app.Intended_Program__c == null || !String.valueOf(app.Intended_Program__c).equals(programId)))
            return false;
        if (String.isNotBlank(applicantTypes) && (String.isBlank(app.Applicant_Type__c) || !(new Set<String>(applicantTypes.split(';'))).contains(app.Applicant_Type__c)))
            return false;
        if (String.isNotBlank(citizenships) && (String.isBlank(app.Citizenship__c) || !(new Set<String>(citizenships.split(';'))).contains(app.Citizenship__c)))
            return false;
        if (String.isNotBlank(schoolCollege) && (String.isBlank(app.School_College__c) || !schoolCollege.equals(app.School_College__c)))
            return false;
        if (String.isNotBlank(deliveryTypes) && (String.isBlank(app.Delivery_Type__c) || !(new Set<String>(deliveryTypes.split(';'))).contains(app.Delivery_Type__c)))
            return false;
        if (String.isNotBlank(residency) && (String.isBlank(app.Residency__c) || !residency.equals(app.Residency__c)))
            return false;
        if (String.isNotBlank(studentTypes) && (String.isBlank(app.Student_Type__c) || !(new Set<String>(studentTypes.split(';'))).contains(app.Student_Type__c)))
            return false;
        if (String.isNotBlank(degreeTypes) && (String.isBlank(app.Degree_Type__c) || !(new Set<String>(degreeTypes.split(';'))).contains(app.Degree_Type__c)))
            return false;
        if (String.isNotBlank(genericFilters1) && (String.isBlank(app.Generic_Filter_1__c) || !(new Set<String>(genericFilters1.split(';'))).contains(app.Generic_Filter_1__c)))
            return false;
        if (String.isNotBlank(genericFilters2) && (String.isBlank(app.Generic_Filter_2__c) || !(new Set<String>(genericFilters2.split(';'))).contains(app.Generic_Filter_2__c)))
            return false;
        if (String.isNotBlank(genericFilters3) && (String.isBlank(app.Generic_Filter_3__c) || !(new Set<String>(genericFilters3.split(';'))).contains(app.Generic_Filter_3__c)))
            return false;
        if (String.isNotBlank(genericFilters4) && (String.isBlank(app.Generic_Filter_4__c) || !(new Set<String>(genericFilters4.split(';'))).contains(app.Generic_Filter_4__c)))
            return false;
        if (checkStatus && (!UserInfo.getUserType().equals('Standard') || Test.isRunningTest()) && String.isNotBlank(appStatuses) && (String.isBlank(app.Application_Status__c) || !(new Set<String>(appStatuses.split(';'))).contains(app.Application_Status__c)))
            return false;
        
        return true;
    }
}