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
			
			if(objectCreationErrors.size() > 0){
				String errors = '';
			
				for(String err: objectCreationErrors){
					errors += err + '.';
				}

				System.debug('Object Creation errors: ' + errors);
				throw new WaveConfiguratorException('An object could not be created. Cause: ' + errors);

			}
		}

		if(SF_MetadataUtils.fieldExists(fieldToCreate.ObjectName, fieldToCreate.Name)){
			List<String> assignmentAccessErrors = SF_MetadataUtils.assignAccessToField(fieldToCreate.ObjectName, fieldToCreate.Name);
			
			if(assignmentAccessErrors.size() > 0){
				String errors = '';
			
				for(String err: assignmentAccessErrors){
					errors += err + '.';
				}

				System.debug('Field permissions errors: ' + errors);
				throw new WaveConfiguratorException('A field could not be granted. Cause: ' + errors);
			
			}

		}
		else{
			List<String> fieldCreationErrors = SF_MetadataUtils.createField(fieldToCreate, this.sessionId);
			
			if(fieldCreationErrors.size() > 0){
				String errors = '';
			
				for(String err: fieldCreationErrors){
					errors += err + '.';
				}

				System.debug('Field Creation errors: ' + errors);
				throw new WaveConfiguratorException('A field could not be created. Cause: ' + errors);
			
			}
		}

    }
}