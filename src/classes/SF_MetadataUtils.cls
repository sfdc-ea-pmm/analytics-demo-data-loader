// This class combines Schema class for describe metadata and MetadataService calls to handle
// the creation of custom objects and fields
public with sharing class SF_MetadataUtils {
	
	private Map<String, Boolean> existingObjectsMap = new Map<String, Boolean>();
    private Map<String, Map<String, Boolean>> existingFieldsMap = new Map<String, Map<String, Boolean>>();

	public SF_MetadataUtils() {
		
        String[] objNamesArray = new String[]{};
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe(); 
        for(String objectKey : globalDescribe.keySet()){
            String objectName = globalDescribe.get(objectKey).getDescribe().getName();
            if(!objectName.endsWithIgnoreCase('__kav')){
                // We add the object to the existing ones map
                this.existingObjectsMap.put(objectName, true);
                Map<String, Boolean> fieldsMap = new Map<String, Boolean>();
                this.existingFieldsMap.put(objectName, fieldsMap);

                objNamesArray.add(objectName);
            }
        }

        //System.debug(this.existingFieldsMap);

        // Now for each object, the fields
        Schema.DescribeSObjectResult[] sObjectsDescribe = Schema.describeSObjects(objNamesArray);
        for(Schema.DescribeSObjectResult objDesc : sObjectsDescribe){
            
            Map<String, Boolean> currentFieldMap = this.existingFieldsMap.get(objDesc.getName());
            Map<String, Schema.SObjectField> fieldMap = objDesc.fields.getMap();

            for(String fieldKey : fieldMap.keySet()){
                Schema.SObjectField fieldSchema = fieldMap.get(fieldKey);
                Schema.DescribeFieldResult dfr = fieldSchema.getDescribe();
                currentFieldMap.put(dfr.getName(), true);
            }
        }

        /*
        MetadataService.MetadataPort service = createService();
        List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();

        MetadataService.ListMetadataQuery customObjQuery = new MetadataService.ListMetadataQuery();
        customObjQuery.type_x = 'CustomObject';
        queries.add(customObjQuery);

        MetadataService.ListMetadataQuery customFieldsQuery = new MetadataService.ListMetadataQuery();
        customFieldsQuery.type_x = 'CustomField';
        queries.add(customFieldsQuery);

        MetadataService.ListMetadataQuery stdFieldsQuery = new MetadataService.ListMetadataQuery();
        stdFieldsQuery.type_x = 'Field';
        queries.add(stdFieldsQuery);
        
        MetadataService.FileProperties[] fileProperties = service.listMetadata(queries, 25);

        for(MetadataService.FileProperties fileProperty : fileProperties){

            System.debug('Metadata object: ' + fileProperty.fullName);
            System.debug('Type: ' + fileProperty.type_x);

            if(fileProperty.type_x == 'CustomObject'){
            	this.existingObjectsMap.put(fileProperty.fullName, true);
            }
            else if(fileProperty.type_x == 'CustomField') {
            	String[] fullNameParts = fileProperty.fullName.split('\\.');
            	String objName = fullNameParts[0];
            	String fieldName = fullNameParts[1];            	

            	Map<String, Boolean> fieldsMap;
            	if(!this.existingFieldsMap.containsKey(objName)){
            		fieldsMap = new Map<String, Boolean>();
            		this.existingFieldsMap.put(objName, fieldsMap);
            	}
            	else {
            		fieldsMap = this.existingFieldsMap.get(objName);
            	}
            	
            	fieldsMap.put(fieldName, true);
            }
        }*/
	}

	public Boolean objectExists(String objName){
		return this.existingObjectsMap.containsKey(objName);
	}

	public Boolean fieldExists(String objName, String fieldName){
		//System.debug(objName + ' object exists? ' + this.existingObjectsMap.containsKey(objName));
        System.debug(fieldName + ' field within ' + objName + ' object exists? ' + this.existingFieldsMap.get(objName).containsKey(fieldName));
        return this.existingObjectsMap.containsKey(objName) && this.existingFieldsMap.get(objName).containsKey(fieldName);
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
        cObj.nameField.label = objName + ' Name';
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
		List<MetadataService.SaveResult> results;
		MetadataService.MetadataPort service = createService();
		MetadataService.CustomField cField = new MetadataService.CustomField();
        
        cField.fullName = fieldSpec.ObjectName + '.' + fieldSpec.Name;
        cField.label = fieldSpec.Label;
        cField.type_x = fieldSpec.Type;
        
        if(!String.isBlank(fieldSpec.ReferenceTo)){
            cField.referenceTo = fieldSpec.ReferenceTo;
        }

        cField.length = fieldSpec.Length;

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