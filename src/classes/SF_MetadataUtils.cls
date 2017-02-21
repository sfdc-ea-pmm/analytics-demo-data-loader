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
		
	}

	public static MetadataService.MetadataPort createService()
    {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        
        return service;
    }
}