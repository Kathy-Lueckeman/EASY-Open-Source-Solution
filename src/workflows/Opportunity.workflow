<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Opportunity_Application_Submitted_Date</fullName>
        <description>Sets the Application Submitted Date to Today</description>
        <field>Application_Submitted_Date__c</field>
        <formula>TODAY()</formula>
        <name>Opportunity: Application Submitted Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_First_Recruitment_Program</fullName>
        <description>Sets the First Recruitment Program to the Recruitment Program Name.</description>
        <field>First_Recruitment_Program__c</field>
        <formula>Recruitment_Program__r.Name</formula>
        <name>Opportunity: First Recruitment Program</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Key_Set_Based_on_Career</fullName>
        <description>For UG, sets key to Contact ID + Opportunity Career + Term ID, for GR, Contact ID + Opportunity Career + ((Academic. Program ID.Recruitment Program ID or Academic Program ID) or Recruitment Program ID) + Term ID.</description>
        <field>Opportunity_Key__c</field>
        <formula>CASESAFEID(Contact__r.Id)+ 

IF(Academic_Program__c + Recruitment_Program__c = &quot;&quot;,&quot;&quot;, 

/*If the Academic Program Career = Undergraduate, or Academic Program is blank and the Recruitment Program Career = Undergraduate, this formula uses the centralized model (one Opportunity per Term)*/ 
IF(OR(ISPICKVAL(Academic_Program__r.Career__c, &quot;Undergraduate&quot;), AND(ISBLANK(Academic_Program__c), ISPICKVAL(Recruitment_Program__r.Career__c, &quot;Undergraduate&quot;))), &quot;.Undergraduate&quot;, 

/*Otherwise, this formula uses the decentralized model (one Opportunity per Academic Program or Recruitment Program and Term)*/ 
&quot;.Graduate.&quot; + 

/*If there is no Academic Program, the decentralized model adds the Recruitment Program Id. Otherwise, the model uses the Recruitment Program ID from the Academic Program, or if there is none, the Academic Program ID is used as a last resort. Most Academic Programs should have a Recruitment Program ID to ensure a smooth process from inquiry to application.*/ 
IF(ISBLANK(Academic_Program__r.Id), Recruitment_Program__r.Id, IF(ISBLANK(Academic_Program__r.Recruitment_Program__c), Academic_Program__r.Id, Academic_Program__r.Recruitment_Program__r.Id))))</formula>
        <name>Opportunity Key: Set Based on Career</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Name_Set_to_Last_Term</fullName>
        <description>Sets the Opportunity Name to Contact Last Name - Term Name</description>
        <field>Name</field>
        <formula>Contact__r.LastName</formula>
        <name>Opportunity Name - Set to Last - Term</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Set_First_Inquiry_Source</fullName>
        <description>Sets the First Inquiry Source field to the LeadSource.</description>
        <field>First_Inquiry_Source__c</field>
        <formula>TEXT(LeadSource)</formula>
        <name>Opportunity: Set First Inquiry Source</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Set_Inquiry_Date</fullName>
        <description>Sets the Inquiry Date field to CreatedDate.</description>
        <field>Inquiry_Date__c</field>
        <formula>CreatedDate</formula>
        <name>Opportunity: Set Inquiry Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Record_Type_Set_to_Applicant</fullName>
        <description>Sets Record Type to Applicant.</description>
        <field>RecordTypeId</field>
        <lookupValue>Applicant_Opportunity</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Record Type: Set to Applicant</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Record_Type_Set_to_Inquiry</fullName>
        <description>Sets Record Type to Inquiry Opportunity</description>
        <field>RecordTypeId</field>
        <lookupValue>Inquiry_Opportunity</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Record Type: Set to Inquiry</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Opportunity%3A Set Applicant Record Type</fullName>
        <actions>
            <name>Record_Type_Set_to_Applicant</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Updates the record type to Applicant</description>
        <formula>ISCHANGED(StageName) &amp;&amp; ISPICKVAL(StageName, &quot;Applied&quot;) &amp;&amp; RecordType.Name &lt;&gt; &quot;Applicant_Opportunity&quot;</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Opportunity%3A Set Application Submitted Date</fullName>
        <actions>
            <name>Opportunity_Application_Submitted_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Sets the Application Submitted Date to Today when the Stage is changed to Applied.</description>
        <formula>ISCHANGED(StageName) &amp;&amp; ISPICKVAL(StageName, &quot;Applied&quot;)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Opportunity%3A Set First Inquiry Source</fullName>
        <actions>
            <name>Opportunity_Set_First_Inquiry_Source</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Sets the First Inquiry Source field when it is blank.</description>
        <formula>ISBLANK( First_Inquiry_Source__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Opportunity%3A Set First Recruitment Program</fullName>
        <actions>
            <name>Opportunity_First_Recruitment_Program</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Sets the First Recruitment Program field when it is blank.</description>
        <formula>ISBLANK( First_Recruitment_Program__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Opportunity%3A Set Inquiry Date</fullName>
        <actions>
            <name>Opportunity_Set_Inquiry_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.Inquiry_Date__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>Sets the Inquiry Date if the Opportunity is created or edited and the Inquiry Date is blank.</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Opportunity%3A Set Inquiry Record Type</fullName>
        <actions>
            <name>Record_Type_Set_to_Inquiry</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Updates the record type to Inquiry based on Stage.</description>
        <formula>ISCHANGED(StageName) &amp;&amp; ISPICKVAL(StageName, &quot;Inquired&quot;) &amp;&amp; RecordType.Name &lt;&gt; &quot;Inquiry_Opportunity&quot;</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Opportunity%3A Update Name</fullName>
        <actions>
            <name>Opportunity_Name_Set_to_Last_Term</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Updates Opportunity Name to Contact Last - Term Name</description>
        <formula>Name &lt;&gt; Contact__r.LastName</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Opportunity%3A Update Opportunity Key</fullName>
        <actions>
            <name>Opportunity_Key_Set_Based_on_Career</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Sets the Opportunity Key based on the Career, Recruitment Program or Academic Program, and Term, according to the formula used in the Opportunity Key field on the Interactions object.</description>
        <formula>/*The below formula allows for a centralized and decentralized recruitment model.*/ /*If the Academic Career from the Academic Program = Undergraduate or the Academic Program is blank and the Recruitment Program Career = Undergraduate, this formula uses the centralized model (one Opportunity per Term). If the same is true for the Graduate Career, this formula uses the decentralized model (one Opportunity per Opportunity Program and Term). Otherwise, the formula is blank, which means the Opportunity is missing important information.*/ Opportunity_Key__c &lt;&gt; CASESAFEID(Contact__r.Id)+ IF(Academic_Program__c + Recruitment_Program__c = &quot;&quot;,&quot;&quot;,   /*If the Academic Program Career = Undergraduate, or Academic Program is blank and the Recruitment Program Career = Undergraduate, this formula uses the centralized model (one Opportunity per Term)*/  IF(OR(ISPICKVAL(Academic_Program__r.Career__c, &quot;Undergraduate&quot;), AND(ISBLANK(Academic_Program__c), ISPICKVAL(Recruitment_Program__r.Career__c, &quot;Undergraduate&quot;))), &quot;.Undergraduate&quot;,   /*Otherwise, this formula uses the decentralized model (one Opportunity per Academic Program or Recruitment Program and Term)*/  &quot;.Graduate.&quot; +   /*If there is no Academic Program, the decentralized model adds the Recruitment Program Id. Otherwise, the model uses the Recruitment Program ID from the Academic Program, or if there is none, the Academic Program ID is used as a last resort. Most Academic Programs should have a Recruitment Program ID to ensure a smooth process from inquiry to application.*/  IF(ISBLANK(Academic_Program__r.Id), Recruitment_Program__r.Id, IF(ISBLANK(Academic_Program__r.Recruitment_Program__c), Academic_Program__r.Id, Academic_Program__r.Recruitment_Program__r.Id))))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
