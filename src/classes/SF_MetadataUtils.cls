public with sharing class SF_MetadataUtils {
	
	private Map<String, Boolean> existingObjectsMap = new Map<String, Boolean>();
    private Map<String, Map<String, Boolean>> existingFieldsMap = new Map<String, Map<String, Boolean>>();

	public SF_MetadataUtils() {
		MetadataService.MetadataPort service = createService();
        List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();

        MetadataService.ListMetadataQuery customObjQuery = new MetadataService.ListMetadataQuery();
        customObjQuery.type_x = 'CustomObject';
        queries.add(customObjQuery);

        MetadataService.ListMetadataQuery customFieldsQuery = new MetadataService.ListMetadataQuery();
        customFieldsQuery.type_x = 'CustomField';
        queries.add(customFieldsQuery);
        
        MetadataService.FileProperties[] fileProperties = service.listMetadata(queries, 25);

        for(MetadataService.FileProperties fileProperty : fileProperties){
            if(fileProperty.type_x == 'CustomObject'){
            	this.existingObjectsMap.put(fileProperty.fullName, true);
            }
            else if(fileProperty.type_x == 'CustomField') {
            	String[] fullNameParts = fileProperty.fullName.split('.');
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
        }
	}

	public Boolean objectExists(String objName){
		return this.existingObjectsMap.containsKey(objName);
	}

	public Boolean fieldExists(String objName, String fieldName){
		return this.existingObjectsMap.containsKey(objName) && this.existingFieldsMap.get(objName).containsKey(fieldName);
	}

	public void createObject(String objName){
		
		List<MetadataService.SaveResult> results;
		MetadataService.MetadataPort service = createService();
		MetadataService.CustomObject cObj = new MetadataService.CustomObject();
        cObj.fullName = objName + '__c';
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
        	existingObjectsMap.put(objName, true);
        }
        else {
        	// Return error messages
        }
	}

	public void createField(CustomFieldSpecification fieldSpec){
		
		List<MetadataService.SaveResult> results;
		MetadataService.MetadataPort service = createService();
		MetadataService.CustomField cField = new MetadataService.CustomField();
        cField.fullName = fieldSpec.ObjectName + '.' + fieldSpec.Name + '__c';
        cField.label = fieldSpec.Label;
        cField.type_x = fieldSpec.Type;
        cField.referenceTo = fieldSpec.ReferenceTo;
        cField.length = fieldSpec.Length;

        // CONTINUAR ACA

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
        }
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