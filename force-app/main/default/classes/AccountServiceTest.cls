/**
 * @description Test class for AccountService
 * @author DevOps Team
 * @date 2025-10-04
 */
@isTest
private class AccountServiceTest {
    
    /**
     * @description Setup test data
     */
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                Industry = 'Technology',
                Active__c = 'Yes'
            ));
        }
        
        insert testAccounts;
    }
    
    /**
     * @description Test createAccount with valid data
     */
    @isTest
    static void testCreateAccount_ValidData() {
        // Arrange
        String accountName = 'New Test Account';
        String industry = 'Finance';
        
        // Act
        Test.startTest();
        Id accountId = AccountService.createAccount(accountName, industry);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, accountId, 'Account should be created');
        
        Account createdAccount = [SELECT Name, Industry, Active__c FROM Account WHERE Id = :accountId];
        System.assertEquals(accountName, createdAccount.Name, 'Name should match');
        System.assertEquals(industry, createdAccount.Industry, 'Industry should match');
        System.assertEquals('Yes', createdAccount.Active__c, 'Active should be Yes');
    }
    
    /**
     * @description Test createAccount with blank name
     */
    @isTest
    static void testCreateAccount_BlankName() {
        // Arrange
        String accountName = '';
        String industry = 'Technology';
        
        // Act & Assert
        Test.startTest();
        try {
            AccountService.createAccount(accountName, industry);
            System.assert(false, 'Should have thrown exception');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Exception thrown as expected');
            System.assert(e.getMessage().contains('blank'), 'Error message should mention blank');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test getActiveAccountsByIndustry
     */
    @isTest
    static void testGetActiveAccountsByIndustry() {
        // Arrange
        String industry = 'Technology';
        
        // Act
        Test.startTest();
        List<Account> results = AccountService.getActiveAccountsByIndustry(industry);
        Test.stopTest();
        
        // Assert
        System.assertEquals(5, results.size(), 'Should return 5 accounts');
        
        for (Account acc : results) {
            System.assertEquals(industry, acc.Industry, 'All should be Technology');
            System.assertEquals('Yes', acc.Active__c, 'All should be active');
        }
    }
    
    /**
     * @description Test updateAccountIndustry
     */
    @isTest
    static void testUpdateAccountIndustry() {
        // Arrange
        Account testAccount = [SELECT Id, Industry FROM Account LIMIT 1];
        String newIndustry = 'Healthcare';
        
        // Act
        Test.startTest();
        AccountService.updateAccountIndustry(testAccount.Id, newIndustry);
        Test.stopTest();
        
        // Assert
        Account updatedAccount = [SELECT Industry FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(newIndustry, updatedAccount.Industry, 'Industry should be updated');
    }
    
    /**
     * @description Test updateAccountIndustry with null Id
     */
    @isTest
    static void testUpdateAccountIndustry_NullId() {
        // Act & Assert
        Test.startTest();
        try {
            AccountService.updateAccountIndustry(null, 'Technology');
            System.assert(false, 'Should have thrown exception');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Exception thrown as expected');
        }
        Test.stopTest();
    }
}