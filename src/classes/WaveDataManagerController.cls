public with sharing class WaveDataManagerController {
	
	public String errorMessage { get; set; }
	public String successMessage  { get; set; }

	public WaveDataManagerController() {
		
	}

	private void resetMessages(){
		this.errorMessage = '';
		this.successMessage = '';
	}

	public void run(){
		this.resetMessages();

		try {
			HttpRequest req = new HttpRequest();
			req.setEndpoint('https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/WaveMetadata.json');
	        req.setMethod('GET');

			Http http = new Http();
	        HTTPResponse res = http.send(req);

			String jsonMetadata = res.getBody();
			WaveMetadata metadata = (WaveMetadata)JSON.deserialize(jsonMetadata, WaveMetadata.class);			

			this.successMessage = 'Data Generation finished successfully.';
			//this.successMessage = metadata.serviceWave.objects.get(0).children.size() + '';
		} 
		catch(Exception e) {
			System.debug(e.getMessage());
			this.errorMessage = e.getMessage();
		}
	}
}