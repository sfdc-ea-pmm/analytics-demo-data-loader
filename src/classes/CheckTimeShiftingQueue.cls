public class CheckTimeShiftingQueue implements Queueable, Database.AllowsCallouts {
	public void execute(QueueableContext context) {
        
        List<ScheduledTSDetails__c> tsDetails = [
	        SELECT DetailJson__c, DaysToShift__c, Started_Date__c, End_Date__c, Status__c, CurrentNodeIndex__c, CurrentBatchProcessId__c, QueueProcessId__c, Errors__c 
	        FROM ScheduledTSDetails__c ORDER BY Started_Date__c DESC LIMIT 1
        ];
        
        System.debug(tsDetails.size());

		if(tsDetails.size() > 0){
			List<WaveTimeShiftingItem> timeShiftingItems = (List<WaveTimeShiftingItem>)JSON.deserialize(tsDetails.get(0).DetailJson__c, List<WaveTimeShiftingItem>.class);
			ScheduledTSDetails__c currentNode = tsDetails.get(0);
			Integer nodeIndex = (Integer)currentNode.CurrentNodeIndex__c;

			System.debug('TS Items: ' + timeShiftingItems);
			System.debug('Node index: ' + nodeIndex);

			if(!String.isBlank(currentNode.CurrentBatchProcessId__c)){
				List<AsyncApexJob> lstJobs = [SELECT CompletedDate, JobItemsProcessed, NumberOfErrors, Status, TotalJobItems FROM AsyncApexJob WHERE Id = :currentNode.CurrentBatchProcessId__c];
				AsyncApexJob asyncJob = lstJobs.get(0);

				if(asyncJob.Status == 'Completed'){
					if(asyncJob.NumberOfErrors > 0) {
						System.debug('Completed with errors');
						currentNode.Status__c = 'Completed with errors';
						currentNode.Errors__c = 'The process was interrupted due to errors while time shifting data for the ' + timeShiftingItems.get(nodeIndex).objectTypeName + ' object.';
						currentNode.CurrentNodeIndex__c = 0;
						currentNode.End_Date__c = Datetime.now();
					}
					else {
						// now check whether it was the last one
						if(currentNode.CurrentNodeIndex__c == timeShiftingItems.size() - 1){
							System.debug('No more nodes to process');
							currentNode.Status__c = 'Completed';
							currentNode.Errors__c = '';
							currentNode.CurrentNodeIndex__c = 0;
							currentNode.End_Date__c = Datetime.now();
						}
						else {
							// There are more nodes to process, increment index and reset
							System.debug('More nodes to process');
							currentNode.CurrentNodeIndex__c = currentNode.CurrentNodeIndex__c + 1;
							WaveTimeShiftingItem tsItem = timeShiftingItems.get((Integer)currentNode.CurrentNodeIndex__c);
							TimeShiftingBatch batchProcess = new TimeShiftingBatch(tsItem.objectTypeName, tsItem.fieldsToTimeShift, (Integer)currentNode.DaysToShift__c);
							
							update currentNode;

							CheckTimeShiftingQueue tsQueue = new CheckTimeShiftingQueue();
							currentNode.QueueProcessId__c = System.enqueueJob(tsQueue);
						}
					}		
				}
				else if(asyncJob.Status == 'Aborted'){
					System.debug('Aborted');
					currentNode.Status__c = 'Aborted';
					currentNode.Errors__c = 'The process was aborted while time shifting data for the ' + timeShiftingItems.get(nodeIndex).objectTypeName + ' object.';
					currentNode.CurrentNodeIndex__c = 0;
					currentNode.End_Date__c = Datetime.now();
				}
				else if(asyncJob.Status == 'Failed'){
					System.debug('Failed');
					currentNode.Status__c = 'Failed';
					currentNode.Errors__c = 'The process failed while time shifting data for the ' + timeShiftingItems.get(nodeIndex).objectTypeName + ' object.';
					currentNode.CurrentNodeIndex__c = 0;
					currentNode.End_Date__c = Datetime.now();
				}
				else {
					CheckTimeShiftingQueue tsQueue = new CheckTimeShiftingQueue();
					currentNode.QueueProcessId__c = System.enqueueJob(tsQueue);
				}
				
				update currentNode;
			}
		}
	
	}
}