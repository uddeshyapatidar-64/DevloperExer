/**
 * @author Uddeshya Patidar
 * @date 2026-11-28
 *
 * @group General
 *
 * @description Tests Contact Domain business rules for synchronizing
 *              the Account Primary Contact Email field.
 *
 * @see ContactDomain
 * @see ContactTriggerHandler
 * @see ContactTrigger
 */
@isTest
private class ContactPrimaryEmailSyncTest {

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
     * @description Creates and inserts a test Contact.
     *
     * @param accountId Account to associate with the Contact.
     * @param email Email address of the Contact.
     * @param isPrimary Whether the Contact is primary.
     * @return The inserted Contact.
     */
    private static Contact createContact(
        Id accountId,
        String email,
        Boolean isPrimary
    ) {
        Contact con = new Contact(
            LastName = 'Test Contact',
            AccountId = accountId,
            Email = email,
            Is_Primary__c = isPrimary
        );

        insert con;
        return con;
    }

    /**
     * @description Verifies that inserting a primary Contact
     *              synchronizes its Email with the Account.
     */
    @isTest
    static void testPrimaryContactInsert() {
        Account acc = createAccount('Insert Test');

        Test.startTest();

        createContact(acc.Id, 'john@gmail.com', true);

        Test.stopTest();

        Account updatedAccount = [
            SELECT Primary_Contact_Email__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            'john@gmail.com',
            updatedAccount.Primary_Contact_Email__c,
            'Account email should match the primary Contact email.'
        );
    }

    /**
     * @description Verifies that changing the primary Contact's
     *              Email updates the Account email.
     */
    @isTest
    static void testPrimaryContactEmailUpdate() {
        Account acc = createAccount('Email Update Test');

        Contact con = createContact(
            acc.Id,
            'old@gmail.com',
            true
        );

        Test.startTest();

        con.Email = 'new@gmail.com';
        update con;

        Test.stopTest();

        Account updatedAccount = [
            SELECT Primary_Contact_Email__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            'new@gmail.com',
            updatedAccount.Primary_Contact_Email__c,
            'Account email should update when primary Contact email changes.'
        );
    }

    /**
     * @description Verifies that unmarking a primary Contact
     *              clears the Account email when no other primary exists.
     */
    @isTest
    static void testUnmarkPrimaryContact() {
        Account acc = createAccount('Unmark Test');

        Contact con = createContact(
            acc.Id,
            'john@gmail.com',
            true
        );

        Test.startTest();

        con.Is_Primary__c = false;
        update con;

        Test.stopTest();

        Account updatedAccount = [
            SELECT Primary_Contact_Email__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            null,
            updatedAccount.Primary_Contact_Email__c,
            'Account email should be cleared when no primary Contact exists.'
        );
    }

    /**
     * @description Verifies that deleting a primary Contact
     *              clears the Account email.
     */
    @isTest
    static void testDeletePrimaryContact() {
        Account acc = createAccount('Delete Test');

        Contact con = createContact(
            acc.Id,
            'john@gmail.com',
            true
        );

        Test.startTest();

        delete con;

        Test.stopTest();

        Account updatedAccount = [
            SELECT Primary_Contact_Email__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            null,
            updatedAccount.Primary_Contact_Email__c,
            'Account email should be cleared after deleting its primary Contact.'
        );
    }

    /**
     * @description Verifies that undeleting a primary Contact
     *              restores the Account email.
     */
    @isTest
    static void testUndeletePrimaryContact() {
        Account acc = createAccount('Undelete Test');

        Contact con = createContact(
            acc.Id,
            'john@gmail.com',
            true
        );

        delete con;

        Test.startTest();

        undelete con;

        Test.stopTest();

        Account updatedAccount = [
            SELECT Primary_Contact_Email__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            'john@gmail.com',
            updatedAccount.Primary_Contact_Email__c,
            'Account email should be restored after undeleting the primary Contact.'
        );
    }

    /**
     * @description Verifies that moving a primary Contact
     *              clears the old Account and updates the new Account.
     */
    @isTest
    static void testPrimaryContactReparenting() {
        Account oldAccount = createAccount('Old Employer');
        Account newAccount = createAccount('New Employer');

        Contact con = createContact(
            oldAccount.Id,
            'john@gmail.com',
            true
        );

        Test.startTest();

        con.AccountId = newAccount.Id;
        update con;

        Test.stopTest();

        Map<Id, Account> updatedAccounts = new Map<Id, Account>([
            SELECT Id, Primary_Contact_Email__c
            FROM Account
            WHERE Id IN :new Set<Id>{
                oldAccount.Id,
                newAccount.Id
            }
        ]);

        System.assertEquals(
            null,
            updatedAccounts.get(oldAccount.Id).Primary_Contact_Email__c,
            'Old Account email should be cleared.'
        );

        System.assertEquals(
            'john@gmail.com',
            updatedAccounts.get(newAccount.Id).Primary_Contact_Email__c,
            'New Account email should match the primary Contact.'
        );
    }

    /**
     * @description Verifies that inserting multiple primary Contacts
     *              for different Accounts synchronizes all Accounts.
     */
    @isTest
    static void testBulkPrimaryContactInsert() {
        Account accountOne = createAccount('Bulk Account One');
        Account accountTwo = createAccount('Bulk Account Two');
        Account accountThree = createAccount('Bulk Account Three');

        List<Contact> contacts = new List<Contact>{
            new Contact(
                LastName = 'Contact One',
                AccountId = accountOne.Id,
                Email = 'one@gmail.com',
                Is_Primary__c = true
            ),
            new Contact(
                LastName = 'Contact Two',
                AccountId = accountTwo.Id,
                Email = 'two@gmail.com',
                Is_Primary__c = true
            ),
            new Contact(
                LastName = 'Contact Three',
                AccountId = accountThree.Id,
                Email = 'three@gmail.com',
                Is_Primary__c = true
            )
        };

        Test.startTest();

        insert contacts;

        Test.stopTest();

        Map<Id, Account> updatedAccounts = new Map<Id, Account>([
            SELECT Id, Primary_Contact_Email__c
            FROM Account
            WHERE Id IN :new Set<Id>{
                accountOne.Id,
                accountTwo.Id,
                accountThree.Id
            }
        ]);

        System.assertEquals(
            'one@gmail.com',
            updatedAccounts.get(accountOne.Id).Primary_Contact_Email__c
        );

        System.assertEquals(
            'two@gmail.com',
            updatedAccounts.get(accountTwo.Id).Primary_Contact_Email__c
        );

        System.assertEquals(
            'three@gmail.com',
            updatedAccounts.get(accountThree.Id).Primary_Contact_Email__c
        );
    }

    /**
     * @description Verifies that inserting a non-primary Contact
     *              does not populate the Account primary email field.
     */
    @isTest
    static void testNonPrimaryContactInsert() {
        Account acc = createAccount('Non Primary Test');

        Test.startTest();

        createContact(acc.Id, 'david@gmail.com', false);

        Test.stopTest();

        Account updatedAccount = [
            SELECT Primary_Contact_Email__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            null,
            updatedAccount.Primary_Contact_Email__c,
            'Non-primary Contact should not populate the Account email.'
        );
    }
}