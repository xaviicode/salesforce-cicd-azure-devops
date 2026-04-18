/**
 * @description Test class for AccountAutomationTrigger
 * @author Oscar Lopez
 * @date 2026-02-14
 */
@isTest
private class AccountAutomationTriggerTest {
    
    /**
     * @description Test trigger on Account insert
     */
    @isTest
    static void testAccountInsertWithEmptyDescription() {
        // Test data
        Account testAccount = new Account(
            Name = 'Test Account CI/CD',
            Description = ''
        );
        
        // Execute
        Test.startTest();
        insert testAccount;
        Test.stopTest();
        
        // Verify
        Account insertedAccount = [SELECT Id, Description FROM Account WHERE Id = :testAccount.Id];
        System.assertNotEquals(null, insertedAccount.Description, 'Description should be populated');
        System.assert(insertedAccount.Description.contains('CI/CD Pipeline'), 'Description should contain CI/CD Pipeline');
        System.assert(insertedAccount.Description.contains('Last updated:'), 'Description should contain timestamp');
    }
    
    /**
     * @description Test trigger on Account insert with null description
     */
    @isTest
    static void testAccountInsertWithNullDescription() {
        // Test data
        Account testAccount = new Account(
            Name = 'Test Account Null Description'
        );
        
        // Execute
        Test.startTest();
        insert testAccount;
        Test.stopTest();
        
        // Verify
        Account insertedAccount = [SELECT Id, Description FROM Account WHERE Id = :testAccount.Id];
        System.assertNotEquals(null, insertedAccount.Description, 'Description should be populated');
        System.assert(insertedAccount.Description.contains('Last updated:'), 'Description should contain timestamp');
    }
    
    /**
     * @description Test trigger on Account update
     */
    @isTest
    static void testAccountUpdate() {
        // Test data - Insert
        Account testAccount = new Account(
            Name = 'Test Account Update',
            Description = 'Initial Description'
        );
        insert testAccount;
        
        // Execute - Update
        Test.startTest();
        testAccount.Name = 'Updated Account Name';
        update testAccount;
        Test.stopTest();
        
        // Verify
        Account updatedAccount = [SELECT Id, Description FROM Account WHERE Id = :testAccount.Id];
        System.assert(updatedAccount.Description.contains('Last updated:'), 'Description should contain update timestamp');
    }
    
    /**
     * @description Test bulk insert
     */
    @isTest
    static void testBulkAccountInsert() {
        // Test data - Bulk
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Bulk Test Account ' + i
            ));
        }
        
        // Execute
        Test.startTest();
        insert accounts;
        Test.stopTest();
        
        // Verify
        List<Account> insertedAccounts = [SELECT Id, Description FROM Account WHERE Name LIKE 'Bulk Test Account%'];
        System.assertEquals(200, insertedAccounts.size(), 'Should insert 200 accounts');
        
        for (Account acc : insertedAccounts) {
            System.assertNotEquals(null, acc.Description, 'Each account should have description');
            System.assert(acc.Description.contains('Last updated:'), 'Each description should have timestamp');
        }
    }
}