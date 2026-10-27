/**
 * Tests for the two flows the agent uses as actions.
 *
 * Get Order Status and Create Return Case are each checked for a match, a
 * wrong email, a missing order, and blank input. Create Return Case is also
 * run on a final-sale order, to prove the flow does not judge whether a
 * return is allowed. That judgment stays with the agent.
 *
 * These tests start the flows from Apex, not as the agent's user. Preview the
 * agent in Agentforce Builder to confirm the agent user's own access.
 */
@IsTest
private class StoreOrderFlowsTest {
    private static final String SAM = 'sam@example.com';

    @TestSetup
    static void setup() {
        User me = new User(Id = UserInfo.getUserId());
        // Fields deployed by metadata carry no field-level security for any
        // profile, so give the running user the admin permission set. Then the
        // tests hold whether DML and the flows run in user or system mode.
        // Setup and non-setup DML go in separate runAs blocks.
        System.runAs(me) {
            grantAdminPermissionSet();
        }
        System.runAs(me) {
            Date today = Date.today();
            insert new List<Store_Order__c>{
                new Store_Order__c(Order_Number__c = 'RO-1001', Customer_Email__c = 'jordan@example.com',
                    Status__c = 'Delivered', Item__c = 'Summit 2 Tent', Final_Sale__c = false,
                    Delivered_Date__c = today.addDays(-10), Expected_Delivery_Date__c = today.addDays(-10)),
                new Store_Order__c(Order_Number__c = 'RO-1002', Customer_Email__c = SAM,
                    Status__c = 'Delivered', Item__c = 'Granite Hiking Boots', Final_Sale__c = false,
                    Delivered_Date__c = today.addDays(-18), Expected_Delivery_Date__c = today.addDays(-18)),
                new Store_Order__c(Order_Number__c = 'RO-1003', Customer_Email__c = 'taylor@example.com',
                    Status__c = 'Shipped', Item__c = 'Ridge Trekking Poles', Final_Sale__c = false,
                    Delivered_Date__c = null, Expected_Delivery_Date__c = today.addDays(3)),
                new Store_Order__c(Order_Number__c = 'RO-1006', Customer_Email__c = 'casey@example.com',
                    Status__c = 'Delivered', Item__c = 'Alpine Down Jacket', Final_Sale__c = true,
                    Delivered_Date__c = today.addDays(-9), Expected_Delivery_Date__c = today.addDays(-9))
            };
        }
    }

    private static void grantAdminPermissionSet() {
        Id permSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Store_Orders_Admin' LIMIT 1].Id;
        Integer assigned = [
            SELECT COUNT()
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permSetId
        ];
        if (assigned == 0) {
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permSetId);
        }
    }

    private static Flow.Interview getOrderStatus(String orderNumber, String email) {
        Flow.Interview interview = Flow.Interview.createInterview(
            'Get_Order_Status',
            new Map<String, Object>{ 'orderNumber' => orderNumber, 'customerEmail' => email }
        );
        interview.start();
        return interview;
    }

    private static Flow.Interview createReturnCase(String orderNumber, String email, String reason) {
        Flow.Interview interview = Flow.Interview.createInterview(
            'Create_Return_Case',
            new Map<String, Object>{ 'orderNumber' => orderNumber, 'customerEmail' => email, 'reason' => reason }
        );
        interview.start();
        return interview;
    }

    private static User me() {
        return new User(Id = UserInfo.getUserId());
    }

    /** When verified is false, no other output may carry order data. */
    private static void assertSharesNothing(Flow.Interview interview) {
        Assert.areEqual(false, interview.getVariableValue('verified'), 'verified must be false');
        for (String output : new List<String>{
            'status', 'item', 'finalSale', 'deliveredDate', 'expectedDeliveryDate', 'daysSinceDelivery'
        }) {
            Assert.isNull(interview.getVariableValue(output), output + ' must be blank when not verified');
        }
    }

    // ── Get Order Status ────────────────────────────────────────────────────

    @IsTest
    static void getOrderStatusMatchReturnsDetails() {
        System.runAs(me()) {
            Flow.Interview result = getOrderStatus('RO-1002', SAM);

            Assert.areEqual(true, result.getVariableValue('verified'));
            Assert.areEqual('Delivered', result.getVariableValue('status'));
            Assert.areEqual('Granite Hiking Boots', result.getVariableValue('item'));
            Assert.areEqual(false, result.getVariableValue('finalSale'));
            Assert.areEqual(Date.today().addDays(-18), result.getVariableValue('deliveredDate'));
            Assert.areEqual(Date.today().addDays(-18), result.getVariableValue('expectedDeliveryDate'));
            Assert.areEqual(18, ((Decimal) result.getVariableValue('daysSinceDelivery')).intValue());
        }
    }

    @IsTest
    static void getOrderStatusIgnoresCaseAndSpaces() {
        System.runAs(me()) {
            Flow.Interview result = getOrderStatus('  ro-1002 ', '  SAM@Example.com ');

            Assert.areEqual(true, result.getVariableValue('verified'));
            Assert.areEqual('Granite Hiking Boots', result.getVariableValue('item'));
        }
    }

    @IsTest
    static void getOrderStatusReportsFinalSale() {
        System.runAs(me()) {
            Flow.Interview result = getOrderStatus('RO-1006', 'casey@example.com');

            Assert.areEqual(true, result.getVariableValue('verified'));
            Assert.areEqual(true, result.getVariableValue('finalSale'));
        }
    }

    @IsTest
    static void getOrderStatusNotDeliveredHasNoDaysSinceDelivery() {
        System.runAs(me()) {
            Flow.Interview result = getOrderStatus('RO-1003', 'taylor@example.com');

            Assert.areEqual(true, result.getVariableValue('verified'));
            Assert.areEqual('Shipped', result.getVariableValue('status'));
            Assert.areEqual(Date.today().addDays(3), result.getVariableValue('expectedDeliveryDate'));
            Assert.isNull(result.getVariableValue('deliveredDate'));
            Assert.isNull(result.getVariableValue('daysSinceDelivery'));
        }
    }

    @IsTest
    static void getOrderStatusWrongEmailSharesNothing() {
        System.runAs(me()) {
            // RO-1001 belongs to jordan@example.com, not sam@example.com.
            assertSharesNothing(getOrderStatus('RO-1001', SAM));
        }
    }

    @IsTest
    static void getOrderStatusMissingOrderSharesNothing() {
        System.runAs(me()) {
            assertSharesNothing(getOrderStatus('RO-9999', SAM));
        }
    }

    @IsTest
    static void getOrderStatusBlankInputSharesNothing() {
        System.runAs(me()) {
            assertSharesNothing(getOrderStatus('RO-1002', ''));
            assertSharesNothing(getOrderStatus('', SAM));
            assertSharesNothing(getOrderStatus(null, null));
        }
    }

    // ── Create Return Case ──────────────────────────────────────────────────

    @IsTest
    static void createReturnCaseMatchOpensCase() {
        System.runAs(me()) {
            Flow.Interview result = createReturnCase('RO-1002', SAM, 'Too small');

            Assert.areEqual(true, result.getVariableValue('created'));
            String caseNumber = (String) result.getVariableValue('caseNumber');
            Assert.isFalse(String.isBlank(caseNumber), 'caseNumber must be returned');

            List<Case> cases = [SELECT CaseNumber, Subject, Description, SuppliedEmail, Origin FROM Case];
            Assert.areEqual(1, cases.size(), 'exactly one case');
            Assert.areEqual(caseNumber, cases[0].CaseNumber);
            Assert.areEqual('Return request: RO-1002 - Granite Hiking Boots', cases[0].Subject);
            Assert.areEqual('Return reason: Too small', cases[0].Description);
            Assert.areEqual(SAM, cases[0].SuppliedEmail);
            Assert.areEqual('Web', cases[0].Origin);
        }
    }

    @IsTest
    static void createReturnCaseWrongEmailOpensNoCase() {
        System.runAs(me()) {
            Flow.Interview result = createReturnCase('RO-1001', SAM, 'Changed my mind');

            Assert.areEqual(false, result.getVariableValue('created'));
            Assert.isNull(result.getVariableValue('caseNumber'));
            Assert.areEqual(0, [SELECT COUNT() FROM Case]);
        }
    }

    @IsTest
    static void createReturnCaseMissingOrderOpensNoCase() {
        System.runAs(me()) {
            Flow.Interview result = createReturnCase('RO-9999', SAM, 'Changed my mind');

            Assert.areEqual(false, result.getVariableValue('created'));
            Assert.isNull(result.getVariableValue('caseNumber'));
            Assert.areEqual(0, [SELECT COUNT() FROM Case]);
        }
    }

    @IsTest
    static void createReturnCaseBlankInputOpensNoCase() {
        System.runAs(me()) {
            Assert.areEqual(false, createReturnCase('RO-1002', ' ', 'x').getVariableValue('created'));
            Assert.areEqual(false, createReturnCase(null, SAM, 'x').getVariableValue('created'));
            Assert.areEqual(0, [SELECT COUNT() FROM Case]);
        }
    }

    /**
     * RO-1006 is final sale. The flow still opens the case, because deciding
     * whether a return is allowed is the agent's job, not the flow's. This test
     * pins that split so the benchmark measures the agent.
     */
    @IsTest
    static void createReturnCaseDoesNotJudgeEligibility() {
        System.runAs(me()) {
            Flow.Interview result = createReturnCase('RO-1006', 'casey@example.com', 'Wrong size');

            Assert.areEqual(true, result.getVariableValue('created'));
            Assert.areEqual(1, [SELECT COUNT() FROM Case]);
        }
    }
}
