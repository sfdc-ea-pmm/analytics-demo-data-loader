public with sharing class WaveRestApiUtils {
	
	// Retrieves asset JSON through WAVE REST API, only works within the ORG in which this code executes
	// @param waveAssets: Type of asset to retrieve [folders, datasets, lenses, dashboards]
	// @param requestUrl: If not null, uses this URL to request data
	public static String getWaveAssetsJSON(String waveAssets, String requestUrl){
        HttpRequest req = new HttpRequest();
        String salesforceHost = System.Url.getSalesforceBaseURL().toExternalForm();
        String url = salesforceHost + (requestUrl != null ? requestUrl : '/services/data/v38.0/wave/' + waveAssets + '?pageSize=200');
        req.setEndpoint(url);
        req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        req.setMethod('GET');

        Http httpMgr = new Http();
        HTTPResponse res = httpMgr.send(req);

        return res.getBody();
    }
}