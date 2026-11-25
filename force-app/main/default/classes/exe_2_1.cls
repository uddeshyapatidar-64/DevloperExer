/**
 * @author Your Name
 * @date 2026-11-25
 * @group General
 * @description Provides SOSL-based search functionality for Consultants,
 *              Contacts, and Positions. Supports searching across all fields
 *              and filtering people by gender.
 * @see Consultant__c
 * @see Contact
 * @see Position__c
 */
public with sharing class exe_2_1 {

    /**
     * @description Searches for Consultants and Contacts using the provided
     *              search term across all searchable fields.
     * @param searchTerm The text to search for.
     * @return List of SObject lists containing matching Consultants and Contacts.
     * @throws IllegalArgumentException If the search term is empty.
     * @example
     * List<List<SObject>> results =
     *     PeopleSearchService.searchPeople('John');
     * @see Consultant__c
     * @see Contact
     */
    public static List<List<SObject>> searchPeople(String searchTerm) {

        if (String.isBlank(searchTerm)) {
            throw new IllegalArgumentException('Search term cannot be empty.');
        }

        // Normalize the input before using it in the SOSL search.
        searchTerm = searchTerm.trim();

        List<List<SObject>> results = [
            FIND :searchTerm IN ALL FIELDS
            RETURNING
                Consultant__c(Id, First_Name__c),
                Contact(Id, Name)
            WITH USER_MODE
        ];

        return results;
    }

    /**
     * @description Searches for Consultants and Contacts based on the
     *              provided search term and gender.
     * @param searchTerm The text to search for across all searchable fields.
     * @param gender The gender value used to filter matching records.
     * @return List of SObject lists containing matching Consultants and Contacts.
     * @throws IllegalArgumentException If the search term or gender is empty.
     * @example
     * List<List<SObject>> results =
     *     PeopleSearchService.searchPeopleByGender('John', 'Male');
     * @see Consultant__c
     * @see Contact
     */
    public static List<List<SObject>> searchPeopleByGender(
        String searchTerm,
        String gender
    ) {

        if (String.isBlank(searchTerm)) {
            throw new IllegalArgumentException('Search term cannot be empty.');
        }

        if (String.isBlank(gender)) {
            throw new IllegalArgumentException('Gender cannot be empty.');
        }

        // Normalize the input values.
        searchTerm = searchTerm.trim();
        gender = gender.trim();

        List<List<SObject>> results = [
            FIND :searchTerm IN ALL FIELDS
            RETURNING
                Consultant__c(
                    Id,
                    First_Name__c
                    WHERE Gender__c = :gender
                ),
                Contact(
                    Id,
                    Name
                    WHERE GenderIdentity = :gender
                )
            WITH USER_MODE
        ];

        return results;
    }

    /**
     * @description Searches Position records for the provided search term
     *              across all searchable fields.
     * @param searchTerm The text to search for, such as 'Apex'.
     * @return List containing matching Position__c records.
     * @throws IllegalArgumentException If the search term is empty.
     * @example
     * List<List<SObject>> results =
     *     PeopleSearchService.searchPositions('Apex');
     * @see Position__c
     */
    public static List<List<SObject>> searchPositions(String searchTerm) {

        if (String.isBlank(searchTerm)) {
            throw new IllegalArgumentException('Search term cannot be empty.');
        }

        searchTerm = searchTerm.trim();

        List<List<SObject>> results = [
            FIND :searchTerm
            IN ALL FIELDS
            RETURNING Position__c(Id, Name)
            WITH USER_MODE
        ];

        return results;
    }
}
