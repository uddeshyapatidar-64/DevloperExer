public class exe_2_1 {
    /*
    Find everyone named "John" in Consultants and HR Contacts with one search.
    The same search, but only male people from both. Change the data model if you need to.
    */
    public Static List<List<sObject>> searchName(string SearchVar){
        
        List<List<sObject>> searchRes = [
            FIND :searchVar
            IN All fields
            Returning
            Consultant__c(Id, First_Name__c  where Gender__c = 'Male'),
            Contact(Id, Name  Where GenderIdentity = 'Male')
            WITH USER_MODE
        ];
        
        System.debug('searchRes >>> :: '+searchRes);
        System.debug(searchRes[0]);
        return searchRes;
    }   
    /*
    Find positions whose description mentions "Apex".
    */
    public static void findPosition(String searchVar){
        List<List<SObject>> searchResults = [
            FIND :searchVar
            IN all FIELDS
            RETURNING Position__c(id, Name)
        ];
        system.debug('Position with ' + searchVar + ' in discription:: '+ searchResults);
    }

    /*
    In two sentences: when is SOSL a better choice than SOQL?
    > SOSL is better than SOQL when we need to search for specific text across multiple objects and fields simultaneously. SOQL is better when we know which object and fields we want to query and need to filter records using specific conditions.
    */
}