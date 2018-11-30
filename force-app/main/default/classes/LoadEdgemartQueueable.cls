public with sharing class LoadEdgemartQueueable implements Queueable, Database.AllowsCallouts {

    private String sessionId;
    private WaveApplicationEdgemart edgemartToLoad;

    public LoadEdgemartQueueable(WaveApplicationEdgemart edg, String sessionId) {
        this.edgemartToLoad = edg;
		this.sessionId = sessionId;
    }

    public void execute(QueueableContext context) {
        // Process the load of the edgemart
        
    }
}
