public with sharing virtual class WaveCsvDataRetriever implements IMockarooHelper {
	
	public WaveCsvDataRetriever() {
		
	}

	public List<List<String>> getData(String dataUrl, Boolean skipHeaders){
		
		List<List<String>> allFields = new List<List<String>>();
		String contents = this.mockarooCallout(dataUrl);
		contents = contents.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
        contents = contents.replaceAll('""','DBLQT');
        contents = contents.replaceAll('\r', '');
		List<String> lines = contents.split('\n');
		Integer num = 0;

        for(String line : lines) {
            
            // check for blank CSV lines (only commas)
            if (!String.isBlank(line.replaceAll(',',''))){
            	
            	List<String> fields = line.split(',');	
	            List<String> cleanFields = new List<String>();
	            String compositeField;
	            Boolean makeCompositeField = false;
	            
	            for(String field : fields) {
	                if (field.startsWith('"') && field.endsWith('"')) {
	                    cleanFields.add(field.replaceAll('DBLQT','"'));
	                } 
	                else if (field.startsWith('"')) {
	                    makeCompositeField = true;
	                    compositeField = field;
	                } 
	                else if (field.endsWith('"')) {
	                    compositeField += ',' + field;
	                    cleanFields.add(compositeField.replaceAll('DBLQT','"'));
	                    makeCompositeField = false;
	                } 
	                else if (makeCompositeField) {
	                    compositeField +=  ',' + field;
	                } 
	                else {
	                    cleanFields.add(field.replaceAll('DBLQT','"'));
	                }
	            }

	            allFields.add(cleanFields);
            }
        }

        if(skipHeaders){
        	allFields.remove(0);
        }

        return allFields;
	}

	public String validateDataURL(String dataUrl){
		String validationMessage = '';
		return validationMessage;
	}

	public List<String> getSchemaFieldNames(String dataUrl){
		List<String> lstFields = new List<String>();

		String contents = this.mockarooCallout(dataUrl);
		
		if(!String.isBlank(contents)){
			List<String> lines = contents.split('\n');

			if(lines.size() > 0){
				String headers = lines.get(0);
				lstFields = headers.trim().split(',');
			}
		}

		return lstFields;
	}

	protected String mockarooCallout(String url){

		HttpRequest req = new HttpRequest();
		req.setEndpoint(url);
        req.setMethod('GET');
        req.setTimeout(120000);

		Http http = new Http();
        HTTPResponse res = http.send(req);

		return res.getBody();
	}
}