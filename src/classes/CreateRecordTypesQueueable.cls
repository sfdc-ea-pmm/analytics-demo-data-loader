public with sharing class CreateRecordTypesQueueable implements Queueable, Database.AllowsCallouts{
	private SF_MetadataUtils.RecordTypeSpecification rtToCreate;
	private String sessionId;

	public CreateRecordTypesQueueable(SF_MetadataUtils.RecordTypeSpecification rtToCreate, String sessionId) {
		this.rtToCreate = rtToCreate;
		this.sessionId = sessionId;
	}

	public void execute(QueueableContext context) {
	
		List<String> fieldCreationErrors = SF_MetadataUtils.createRecordType(rtToCreate, this.sessionId);

		System.debug('Field Creation errors: ' + fieldCreationErrors);

    }
}