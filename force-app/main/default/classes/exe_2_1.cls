public class exe_2_1 {
    /**
     * My approch Missing : No input validation, No exception handling, Debug statements, Hardcoded Male and May return all Contacts, not just HR Contacts	
     */
    // public Static List<List<sObject>> searchName(string SearchVar){
        
    //     List<List<sObject>> searchRes = [
    //         FIND :searchVar
    //         IN All fields
    //         Returning
    //         Consultant__c(Id, First_Name__c  where Gender__c = 'Male'),
    //         Contact(Id, Name  Where GenderIdentity = 'Male')
    //         WITH USER_MODE
    //     ];
        
    //     System.debug('searchRes >>> :: '+searchRes);
    //     System.debug(searchRes[0]);
    //     return searchRes;
    // }   
    
    // public static void findPosition(String searchVar){
    //     List<List<SObject>> searchResults = [
    //         FIND :searchVar
    //         IN all FIELDS
    //         RETURNING Position__c(id, Name)
    //     ];
    //     system.debug('Position with ' + searchVar + ' in discription:: '+ searchResults);
    // }

    /**
     * New approch with improvements: To find people with name from Consultants and HR Contacts with one search.
     */
    public static List<List<SObject>> searchPeople(String searchTerm) {
        if (String.isBlank(searchTerm)) {
            throw new IllegalArgumentException('Search term cannot be empty.');
        }
        List<List<SObject>> results = [
            FIND :searchTerm IN ALL FIELDS RETURNING 
            Consultant__c(Id, First_Name__c), 
            Contact(Id, Name) 
            WITH USER_MODE];
        return results;
    }

    /**
     * Diffrent search method but only male people from both. Created a dynamic method in which we can pass gender male or female.
     */
    public static List<List<SObject>> searchPeopleByGender(String searchTerm, String gender) {

        if (String.isBlank(searchTerm)) {
            throw new IllegalArgumentException('Search term cannot be empty.');
        }

        if (String.isBlank(gender)) {
            throw new IllegalArgumentException('Gender cannot be empty.');
        }

        List<List<SObject>> results = [
            FIND :searchTerm IN ALL FIELDS
            RETURNING
            Consultant__c(Id, First_Name__c WHERE Gender__c = :gender),
            Contact(Id, Name WHERE GenderIdentity = :gender)
            WITH USER_MODE
];
        return results;
    }

    /**
     * To find positions which mentions "Apex" in any of the fields.
     */
    public static List<List<SObject>> searchPositions(String searchTerm) {

        if (String.isBlank(searchTerm)) {
            throw new IllegalArgumentException('Search term cannot be empty.');
        }

        List<List<SObject>> results = [
            FIND :searchTerm
            IN ALL FIELDS
            RETURNING Position__c(Id, Name)
            WITH USER_MODE
        ];
        return results;
    }
}
