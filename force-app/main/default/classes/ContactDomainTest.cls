/**
 * @author Uddeshya Patidar
 * @date 2026-11-28
 *
 * @group General
 *
 * @description Tests ContactDomain primary Contact validation
 *              for single and bulk database operations.
 *
 * @see ContactDomain
 * @see ContactTriggerHandler
 */
@isTest
private class ContactDomainTest {

    /**
     * @description Verifies that a second primary Contact cannot
     *              be created for an Account that already has one.
     *
     * @return void
     */
    @isTest
    static void testPreventSecondPrimaryContact() {

        Account employer = new Account(Name = 'ABC Technologies');
        insert employer;

        Contact existingPrimary = new Contact(
            LastName = 'Gunwant',
            AccountId = employer.Id,
            Is_Primary__c = true
        );
        insert existingPrimary;

        Contact newPrimary = new Contact(
            LastName = 'Yashika',
            AccountId = employer.Id,
            Is_Primary__c = true
        );

        Test.startTest();

        Database.SaveResult result =
            Database.insert(newPrimary, false);

        Test.stopTest();

        System.assertEquals(
            false,
            result.isSuccess(),
            'A second primary Contact should not be allowed.'
        );

        System.assert(
            result.getErrors()[0].getMessage().contains(
                'Only one primary Contact is allowed'
            ),
            'Expected a primary Contact validation error.'
        );
    }

    /**
     * @description Verifies that multiple primary Contacts
     *              for the same Account are rejected in bulk.
     *
     * @return void
     */
    @isTest
    static void testPreventMultiplePrimaryContactsInBulk() {

        Account employer = new Account(Name = 'XYZ Technologies');
        insert employer;

        List<Contact> contacts = new List<Contact>{

            new Contact(
                LastName = 'Lakshya',
                AccountId = employer.Id,
                Is_Primary__c = true
            ),

            new Contact(
                LastName = 'Garvit',
                AccountId = employer.Id,
                Is_Primary__c = true
            )

        };

        Test.startTest();

        Database.SaveResult[] results =
            Database.insert(contacts, false);

        Test.stopTest();

        System.assertEquals(2, results.size());

        System.assertEquals(
            false,
            results[0].isSuccess(),
            'First primary Contact should fail.'
        );

        System.assertEquals(
            false,
            results[1].isSuccess(),
            'Second primary Contact should fail.'
        );
    }

    /**
     * @description Verifies that an existing primary Contact
     *              can be replaced when both Contacts are updated
     *              in the same bulk transaction.
     *
     * @return void
     */
    @isTest
    static void testReplacePrimaryContactInBulkUpdate() {

        Account employer = new Account(Name = 'PQR Technologies');
        insert employer;

        Contact existingPrimary = new Contact(
            LastName = 'Anjali',
            AccountId = employer.Id,
            Is_Primary__c = true
        );

        Contact secondary = new Contact(
            LastName = 'Uddeshya',
            AccountId = employer.Id,
            Is_Primary__c = false
        );

        insert new List<Contact>{
            existingPrimary,
            secondary
        };

        Contact removePrimary = new Contact(
            Id = existingPrimary.Id,
            Is_Primary__c = false
        );

        Contact promoteSecondary = new Contact(
            Id = secondary.Id,
            Is_Primary__c = true
        );

        Test.startTest();

        update new List<Contact>{
            removePrimary,
            promoteSecondary
        };

        Test.stopTest();

        List<Contact> updatedContacts = [
            SELECT Id, Is_Primary__c
            FROM Contact
            WHERE AccountId = :employer.Id
            AND Is_Primary__c = true
        ];

        System.assertEquals(
            1,
            updatedContacts.size(),
            'Exactly one primary Contact should remain.'
        );

        System.assertEquals(
            secondary.Id,
            updatedContacts[0].Id,
            'The new primary Contact should be Priya.'
        );
    }

    /**
     * @description Verifies that different Accounts can each
     *              have their own primary Contact in one bulk insert.
     *
     * @return void
     */
    @isTest
    static void testPrimaryContactsForDifferentAccounts() {

        Account employerOne = new Account(Name = 'Employer One');
        Account employerTwo = new Account(Name = 'Employer Two');

        insert new List<Account>{
            employerOne,
            employerTwo
        };

        List<Contact> contacts = new List<Contact>{

            new Contact(
                LastName = 'Gaurav',
                AccountId = employerOne.Id,
                Is_Primary__c = true
            ),

            new Contact(
                LastName = 'Anirudh',
                AccountId = employerTwo.Id,
                Is_Primary__c = true
            )

        };

        Test.startTest();

        Database.SaveResult[] results =
            Database.insert(contacts, false);

        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess());
        System.assertEquals(true, results[1].isSuccess());
    }
}