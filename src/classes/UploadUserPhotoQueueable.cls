public class UploadUserPhotoQueueable implements Queueable {
	
	private Zippex zipHandler;
	private String fileNameToExtract;
	private String fileBaseName;

	public UploadUserPhotoQueueable(Zippex zipHandler, String fileNameToExtract, String fileBaseName){
		this.zipHandler = zipHandler;
		this.fileNameToExtract = fileNameToExtract;
		this.fileBaseName = fileBaseName;
	}

	public void execute(QueueableContext context) {
        
        String nameToSave = this.fileBaseName.substringBeforeLast('.');

		if(String.isNotBlank(nameToSave)){

			List<User> users = [SELECT Id, External_Id__c FROM User WHERE External_Id__c = :nameToSave];

			if(users.size() > 0){
				User usr = users.get(0);
				Blob blobFile = zipHandler.getFile(this.fileNameToExtract);
				String mimeType = 'image/' + this.fileBaseName.substringAfterLast('.');

				ConnectApi.UserProfiles.setPhoto(null, usr.Id, new ConnectApi.BinaryInput(blobFile, mimeType, this.fileBaseName));
			}
		}
	}
}