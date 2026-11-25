/**
 * @author Uddeshya Patidar
 * @date 2026-11-25
 *
 * @group General
 * @group-content Recruitment Services
 *
 * @description Provides recruitment-related services, including retrieving
 * consultant information, calculating working days, and listing    
 * standard and custom objects in the organization.
 *
 * @see Account
 * @see Hiring__c
 * @see Consultant__c
 */
public with sharing class RecruitmentService {

    /**
     * @description Custom exception used for invalid inputs in recruitment services.
     * @see RecruitmentService
     */
    public class RecruitmentServiceException extends Exception {}


    /**
     * @description Returns the first names of consultants hired by an Account.
     *
     * @param employerId The Account ID of the employer.
     * @return A list of consultant first names.
     * @throws RecruitmentServiceException If the ID is null or is not an Account ID.
     *
     * @example
     * List<String> names =
     *     RecruitmentService.getConsultantNames(accountId);
     *
     * @see Account
     * @see Hiring__c
     */
    public static List<String> getConsultantNames(Id employerId) {

        if (employerId == null) {
            throw new RecruitmentServiceException('Employer Id cannot be null.');
        }
        
        List<String> consultantNames = new List<String>();

        for (Hiring__c hiring : [
            SELECT Consultant__r.First_Name__c
            FROM Hiring__c
            WHERE Employer__c = :employerId
            AND Consultant__c != null
            WITH USER_MODE
        ]) {
            if (hiring.Consultant__r.First_Name__c != null) {
                consultantNames.add(
                    hiring.Consultant__r.First_Name__c
                );
            }
        }

        return consultantNames;
    }


    /**
     * @description Returns consultant IDs associated with a single Account.
     *
     * @param employerId The Account ID of the employer.
     * @return A map containing the Account ID and its consultant IDs.
     * @throws RecruitmentServiceException If the supplied ID is not an Account ID.
     *
     * @example
     * Map<Id, Set<Id>> result =
     *     RecruitmentService.getConsultantsByEmployer(accountId);
     *
     * @see Account
     * @see Hiring__c
     */
    public static Map<Id, Set<Id>> getConsultantsByEmployer(Id employerId) {

        if (employerId == null) {
            return new Map<Id, Set<Id>>();
        }

        return getConsultantsByEmployer(
            new Set<Id>{ employerId }
        );
    }


    /**
     * @description Returns consultant IDs grouped by their employer Account IDs.
     *
     * @param employerIds A set of Account IDs.
     * @return A map where each Account ID contains its associated consultant IDs.
     * @throws RecruitmentServiceException If an invalid Account ID is supplied.
     *
     * @example
     * Map<Id, Set<Id>> result =
     *     RecruitmentService.getConsultantsByEmployer(accountIds);
     *
     * @see Account
     * @see Hiring__c
     */
    public static Map<Id, Set<Id>> getConsultantsByEmployer(Set<Id> employerIds) {

        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();

        if (employerIds == null || employerIds.isEmpty()) {
            return result;
        }

        // Validate Account IDs and initialize empty consultant sets.
        for (Id employerId : employerIds) {

            if (employerId == null ||
                employerId.getSObjectType() != Account.SObjectType) {

                throw new RecruitmentServiceException(
                    'Invalid Employer Id supplied. Expected Account IDs.'
                );
            }

            result.put(employerId, new Set<Id>());
        }

        // Retrieve consultants for all supplied Accounts in one query.
        for (Hiring__c hiring : [
            SELECT Employer__c, Consultant__c
            FROM Hiring__c
            WHERE Employer__c IN :employerIds
            AND Consultant__c != null
            WITH USER_MODE
        ]) {
            result.get(hiring.Employer__c).add(
                hiring.Consultant__c
            );
        }

        return result;
    }


    /**
     * @description Counts working days between two dates, excluding the start
     * and end dates, weekends, and organization holidays.
     * The dates can be supplied in either order.
     *
     * @param startDate The first date of the range.
     * @param endDate The second date of the range.
     * @return The number of working days between the two dates.
     * @throws RecruitmentServiceException If either date is null.
     *
     * @example
     * Integer days = RecruitmentService.countWorkingDays(
     *     Date.newInstance(2026, 1, 1),
     *     Date.newInstance(2026, 1, 10)
     * );
     *
     * @see Holiday
     */
    public static Integer countWorkingDays(Date startDate, Date endDate) {

        if (startDate == null || endDate == null) {
            throw new RecruitmentServiceException(
                'Start Date and End Date cannot be null.'
            );
        }

        // Normalize dates so the calculation works in either order.
        Date firstDate = startDate < endDate ? startDate : endDate;
        Date lastDate = startDate > endDate ? startDate : endDate;

        // Exclude the start and end dates.
        firstDate = firstDate.addDays(1);
        lastDate = lastDate.addDays(-1);

        if (firstDate > lastDate) {
            return 0;
        }

        // Calculate weekdays using complete weeks.
        Integer totalDays = firstDate.daysBetween(lastDate) + 1;
        Integer workingDays = (totalDays / 7) * 5;

        // Calculate weekdays in the remaining days.
        Integer remainingDays = Math.mod(totalDays, 7);
        Date currentDate = firstDate.addDays((totalDays / 7) * 7);

        for (Integer i = 0; i < remainingDays; i++) {

            Integer day = Integer.valueOf(
                Datetime.newInstance(
                    currentDate.addDays(i),
                    Time.newInstance(0, 0, 0, 0)
                ).format('u')
            );

            if (day <= 5) {
                workingDays++;
            }
        }

        // Retrieve organization holidays within the date range.
        Set<Date> holidays = new Set<Date>();

        for (Holiday h : [
            SELECT ActivityDate
            FROM Holiday
            WHERE ActivityDate >= :firstDate
            AND ActivityDate <= :lastDate
            WITH USER_MODE
        ]) {
            if (h.ActivityDate != null) {

                Integer day = Integer.valueOf(
                    Datetime.newInstance(
                        h.ActivityDate,
                        Time.newInstance(0, 0, 0, 0)
                    ).format('u')
                );

                // Subtract only weekday holidays.
                if (day <= 5) {
                    holidays.add(h.ActivityDate);
                }
            }
        }

        return workingDays - holidays.size();
    }


    /**
     * @description Retrieves and sorts the names of standard and custom
     * objects available in the organization.
     *
     * @return A nested list of object names. Index 0 contains standard
     * objects and index 1 contains custom objects.
     *
     * @example
     * List<List<String>> objects =
     *     RecruitmentService.listOrgObjects();
     *
     * List<String> standardObjects = objects[0];
     * List<String> customObjects = objects[1];
     *
     * @see Schema
     */
    public static List<List<String>> listOrgObjects() {

        List<String> standardObjects = new List<String>();
        List<String> customObjects = new List<String>();

        Map<String, Schema.SObjectType> allObjects =
            Schema.getGlobalDescribe();

        for (String objName : allObjects.keySet()) {

            if (allObjects.get(objName).getDescribe().isCustom()) {
                customObjects.add(objName);
            } else {
                standardObjects.add(objName);
            }
        }

        standardObjects.sort();
        customObjects.sort();

        return new List<List<String>>{
            standardObjects,
            customObjects
        };
    }
}
