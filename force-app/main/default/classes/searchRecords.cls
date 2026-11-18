public with sharing class searchRecords {
  public static void searchRecords() {
        List<List<SObject>> searchResults = [
            FIND 'John' IN ALL FIELDS
            RETURNING
            Consultant__c(Id, Name),
            HR_Contact__c(Id, Name)
        ];

        for (List<SObject> records : searchResults) {
            for (SObject record : records) {
                System.debug(record);
            }
        }
    }
}   