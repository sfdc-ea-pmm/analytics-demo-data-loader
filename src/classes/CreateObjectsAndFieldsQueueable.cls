public with sharing class CreateObjectsAndFieldsQueueable implements Queueable, Database.AllowsCallouts{
	
	private SF_MetadataUtils.CustomFieldSpecification fieldToCreate;
	private String sessionId;

	public CreateObjectsAndFieldsQueueable(SF_MetadataUtils.CustomFieldSpecification fieldToCreate, String sessionId) {
		this.fieldToCreate = fieldToCreate;
		this.sessionId = sessionId;
	}

	public void execute(QueueableContext context) {
	
		if(!SF_MetadataUtils.objectExists(fieldToCreate.ObjectName)){
			List<String> objectCreationErrors = SF_MetadataUtils.createObject(fieldToCreate.ObjectName, this.sessionId);
		}

		List<String> fieldCreationErrors = SF_MetadataUtils.createField(fieldToCreate, this.sessionId);

		System.debug('Field Creation errors: ' + fieldCreationErrors);

    }
}