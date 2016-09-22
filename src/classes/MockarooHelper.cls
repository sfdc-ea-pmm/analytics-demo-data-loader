public with sharing virtual class MockarooHelper implements IMockarooHelper {
	
	private final String mockarooBaseUrl = 'https://sfdc-mockaroo.herokuapp.com/';

	public MockarooHelper() {
		
	}

	public List<List<String>> getData(String dataUrl, Boolean skipHeaders){
		
		List<List<String>> allFields = new List<List<String>>();
		String contents = this.mockarooCallout(dataUrl);
		contents = contents.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
        contents = contents.replaceAll('""','DBLQT');
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
		if(dataUrl.startsWith(this.mockarooBaseUrl)){
			
			// Now check parameters
			String uriPart = this.mockarooBaseUrl.difference(dataUrl);
			Pattern uriPattern = Pattern.compile('[a-zA-z0-9]+\\/download\\?count=\\d+\\&key=[a-zA-z0-9]+');
			Matcher uriMatcher = uriPattern.matcher(uriPart);
			
			if(!uriMatcher.matches()){
				validationMessage = 'Invalid URL. It doesn\'t point to any Mockaroo schema.';
			}
		}
		else {
			validationMessage = 'Invalid URL. It doesn\'t point to any Mockaroo schema.';
		}

		return validationMessage;
	}

	public List<String> getSchemaFieldNames(String dataUrl){
		List<String> lstFields = new List<String>();

		// We make sure that will be working with a valid Mockaroo schema url
		if(String.isBlank(this.validateDataURL(dataUrl))){
			String[] firstParts = dataUrl.split('\\?'); // firstParts[1] wil hold the query string
			String[] queryString = firstParts[1].split('\\&');

			// Will search for key component 
			Integer i = 0;
			String keyParamValue = '';

			while (String.isEmpty(keyParamValue) && i < queryString.size()) {
				if(queryString[i].startsWithIgnoreCase('key=')){
					keyParamValue = queryString[i].removeStartIgnoreCase('key=');
				}
				i++;
			}

			// If we have key param value set
			if(!String.isEmpty(keyParamValue)){
				// Will download 0 rows, only the headers to retrieve the schema
				String urlHeadersOnly = String.format('{0}?count=0&key={1}', new String[]{
					firstParts[0],
					keyParamValue
				});

				String headers = this.mockarooCallout(urlHeadersOnly);
				if(!String.isBlank(headers)){
					lstFields = headers.trim().split(',');
				}
			}
		}

		return lstFields;
	}

	protected String mockarooCallout(String url){

		HttpRequest req = new HttpRequest();
		req.setEndpoint(url);
        req.setMethod('GET');

		Http http = new Http();
        HTTPResponse res = http.send(req);

		return res.getBody();
	}
}