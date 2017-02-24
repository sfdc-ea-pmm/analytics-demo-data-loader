public class WaveApplicationObject {
	public String name {get; set;}
	public String url {get; set;}
	public Integer additionalDataFiles {get; set;}
	public Integer recordsToProcess {get; set;}
	public List<WaveApplicationObjectRelation> relations { get; set; }
	public List<WaveApplicationObjectField> fields { get; set; }
}