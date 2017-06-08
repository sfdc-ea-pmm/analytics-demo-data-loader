global class CsvDataImportBatch implements Database.Batchable<String>, Database.Stateful {
	
	private String csvData;
	private Map<Integer, String> fieldPositions;
	private Map<String, Integer> fieldIndexes;
	private List<WaveApplicationObjectRelation> relations;
	private SObjectType objectType;
	private List<SmartLookup> smartLookups;
	private List<String> errorMessages;
	
	global CsvDataImportBatch(SObjectType objectType, String csvData, Map<Integer, String> fieldPositions, List<WaveApplicationObjectRelation> relations) {
		this.objectType = objectType;
		this.csvData = csvData;
		this.fieldPositions = fieldPositions;
		this.relations = relations;
		this.errorMessages = new List<String>();

		// Then we get the table of <fieldName, columnIndexInCSV
		this.fieldIndexes = new Map<String, Integer>();

		for(Integer columnNumber: this.fieldPositions.keySet()) {
    		
    		// Gets the column name
    		String headerValue = this.fieldPositions.get(columnNumber);

    		this.fieldIndexes.put(headerValue, columnNumber);
    	}

    	for(WaveApplicationObjectRelation wAppObjectRelation: relations){
    		String columnName = wAppObjectRelation.csvColumnName;
    		if(!this.fieldIndexes.containsKey(columnName)){
    			throw new WaveConfiguratorException('Error with relation. The CSV dataset is required to contain a column named ' + columnName + '.');
    		}
    	}		
	}
	
	global Iterable<String> start(Database.BatchableContext BC) {
		
		try {
			// Prepare headers and return all data
			this.prepareSmartLookups();

			return new Utility_RowIterator(this.csvData);
		}
		catch(Exception ex){
			System.debug('Exception in start');
			System.debug(ex.getMessage());
			System.debug(ex.getStackTraceString());

			return new List<String>();
		}
	}

   	global void execute(Database.BatchableContext BC, List<String> scope) {

   		try {
			
	   		List<String> lines = new List<String>();

	        for(String row : scope)
	        {
	            lines.add(row);
	        }

	        List<List<String>> rowsBatch = CSVReader.Parse(String.join(lines, '\n'));

	   		// First handle smart lookups
	   		this.processSmartLookupForBatch(rowsBatch);

	   		List<SObject> objectsBatch = new List<SObject>();
	   		List<String> lstExternalIds = new List<String>();
	   		Map<String, Schema.SObjectField> objectFields = this.objectType.getDescribe().fields.getMap();
			
            System.debug(this.fieldPositions);
            
	   		// For each row of data in the CSV
			for(List<String> sObjRow: rowsBatch) {

				// Will create an object
				SObject objToCreate = this.objectType.newSObject();

				// For each column in the CSV row
				for(Integer i = 0; i < sObjRow.size(); i++) {
					
					// We get the name using the position and then its value
					String fieldName = this.fieldPositions.get(i);
                    
					if(String.isNotBlank(sObjRow[i]) && objectFields.containsKey(fieldName)){

						String fieldValue = sObjRow[i].trim();
						
						// Get field datatype
						Schema.DisplayType fieldType  = objectFields.get(fieldName).getDescribe().getType();

						if(fieldType == Schema.DisplayType.Boolean){
							// Boolean
							objToCreate.put(fieldName, Boolean.valueOf(fieldValue));
						}
						else if (fieldType == Schema.DisplayType.Currency || fieldType == Schema.DisplayType.Double || fieldType == Schema.DisplayType.Percent) {
							// Real number
							objToCreate.put(fieldName, Double.valueOf(fieldValue));
						}
						else if (fieldType == Schema.DisplayType.Integer) {
							// Integer
							objToCreate.put(fieldName, Integer.valueOf(fieldValue));
						}
						else if (fieldType == Schema.DisplayType.Date) {
							// Date
							objToCreate.put(fieldName, Date.valueOf(fieldValue));	
						}
						else if (fieldType == Schema.DisplayType.DateTime) {
							// Datetime
							objToCreate.put(fieldName, DateTime.valueOf(fieldValue));
						}
						else {
							// String
							if(!(this.objectType.getDescribe().getName() == 'User' && (fieldName.equalsIgnoreCase('Name') || fieldName.equalsIgnoreCase('Username') || fieldName.equalsIgnoreCase('CommunityNickname')))){
								objToCreate.put(fieldName, fieldValue);	
							}
							
							if(this.objectType.getDescribe().getName() == 'User' && fieldName.equalsIgnoreCase('Alias')){
								String nick = fieldValue + DateTime.now().getTime();
								objToCreate.put('CommunityNickname', nick);
								objToCreate.put('Username', nick + '@demo.user');	
							}
						}

						if(fieldName.equalsIgnoreCase('External_Id__c')){
							lstExternalIds.add(fieldValue);
						}
					}
				}

				objectsBatch.add(objToCreate);
			}

			if(objectsBatch.size() > 0) {
				
				// We must determine which objects to insert, and which to update
				String genQuery = 'SELECT Id, External_Id__c FROM ' + this.objectType.getDescribe().getName() + ' WHERE External_Id__c IN :lstExternalIds';
                
                // only add All Rows and IsDeleted when Tasks and Events
                if(this.objectType.getDescribe().getName() == 'Task' || this.objectType.getDescribe().getName() == 'Event')
                    genQuery += ' AND IsDeleted = False ALL ROWS';
                
		        List<SObject> alreadyThere = Database.query(genQuery);
		        Map<String, String> sfIdsByExternalId = new Map<String, String>();
		        
		        for(SObject sObj: alreadyThere) {
		        	sfIdsByExternalId.put(String.valueOf(sObj.get('External_Id__c')), String.valueOf(sObj.get('Id')));
		        }

		        List<SObject> lstToInsert = new List<SObject>();
		        List<SObject> lstToUpdate = new List<SObject>();

		        for(SObject sObj: objectsBatch) {
		        	if(sfIdsByExternalId.containsKey(String.valueOf(sObj.get('External_Id__c')))){
		        		sObj.put('Id', sfIdsByExternalId.get(String.valueOf(sObj.get('External_Id__c'))));
		        		lstToUpdate.add(sObj);
		        	}
		        	else {
		        		lstToInsert.add(sObj);
		        	}
		        }

		        System.debug(lstToInsert.size() + ' objects to insert.');
		        System.debug(lstToUpdate.size() + ' objects to update.');

		        // DML
		        update lstToUpdate; // For now, only inserts
				insert lstToInsert;
			}

		} 
		catch(Exception ex){
			
			System.debug(ex.getMessage());

			this.errorMessages.add(ex.getMessage());

			throw ex;
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		
		if(this.errorMessages.size() > 0){
			String subject = 'Exception processing data load for objects of type: ' + this.objectType.getDescribe().getName();
			WaveConfiguratorUtils.sendEmail(UserInfo.getUserEmail(), subject, String.join(this.errorMessages, '\r\n'));
		}
	}

	private void prepareSmartLookups(){
		
    	this.smartLookups = new List<SmartLookup>();

    	// Now we traverse relations of the object
    	for(WaveApplicationObjectRelation relObj: this.relations) {
    		
    		SmartLookup smLookUp = new SmartLookup();

    		String csvColumnName = relObj.csvColumnName;
    		smLookUp.columnNumber = this.fieldIndexes.get(csvColumnName);
    		smLookUp.SObjectType = relObj.targetSObject;
    		smLookUp.targetField = relObj.targetSObjectLookupField;

    		this.fieldPositions.put(smLookUp.columnNumber, relObj.foreignKeyField);
    		this.smartLookups.add(smLookUp);
    	}
	}

	private void processSmartLookupForBatch(List<List<String>> scope){
		
		if(scope != null) {

        	// Get all possible unique values to be replaced with IDs
        	// For each smart lookup
	        for (SmartLookup smLookUp : this.smartLookups) {

	        	// For each row we collect the values in the set
	            for (List<String> row : scope) {
	            	String val = row[smLookUp.columnNumber];
	            	if(String.isNotBlank(val)){
	            		smLookUp.plainTextValues.add(val.trim());
	            	}
	            }
	        }

	        // Get mapping of id to name, and add to lookup object
	        for (SmartLookup s : this.smartLookups) {	        	
	            
	            List<String> relevantValues = new List<String>(s.plainTextValues);
	            String sObjToQuery = s.SObjectType;
	            String sFieldToQuery = s.targetField;
				String generatedQuery = 'SELECT Id, ' + sFieldToQuery + ' FROM ' + sObjToQuery + ' WHERE ' + sFieldToQuery + ' IN :relevantValues';

	            // RecordType special hadling
				if(sObjToQuery == 'RecordType'){
					generatedQuery += ' AND SobjectType = \'' + this.objectType.getDescribe().getName() + '\'';
				}

	            List<SObject> temp = Database.query(generatedQuery);
	            
	            for (SObject t: temp) {
	                s.replaceValues.put(String.valueOf(t.get(sFieldToQuery)), String.valueOf(t.get('Id')));
                    System.debug(s.columnNumber + ' ' + String.valueOf(t.get(sFieldToQuery)) + ' ' + String.valueOf(t.get('Id')));
                    System.debug(s.columnNumber + ' ' + s.replaceValues.get(String.valueOf(t.get(sFieldToQuery))));
	            }

	            // Search whether there are Extenal_Id__c with not found id
	            for(String relVal: relevantValues) {
	            	if(String.isNotBlank(relVal) && !s.replaceValues.containsKey(relVal)){
	            		// This time: Throw exception for not being able to find Id for lookup
	            		throw new CsvDataImportException(String.format('Id not found for {0} = "{1}" in SObject: {2}.', new String[]{ sFieldToQuery, relVal, sObjToQuery }));
	            	}
	            }
	        }
	        
	        // Replace name values with Id equivalent
	        for (List<String> row : scope) {
	            for (SmartLookup s: this.smartLookups) {
                    // s.replaceValues.get(row[s.ColumnNumber]) is turning out to be null, 
                    // so we are going to trim row[s.ColumnNumber]
                    //System.debug(s.columnNumber + ' ' + row[s.ColumnNumber] + ' ' + s.replaceValues.get(row[s.ColumnNumber]));
	            	if(String.isNotBlank(row[s.ColumnNumber])){
	            		row[s.ColumnNumber] = s.replaceValues.get(row[s.ColumnNumber].trim());
	            	}
	            }
	        }
		}
	}

	global class CsvDataImportException extends Exception {
		
	}
}