// This class was designed to hold lists of SObjects that will be DMLed 
public class SObjectTransference {
	
	public List<SObject> sObjectsToInsert { get; set; }
	public List<SObject> sObjectsToUpdate { get; set; }
	public List<SObject> sObjectsToDelete { get; set; } // Not used for now
	
	public SObjectTransference(){
		this.sObjectsToInsert = new List<SObject>();
		this.sObjectsToUpdate = new List<SObject>();
		this.sObjectsToDelete = new List<SObject>();
	}	
}