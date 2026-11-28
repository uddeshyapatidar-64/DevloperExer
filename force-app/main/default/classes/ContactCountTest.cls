/**
 * @author Uddeshya Patidar
 * @date 2026-11-28
 *
 * @group General
 *
 * @description Tests the Contact Count synchronization rule.
 *              Ensures Account Contact_Count__c remains accurate
 *              after Contact insert, update, delete, undelete,
 *              and reparenting operations.
 *
 * @see ContactDomain
 * @see ContactTriggerHandler
 * @see ContactTrigger
 */
@isTest
private class ContactCountTest {

    /**
     * @description Creates and inserts a test Account.
     *
     * @param accountName Name of the Account.
     * @return The inserted Account.
     */
    private static Account createAccount(String accountName) {
        Account acc = new Account(Name = accountName);
        insert acc;
        return acc;
    }

    /**
     * @description Creates a Contact associated with an Account.
     *
     * @param accountId Account to associate with the Contact.
     * @param lastName Last name of the Contact.
     * @return An uninserted Contact.
     */
    private static Contact createContact(
        Id accountId,
        String lastName
    ) {
        return new Contact(
            AccountId = accountId,
            LastName = lastName
        );
    }

    /**
     * @description Retrieves the Contact Count from an Account.
     *
     * @param accountId ID of the Account.
     * @return The Account's Contact Count.
     */
    private static Decimal getContactCount(Id accountId) {
        Account acc = [
            SELECT Contact_Count__c
            FROM Account
            WHERE Id = :accountId
        ];

        return acc.Contact_Count__c;
    }

    /**
     * @description Verifies that inserting Contacts updates
     *              the Account Contact Count.
     */
    @isTest
    static void testContactCountAfterInsert() {
        Account acc = createAccount('Insert Test');

        List<Contact> contacts = new List<Contact>{
            createContact(acc.Id, 'John'),
            createContact(acc.Id, 'David'),
            createContact(acc.Id, 'Sarah')
        };

        Test.startTest();

        insert contacts;

        Test.stopTest();

        System.assertEquals(
            3,
            getContactCount(acc.Id),
            'Contact Count should be 3 after inserting three Contacts.'
        );
    }

    /**
     * @description Verifies that deleting a Contact decreases
     *              the Account Contact Count.
     */
    @isTest
    static void testContactCountAfterDelete() {
        Account acc = createAccount('Delete Test');

        List<Contact> contacts = new List<Contact>{
            createContact(acc.Id, 'John'),
            createContact(acc.Id, 'David'),
            createContact(acc.Id, 'Sarah')
        };

        insert contacts;

        Test.startTest();

        delete contacts[0];

        Test.stopTest();

        System.assertEquals(
            2,
            getContactCount(acc.Id),
            'Contact Count should decrease after deleting a Contact.'
        );
    }

    /**
     * @description Verifies that deleting all Contacts
     *              sets the Account Contact Count to zero.
     */
    @isTest
    static void testContactCountAfterDeleteAll() {
        Account acc = createAccount('Delete All Test');

        List<Contact> contacts = new List<Contact>{
            createContact(acc.Id, 'John'),
            createContact(acc.Id, 'David')
        };

        insert contacts;

        Test.startTest();

        delete contacts;

        Test.stopTest();

        System.assertEquals(
            0,
            getContactCount(acc.Id),
            'Contact Count should be zero after deleting all Contacts.'
        );
    }

    /**
     * @description Verifies that undeleting a Contact
     *              increases the Account Contact Count.
     */
    @isTest
    static void testContactCountAfterUndelete() {
        Account acc = createAccount('Undelete Test');

        List<Contact> contacts = new List<Contact>{
            createContact(acc.Id, 'John'),
            createContact(acc.Id, 'David')
        };

        insert contacts;

        delete contacts[0];

        Test.startTest();

        undelete contacts[0];

        Test.stopTest();

        System.assertEquals(
            2,
            getContactCount(acc.Id),
            'Contact Count should increase after undeleting a Contact.'
        );
    }

    /**
     * @description Verifies that reparenting a Contact
     *              updates both old and new Account counts.
     */
    @isTest
    static void testContactCountAfterReparenting() {
        Account oldAccount = createAccount('Old Employer');
        Account newAccount = createAccount('New Employer');

        List<Contact> contacts = new List<Contact>{
            createContact(oldAccount.Id, 'John'),
            createContact(oldAccount.Id, 'David'),
            createContact(newAccount.Id, 'Sarah')
        };

        insert contacts;

        Test.startTest();

        contacts[0].AccountId = newAccount.Id;
        update contacts[0];

        Test.stopTest();

        System.assertEquals(
            1,
            getContactCount(oldAccount.Id),
            'Old Account count should decrease by one.'
        );

        System.assertEquals(
            2,
            getContactCount(newAccount.Id),
            'New Account count should increase by one.'
        );
    }

    /**
     * @description Verifies that bulk insertion of Contacts
     *              updates counts for multiple Accounts.
     */
    @isTest
    static void testBulkContactInsert() {
        Account accountOne = createAccount('Bulk Account One');
        Account accountTwo = createAccount('Bulk Account Two');
        Account accountThree = createAccount('Bulk Account Three');

        List<Contact> contacts = new List<Contact>{
            createContact(accountOne.Id, 'John'),
            createContact(accountOne.Id, 'David'),
            createContact(accountOne.Id, 'Sarah'),
            createContact(accountTwo.Id, 'Mike'),
            createContact(accountTwo.Id, 'Peter'),
            createContact(accountThree.Id, 'James')
        };

        Test.startTest();

        insert contacts;

        Test.stopTest();

        System.assertEquals(
            3,
            getContactCount(accountOne.Id),
            'First Account should have three Contacts.'
        );

        System.assertEquals(
            2,
            getContactCount(accountTwo.Id),
            'Second Account should have two Contacts.'
        );

        System.assertEquals(
            1,
            getContactCount(accountThree.Id),
            'Third Account should have one Contact.'
        );
    }

    /**
     * @description Verifies that updating Contact fields
     *              unrelated to Account association does not
     *              change the Contact Count.
     */
    @isTest
    static void testContactCountUnchangedAfterUpdate() {
        Account acc = createAccount('Update Test');

        List<Contact> contacts = new List<Contact>{
            createContact(acc.Id, 'John'),
            createContact(acc.Id, 'David')
        };

        insert contacts;

        Test.startTest();

        contacts[0].Email = 'john@gmail.com';
        contacts[0].Is_Primary__c = true;
        update contacts[0];

        Test.stopTest();

        System.assertEquals(
            2,
            getContactCount(acc.Id),
            'Contact Count should remain unchanged after updating unrelated fields.'
        );
    }
}