public with sharing class CreateObjectsAndFieldsQueueable implements Queueable{
	
	private List<SF_MetadataUtils.CustomFieldSpecification> objectsAndFields;

	public CreateObjectsAndFieldsQueueable(List<SF_MetadataUtils.CustomFieldSpecification> objectsAndFields) {
		this.objectsAndFields = objectsAndFields;
	}

	public void execute(QueueableContext context) {

		for(SF_MetadataUtils.CustomFieldSpecification fields: objectsAndFields){
			if(!SF_MetadataUtils.objectExists(fields.ObjectName)){
				List<String> objectCreationErrors = SF_MetadataUtils.createObject(fields.ObjectName);
			}

			List<String> fieldCreationErrors = SF_MetadataUtils.createField(fields);	
		}
    }

}