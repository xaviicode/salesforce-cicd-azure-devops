/**
 * @description Service class for Account operations
 * @author DevOps Team
 * @date 2025-10-04
 */
public with sharing class AccountService {
    
    /**
     * @description Creates a new Account with validation
     * @param accountName Name of the account
     * @param industry Industry of the account
     * @return Id of the created account
     */
    public static Id createAccount(String accountName, String industry) {
        // Validation
        if (String.isBlank(accountName)) {
            throw new IllegalArgumentException('Account name cannot be blank');
        }
        
        // Create Account
        Account newAccount = new Account(
            Name = accountName,
            Industry = industry,
            Active__c = 'Yes'
        );
        
        insert newAccount;
        
        return newAccount.Id;
    }
    
    /**
     * @description Gets active accounts by industry
     * @param industry Industry to filter by
     * @return List of active accounts
     */
    public static List<Account> getActiveAccountsByIndustry(String industry) {
        return [
            SELECT Id, Name, Industry, Active__c 
            FROM Account 
            WHERE Industry = :industry 
            AND Active__c = 'Yes'
            LIMIT 100
        ];
    }
    
    /**
     * @description Updates account industry
     * @param accountId Id of account to update
     * @param newIndustry New industry value
     */
    public static void updateAccountIndustry(Id accountId, String newIndustry) {
        if (accountId == null) {
            throw new IllegalArgumentException('Account Id cannot be null');
        }
        
        Account acc = [SELECT Id FROM Account WHERE Id = :accountId LIMIT 1];
        acc.Industry = newIndustry;
        update acc;
        

        //Test comment for CI/CD pipeline
    }
}