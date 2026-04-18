/**
 * @description Trigger automation for Account object
 * @author Oscar Lopez
 * @date 2026-02-14
 */
trigger AccountAutomationTrigger on Account (before insert, before update) {
    
    for (Account acc : Trigger.new) {
        // Auto-populate Description with timestamp
        if (acc.Description == null || acc.Description == '') {
            acc.Description = 'Account managed by CI/CD Pipeline - Last updated: ' + 
                             System.now().format('yyyy-MM-dd HH:mm:ss');
        } else if (Trigger.isUpdate) {
            // Append update timestamp if Description already exists
            if (!acc.Description.contains('Last updated:')) {
                acc.Description += ' - Last updated: ' + 
                                  System.now().format('yyyy-MM-dd HH:mm:ss');
            }
        }
    }
}