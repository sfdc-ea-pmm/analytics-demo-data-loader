// This class combines Schema class for describe metadata and MetadataService calls to handle
// the creation of custom objects and fields
public with sharing class SF_MetadataUtils {
	
	private Map<String, Boolean> existingObjectsMap = new Map<String, Boolean>();
    private Map<String, Map<String, Boolean>> existingFieldsMap = new Map<String, Map<String, Boolean>>();

	public SF_MetadataUtils() {
		
        // We use lowercase names to avoid duplicated fields and objects

        String[] objNamesArray = new String[]{};
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe(); 
        for(String objectKey : globalDescribe.keySet()){
            String objectName = globalDescribe.get(objectKey).getDescribe().getName();
            if(!objectName.endsWithIgnoreCase('__kav')){
                // We add the object to the existing ones map
                String objNameLower = objectName.toLowerCase();
                this.existingObjectsMap.put(objNameLower, true);
                Map<String, Boolean> fieldsMap = new Map<String, Boolean>();
                this.existingFieldsMap.put(objNameLower, fieldsMap);

                objNamesArray.add(objectName);
            }
        }

        // Now for each object, the fields
        Schema.DescribeSObjectResult[] sObjectsDescribe = Schema.describeSObjects(objNamesArray);
        for(Schema.DescribeSObjectResult objDesc : sObjectsDescribe){
            
            Map<String, Boolean> currentFieldMap = this.existingFieldsMap.get(objDesc.getName().toLowerCase());
            Map<String, Schema.SObjectField> fieldMap = objDesc.fields.getMap();

            for(String fieldKey : fieldMap.keySet()){
                Schema.SObjectField fieldSchema = fieldMap.get(fieldKey);
                Schema.DescribeFieldResult dfr = fieldSchema.getDescribe();
                currentFieldMap.put(dfr.getName().toLowerCase(), true);
            }
        }
	}

	public Boolean objectExists(String objName){
		return this.existingObjectsMap.containsKey(objName.toLowerCase());
	}

	public Boolean fieldExists(String objName, String fieldName){
		return this.existingObjectsMap.containsKey(objName.toLowerCase()) && this.existingFieldsMap.get(objName.toLowerCase()).containsKey(fieldName.toLowerCase());
	}

	public List<String> createObject(String objName){
		
        List<String> errors = new List<String>();
		List<MetadataService.SaveResult> results;
		MetadataService.MetadataPort service = createService();
		MetadataService.CustomObject cObj = new MetadataService.CustomObject();

        cObj.fullName = objName.endsWith('__c') ? objName : objName + '__c';
        cObj.label = objName;
        cObj.pluralLabel = objName;
        cObj.nameField = new MetadataService.CustomField();
        cObj.nameField.type_x = 'AutoNumber';
        cObj.nameField.label = objName.replace('__c', '') + ' Name';
        cObj.deploymentStatus = 'Deployed';
        cObj.sharingModel = 'ReadWrite';

        results = service.createMetadata(
            new MetadataService.Metadata[] { cObj }
        );

        if(results != null && results.size() > 0 && results.get(0).success){
        	this.existingObjectsMap.put(objName, true);
            Map<String, Boolean> fieldsMap = new Map<String, Boolean>();
            this.existingFieldsMap.put(objName, fieldsMap);
        }
        else {
        	// Return error messages
            System.debug('Couldn\'t create ' + objName + ' object. Reasons: ');
            for(MetadataService.Error err : results.get(0).errors){
                errors.add(err.message);
                System.debug(err.message);
            }
        }

        return errors;
	}

	public List<String> createField(CustomFieldSpecification fieldSpec){
		
        List<String> errors = new List<String>();
		if(fieldSpec.Name.endsWithIgnoreCase('__c')){
            List<MetadataService.SaveResult> results;
            MetadataService.MetadataPort service = createService();
            MetadataService.CustomField cField = new MetadataService.CustomField();
            
            cField.fullName = fieldSpec.ObjectName + '.' + fieldSpec.Name;
            cField.label = fieldSpec.Label;
            cField.type_x = fieldSpec.Type;
            
            if(!String.isBlank(fieldSpec.ReferenceTo)){
                cField.referenceTo = fieldSpec.ReferenceTo;
            }

            if(fieldSpec.Length > 0 && !fieldSpec.Type.equalsIgnoreCase('MasterDetail') && !fieldSpec.Type.equalsIgnoreCase('Lookup') && !fieldSpec.Type.equalsIgnoreCase('Date'))
            {
                cField.length = fieldSpec.Length;
            }

            if(fieldSpec.Type.equalsIgnoreCase('MasterDetail') || fieldSpec.Type.equalsIgnoreCase('Lookup')){
                cField.relationshipName = fieldSpec.ObjectName.replace('__c', '') + 'Related';
            }

            results = service.createMetadata(
                new MetadataService.Metadata[] { cField }
            );

            if(results != null && results.size() > 0 && results.get(0).success){
                Map<String, Boolean> fieldsMap;
                if(!this.existingFieldsMap.containsKey(fieldSpec.ObjectName)){
                    fieldsMap = new Map<String, Boolean>();
                    this.existingFieldsMap.put(fieldSpec.ObjectName, fieldsMap);
                }
                else {
                    fieldsMap = this.existingFieldsMap.get(fieldSpec.ObjectName);
                }
                
                fieldsMap.put(fieldSpec.Name, true);
            }
            else {
                // Return error messages
                System.debug('Couldn\'t create ' + cField.fullName + ' field. Reasons: ');
                for(MetadataService.Error err : results.get(0).errors){
                    errors.add(err.message);
                    System.debug(err.message);
                }        
            }
        }
        else {
            errors.add('Field creation ignored. Cannot create a standard field.');
        }

        return errors;
	}

	public static MetadataService.MetadataPort createService()
    {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        
        return service;
    }

    public class CustomFieldSpecification {
    	public String ObjectName;
    	public String Name;
    	public String Label;
    	public String Type;
		public String ReferenceTo;
		public Integer Length;
		public Integer Precision;
		public Integer Scale;
		public Boolean IsExternalId;
		public Boolean IsRequired;
    }
}