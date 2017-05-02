global class TimeShiftingBatch implements Database.Batchable<sObject>, Database.Stateful {
	
	SObjectType objectType;
	List<String> dateFieldNames;
	Integer daysToShift;
	String query;
	
	// Constructor
	global TimeShiftingBatch(String objectTypeName, List<String> dateFieldNames, String waveTypeApplication) {
		try{
			this.objectType = Schema.getGlobalDescribe().get(objectTypeName);
			this.dateFieldNames = dateFieldNames;
			this.query = 'SELECT ' + String.join(dateFieldNames, ',') + ' FROM ' + objectTypeName;

			// We get the days to shift from the baseline object
			String dateField = '';
			String whereCond = '';
			String baselineObjectName = '';

			if(waveTypeApplication == 'Sales'){
				dateField = 'CloseDate';
				baselineObjectName = 'Opportunity';
				whereCond = 'StageName = \'Closed Won\' AND CloseDate < TODAY';
			}
			else if(waveTypeApplication == 'Services'){
				dateField = 'ClosedDate';
				baselineObjectName = 'Case';
			}

			String dynamicSoql = 'SELECT ' + dateField + ' FROM ' + baselineObjectName;
			if(String.isNotBlank(whereCond)){
				dynamicSoql += ' WHERE ' + whereCond;
			}

			dynamicSoql += ' ORDER BY ' + dateField + ' DESC NULLS LAST';
			dynamicSoql += ' LIMIT 1';

			List<sObject> sobjList = Database.query(dynamicSoql);
			if(sobjList.size() > 0){
				sObject s = sobjList.get(0);
				DateTime foundDate = (DateTime)s.get(dateField);
				this.daysToShift = Date.newInstance(foundDate.year(), foundDate.month(), foundDate.day()).daysBetween(Date.today());
			}
			else {
				// No time shifting possible
				// This is for executing only one batch of one record, some hack to finish the batch process at the beginning
				this.query += ' LIMIT 1';
			}
		}
		catch(Exception e) {
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
		}
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(this.query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		this.updateObjectDateFields(this.daysToShift, this.dateFieldNames, scope, this.objectType);
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
	private void updateObjectDateFields(Integer daysCount, List<String> fieldsToUpdate, List<sObject> objectsToUpdate, SObjectType objectType){
		try{
			System.debug('Will time shift ' + daysCount + ' days the following fields: ');
			for(String aFieldToUpdate: fieldsToUpdate){	
				System.debug(aFieldToUpdate);
			}

			String objectName = objectType.getDescribe().getName();
			Map<String, Schema.SObjectField> objectFields = objectType.getDescribe().fields.getMap();

			for(String aFieldToUpdate: fieldsToUpdate){	
				if(!objectFields.containsKey(aFieldToUpdate)){
					throw new WaveConfiguratorException('The field ' + aFieldToUpdate + ' does not exist within the ' + objectName + ' sObject.');	
				} 

				// Get field datatype
				Schema.DisplayType fieldType  = objectFields.get(aFieldToUpdate).getDescribe().getType();

				if(fieldType != Schema.DisplayType.DateTime && fieldType != Schema.DisplayType.Date){
					throw new WaveConfiguratorException('The field ' + aFieldToUpdate + ' type is not Date or DateTime.');
				}
			}			

			for(sObject anObjectToUpdate: objectsToUpdate){
				for(String aFieldToUpdate: fieldsToUpdate){	
					
					// Get field datatype
					Schema.DisplayType fieldType  = objectFields.get(aFieldToUpdate).getDescribe().getType();
					
					if(fieldType == Schema.DisplayType.DateTime){
						DateTime dt = DateTime.valueOf(anObjectToUpdate.get(aFieldToUpdate));
						if(dt != null){
							dt = dt.addDays(daysCount);
							anObjectToUpdate.put(aFieldToUpdate, dt);
						}
					}
					else if(fieldType == Schema.DisplayType.Date){
						Date d = Date.valueOf(anObjectToUpdate.get(aFieldToUpdate));
						if(d != null){
							d = d.addDays(daysCount);
							anObjectToUpdate.put(aFieldToUpdate, d);
						}
					}
				}
			}

			update objectsToUpdate;
		}
		catch(Exception e) {
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
		}
	}
}