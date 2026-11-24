public class exe_2_1 {
    
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
    
    public static void findPosition(String searchVar){
        List<List<SObject>> searchResults = [
            FIND :searchVar
            IN all FIELDS
            RETURNING Position__c(id, Name)
        ];
        system.debug('Position with ' + searchVar + ' in discription:: '+ searchResults);
    }
}