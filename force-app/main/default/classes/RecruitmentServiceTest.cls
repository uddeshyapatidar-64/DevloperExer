/**
 * @author Uddeshya Patidar
 * @date 2026-11-25
 *
 * @group General
 * @group-content Recruitment Services Testing
 *
 * @description Test class for RecruitmentService.
 *              Validates consultant retrieval, employer mapping,
 *              working-day calculations, and organization object listing.
 *
 * @see RecruitmentService
 * @see Account
 * @see Hiring__c
 * @see Consultant__c
 */
@isTest
private class RecruitmentServiceTest {

    /**
     * @description Creates reusable test data for RecruitmentService tests.
     *              Creates an employer, consultants, and hiring records.
     */
    @TestSetup
    static void setupTestData() {

        // Create employer Account.
        Account employer = new Account(
            Name = 'Test Employer'
        );
        insert employer;

        // Create Consultants.
        List<Consultant__c> consultants = new List<Consultant__c>();

        for (Integer i = 1; i <= 3; i++) {
            consultants.add(
                new Consultant__c(
                    First_Name__c = 'Consultant' + i,
                    Last_Name__c = 'Test'
                )
            );
        }

        insert consultants;

        // Create Hiring records.
        List<Hiring__c> hiringRecords = new List<Hiring__c>();

        for (Consultant__c consultant : consultants) {
            hiringRecords.add(
                new Hiring__c(
                    Employer__c = employer.Id,
                    Consultant__c = consultant.Id,
                    Hire_Date__c = Date.today()
                )
            );
        }

        insert hiringRecords;
    }


    /**
     * @description Tests retrieving consultant names for a valid employer.
     *
     * @return void
     *
     * @example
     * RecruitmentServiceTest.testGetConsultantNames();
     */
    @isTest
    static void testGetConsultantNames() {

        Account employer = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Employer'
            LIMIT 1
        ];

        Test.startTest();

        List<String> names =
            RecruitmentService.getConsultantNames(employer.Id);

        Test.stopTest();

        System.assertEquals(
            3,
            names.size(),
            'Expected three consultant names for the employer.'
        );

        System.assert(
            names.contains('Consultant1'),
            'Consultant1 should be present in the returned names.'
        );
    }


    /**
     * @description Tests invalid and null employer IDs for name retrieval.
     *
     * @throws RecruitmentService.RecruitmentServiceException
     *         When the employer ID is invalid.
     */
    @isTest
    static void testGetConsultantNamesInvalidEmployer() {

        Boolean nullExceptionThrown = false;
        Boolean invalidExceptionThrown = false;

        // Test null employer ID.
        try {
            RecruitmentService.getConsultantNames(null);
        } catch (RecruitmentService.RecruitmentServiceException e) {
            nullExceptionThrown = true;
        }

        System.assert(
            nullExceptionThrown,
            'Expected an exception when employer ID is null.'
        );

        // Contact ID is not a valid employer Account ID.
        Contact contact = new Contact(
            LastName = 'Test Contact'
        );
        insert contact;

        try {
            RecruitmentService.getConsultantNames(contact.Id);
        } catch (RecruitmentService.RecruitmentServiceException e) {
            invalidExceptionThrown = true;
        }

        System.assert(
            invalidExceptionThrown,
            'Expected an exception when a non-Account ID is supplied.'
        );
    }


    /**
     * @description Tests retrieving consultant IDs for a single employer.
     *
     * @return void
     */
    @isTest
    static void testGetConsultantsBySingleEmployer() {

        Account employer = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Employer'
            LIMIT 1
        ];

        Test.startTest();

        Map<Id, Set<Id>> result =
            RecruitmentService.getConsultantsByEmployer(employer.Id);

        Test.stopTest();

        System.assertEquals(
            1,
            result.size(),
            'Expected one employer in the returned map.'
        );

        System.assertEquals(
            3,
            result.get(employer.Id).size(),
            'Expected three consultant IDs for the employer.'
        );
    }


    /**
     * @description Tests retrieving consultant IDs for multiple employers.
     *
     * @return void
     */
    @isTest
    static void testGetConsultantsByMultipleEmployers() {

        Account secondEmployer = new Account(
            Name = 'Second Test Employer'
        );
        insert secondEmployer;

        Consultant__c consultant = new Consultant__c(
            First_Name__c = 'ExtraConsultant',
            Last_Name__c = 'Test'
        );
        insert consultant;

        insert new Hiring__c(
            Employer__c = secondEmployer.Id,
            Consultant__c = consultant.Id,
            Hire_Date__c = Date.today()
        );

        Account firstEmployer = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Employer'
            LIMIT 1
        ];

        Set<Id> employerIds = new Set<Id>{
            firstEmployer.Id,
            secondEmployer.Id
        };

        Test.startTest();

        Map<Id, Set<Id>> result =
            RecruitmentService.getConsultantsByEmployer(employerIds);

        Test.stopTest();

        System.assertEquals(
            2,
            result.size(),
            'Expected two employers in the returned map.'
        );

        System.assertEquals(
            3,
            result.get(firstEmployer.Id).size(),
            'First employer should have three consultants.'
        );

        System.assertEquals(
            1,
            result.get(secondEmployer.Id).size(),
            'Second employer should have one consultant.'
        );
    }


    /**
     * @description Tests empty and invalid employer ID collections.
     *
     * @return void
     */
    @isTest
    static void testGetConsultantsByEmployerEdgeCases() {

        // Test null collection.
        Map<Id, Set<Id>> nullResult =
            RecruitmentService.getConsultantsByEmployer(
                (Set<Id>) null
            );

        System.assertEquals(
            0,
            nullResult.size(),
            'Null employer collection should return an empty map.'
        );

        // Test empty collection.
        Map<Id, Set<Id>> emptyResult =
            RecruitmentService.getConsultantsByEmployer(
                new Set<Id>()
            );

        System.assertEquals(
            0,
            emptyResult.size(),
            'Empty employer collection should return an empty map.'
        );

        // Test null single employer ID.
        Map<Id, Set<Id>> singleNullResult =
            RecruitmentService.getConsultantsByEmployer((Id) null);

        System.assertEquals(
            0,
            singleNullResult.size(),
            'Null single employer ID should return an empty map.'
        );

        // Test invalid object ID in the collection.
        Contact contact = new Contact(
            LastName = 'Invalid Employer'
        );
        insert contact;

        Boolean exceptionThrown = false;

        try {
            RecruitmentService.getConsultantsByEmployer(
                new Set<Id>{ contact.Id }
            );
        } catch (RecruitmentService.RecruitmentServiceException e) {
            exceptionThrown = true;
        }

        System.assert(
            exceptionThrown,
            'Expected an exception for a non-Account ID.'
        );
    }


    /**
     * @description Tests bulk processing with 200 consultants and hiring records.
     *
     * @return void
     */
    @isTest
    static void testGetConsultantsByEmployerBulk200() {

        Account employer = new Account(
            Name = 'Bulk Test Employer'
        );
        insert employer;

        List<Consultant__c> consultants = new List<Consultant__c>();

        for (Integer i = 1; i <= 200; i++) {
            consultants.add(
                new Consultant__c(
                    First_Name__c = 'BulkConsultant' + i,
                    Last_Name__c = 'Test'
                )
            );
        }

        insert consultants;

        List<Hiring__c> hiringRecords = new List<Hiring__c>();

        for (Consultant__c consultant : consultants) {
            hiringRecords.add(
                new Hiring__c(
                    Employer__c = employer.Id,
                    Consultant__c = consultant.Id,
                     Hire_Date__c = Date.today()
                )
            );
        }

        insert hiringRecords;

        Test.startTest();

        Map<Id, Set<Id>> result =
            RecruitmentService.getConsultantsByEmployer(
                new Set<Id>{ employer.Id }
            );

        Test.stopTest();

        System.assertEquals(
            200,
            result.get(employer.Id).size(),
            'Bulk retrieval should return all 200 consultant IDs.'
        );
    }


    /**
     * @description Tests working-day calculation between two dates.
     *
     * @return void
     */
    @isTest
    static void testCountWorkingDays() {

        // Monday to Monday: Tuesday through Friday = 4 working days.
        Date startDate = Date.newInstance(2026, 11, 23);
        Date endDate = Date.newInstance(2026, 11, 30);

        Test.startTest();

        Integer result =
            RecruitmentService.countWorkingDays(startDate, endDate);

        Test.stopTest();

        System.assertEquals(
            4,
            result,
            'Expected four working days, excluding the start and end dates.'
        );
    }


    /**
     * @description Tests working-day calculation when dates are reversed.
     *
     * @return void
     */
    @isTest
    static void testCountWorkingDaysReversedDates() {

        Date startDate = Date.newInstance(2026, 11, 30);
        Date endDate = Date.newInstance(2026, 11, 23);

        Integer result =
            RecruitmentService.countWorkingDays(startDate, endDate);

        System.assertEquals(
            4,
            result,
            'Reversing the date order should produce the same result.'
        );
    }


    /**
     * @description Tests working-day calculation for same and adjacent dates.
     *
     * @return void
     */
    @isTest
    static void testCountWorkingDaysBoundaryCases() {

        Date dateValue = Date.newInstance(2026, 11, 25);

        Integer sameDateResult =
            RecruitmentService.countWorkingDays(dateValue, dateValue);

        Integer adjacentDateResult =
            RecruitmentService.countWorkingDays(
                dateValue,
                dateValue.addDays(1)
            );

        System.assertEquals(
            0,
            sameDateResult,
            'Same start and end dates should return zero.'
        );

        System.assertEquals(
            0,
            adjacentDateResult,
            'Adjacent dates should return zero because endpoints are excluded.'
        );
    }


    /**
     * @description Tests null date validation.
     *
     * @return void
     */
    @isTest
    static void testCountWorkingDaysNullDates() {

        Boolean exceptionThrown = false;

        try {
            RecruitmentService.countWorkingDays(
                null,
                Date.today()
            );
        } catch (RecruitmentService.RecruitmentServiceException e) {
            exceptionThrown = true;
        }

        System.assert(
            exceptionThrown,
            'Expected an exception when a date parameter is null.'
        );
    }


    /**
     * @description Tests working-day calculation over a ten-year period.
     *
     * @return void
     */
    @isTest
    static void testCountWorkingDaysTenYears() {

        Date startDate = Date.newInstance(2020, 1, 1);
        Date endDate = Date.newInstance(2030, 1, 1);

        Test.startTest();

        Integer result =
            RecruitmentService.countWorkingDays(startDate, endDate);

        Test.stopTest();

        System.assert(
            result > 0,
            'Ten-year working-day calculation should return a positive result.'
        );
    }


    /**
     * @description Tests that organization holidays are excluded from
     *              the working-day calculation.
     *
     * @return void
     */
    @isTest
    static void testCountWorkingDaysExcludesHolidays() {

        Date startDate = Date.newInstance(2026, 11, 23);
        Date endDate = Date.newInstance(2026, 11, 30);

        // Wednesday, which is a working day.
        Holiday testHoliday = new Holiday(
            Name = 'Test Organization Holiday',
            ActivityDate = Date.newInstance(2026, 11, 25)
        );

        insert testHoliday;

        Test.startTest();

        Integer result =
            RecruitmentService.countWorkingDays(startDate, endDate);

        Test.stopTest();

        System.assertEquals(
            3,
            result,
            'Expected one organization holiday to be excluded from four working days.'
        );
    }


    /**
     * @description Tests organization object listing and classification.
     *
     * @return void
     */
    @isTest
        static void testListOrgObjects() {

            Test.startTest();

            Map<String, List<String>> result =
                RecruitmentService.listOrgObjects();

            Test.stopTest();

            System.assertEquals(
                2,
                result.size(),
                'Expected two entries: standard objects and custom objects.'
            );

            List<String> standardObjects = result.get('Standard Obj');
            System.debug('list of standard object '+standardObjects);
            List<String> customObjects = result.get('Custom Obj');
            System.debug(customObjects);

            System.assert(
                standardObjects.contains('account'),
                'Standard object list should contain Account.'
            );

            System.assert(
                customObjects.contains('Consultant__c'),
                'Custom object list should contain Consultant__c.'
            );

            System.assert(
                standardObjects.contains('Contact'),
                'Standard object list should contain Contact.'
            );
        }


    /**
     * @description Tests that standard and custom object names are sorted.
     *
     * @return void
     */
    @isTest
    static void testListOrgObjectsSorting() {

        Map<String, List<String>> result =
            RecruitmentService.listOrgObjects();

        List<String> standardObjects = result.get('Standard Obj');
        List<String> customObjects = result.get('Custom Obj');

        List<String> sortedStandard = new List<String>();
        List<String> sortedCustom = new List<String>();

        sortedStandard.addAll(standardObjects);
        sortedCustom.addAll(customObjects);

        sortedStandard.sort();
        sortedCustom.sort();

        System.assertEquals(
            sortedStandard,
            standardObjects,
            'Standard object names should be sorted alphabetically.'
        );

        System.assertEquals(
            sortedCustom,
            customObjects,
            'Custom object names should be sorted alphabetically.'
        );
    }

    /**
     * @description Tests repeated organization object listing calls.
     *
     * @return void
     */
    @isTest
    static void testListOrgObjectsRepeatedCalls() {

        Test.startTest();

        Map<String, List<String>> firstResult =
            RecruitmentService.listOrgObjects();

        Map<String, List<String>> secondResult =
            RecruitmentService.listOrgObjects();

        Test.stopTest();

        System.assertEquals(
            firstResult,
            secondResult,
            'Repeated calls should return consistent object lists.'
        );
    }
}
