global class ScheduledTimeShifting implements Schedulable {

	private Integer daysToShift;
	private List<WaveTimeShiftingItem> timeShiftingItems;

	global ScheduledTimeShifting(){
		this.timeShiftingItems = new List<WaveTimeShiftingItem>();
	}

	global void execute(SchedulableContext sc) {
		this.calculateDaysToShift();
		this.selectMetadataAndBuildNodes();
		this.processTimeShiftingObjects(0);
	}

	private void calculateDaysToShift(){
		String soqlQuery = 'SELECT CloseDate FROM Opportunity WHERE External_Id__c LIKE \'W_Opportunity%\' AND StageName = \'Closed Won\'';
		
		soqlQuery += ' ORDER BY CloseDate DESC NULLS LAST';
		soqlQuery += ' LIMIT 1';

		List<sObject> sobjList = Database.query(soqlQuery);
		ScheduledTSDetails__c tsDetails = new ScheduledTSDetails__c();

		if(sobjList.size() > 0){				
			sObject s = sobjList.get(0);
			DateTime foundDate = (DateTime)s.get('CloseDate');
			
			this.daysToShift = foundDate.dateGMT().daysBetween(Date.today());
		}
		else{
			this.daysToShift = 0;
		}
	}

	private void selectMetadataAndBuildNodes(){
		HttpRequest req = new HttpRequest();
		req.setEndpoint('https://s3-us-west-2.amazonaws.com/ac-sdo-repo/sales/WaveForSales.json');
        req.setMethod('GET');
		Http http = new Http();
        HTTPResponse res = http.send(req);

        String jsonMetadata = res.getBody();
		WaveMetadataApplication selectedAppMetadata = (WaveMetadataApplication)JSON.deserialize(jsonMetadata, WaveMetadataApplication.class);
	
		for(WaveMetadataApplicationObject wmaObj: selectedAppMetadata.objects) {
			if(wmaObj.dateFieldsToShift != null && wmaObj.dateFieldsToShift.size() > 0){
				WaveTimeShiftingItem timeShiftingItem = new WaveTimeShiftingItem();
				timeShiftingItem.appType = selectedAppMetadata.appType;
				timeShiftingItem.objectTypeName = wmaObj.Name;
				timeShiftingItem.fieldsToTimeShift = wmaObj.dateFieldsToShift;
				this.timeShiftingItems.add(timeShiftingItem);
			}
		}
	}

	private void processTimeShiftingObjects(Integer currentNodeIndex){
		if(this.timeShiftingItems.size() > 0){
			ScheduledTSDetails__c tsDetails = new ScheduledTSDetails__c();
			WaveTimeShiftingItem currentNode = this.timeShiftingItems.get(currentNodeIndex);

			// Start the batch and queue process
			TimeShiftingBatch batchProcess = new TimeShiftingBatch(currentNode.objectTypeName, currentNode.fieldsToTimeShift, this.daysToShift);
			CheckTimeShiftingQueue tsQueue = new CheckTimeShiftingQueue();

			String tsDetailsJson = JSON.serialize(this.timeShiftingItems);

			tsDetails.DetailJson__c = tsDetailsJson;
			tsDetails.DaysToShift__c = this.daysToShift;
			tsDetails.Started_Date__c = Datetime.now();
			tsDetails.Status__c = 'In Progress';
			tsDetails.Errors__c = '';
			tsDetails.CurrentNodeIndex__c = 0;
			tsDetails.CurrentBatchProcessId__c = Database.executeBatch(batchProcess, 800);
			tsDetails.QueueProcessId__c = System.enqueueJob(tsQueue);
			insert tsDetails;
		}
	}
}