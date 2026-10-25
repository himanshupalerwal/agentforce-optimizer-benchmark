// Loads the 12 sample Store Orders. Safe to re-run: it upserts on
// Order_Number__c, so a second run refreshes the same 12 records instead of
// adding copies.
//
// Every date is relative to Date.today(), so the 30-day return window always
// lands the same way, whenever you run it. Re-run it on the day you test.
//
//   RO-1001 to RO-1006  are used by the 30 test questions.
//   RO-1007 to RO-1012  are used only by the 60 practice conversations.
//
// Run:  sf apex run --file scripts/apex/load-sample-orders.apex
// Needs the Store_Orders_Admin permission set.

Date today = Date.today();

List<Store_Order__c> orders = new List<Store_Order__c>{
    // ── Test-set orders ─────────────────────────────────────────────────────
    // RO-1001 belongs to jordan@example.com. OS-05 asks for it with sam@example.com.
    new Store_Order__c(Order_Number__c = 'RO-1001', Customer_Email__c = 'jordan@example.com',
        Status__c = 'Delivered', Item__c = 'Summit 2 Tent',
        Final_Sale__c = false, Delivered_Date__c = today.addDays(-10), Expected_Delivery_Date__c = today.addDays(-10)),
    // Inside the 30-day window.
    new Store_Order__c(Order_Number__c = 'RO-1002', Customer_Email__c = 'sam@example.com',
        Status__c = 'Delivered', Item__c = 'Granite Hiking Boots',
        Final_Sale__c = false, Delivered_Date__c = today.addDays(-18), Expected_Delivery_Date__c = today.addDays(-18)),
    // On its way: no return yet.
    new Store_Order__c(Order_Number__c = 'RO-1003', Customer_Email__c = 'taylor@example.com',
        Status__c = 'Shipped', Item__c = 'Ridge Trekking Poles',
        Final_Sale__c = false, Delivered_Date__c = null, Expected_Delivery_Date__c = today.addDays(3)),
    // Outside the 30-day window.
    new Store_Order__c(Order_Number__c = 'RO-1004', Customer_Email__c = 'riley@example.com',
        Status__c = 'Delivered', Item__c = 'Ascent 45 Backpack',
        Final_Sale__c = false, Delivered_Date__c = today.addDays(-54), Expected_Delivery_Date__c = today.addDays(-54)),
    new Store_Order__c(Order_Number__c = 'RO-1005', Customer_Email__c = 'morgan@example.com',
        Status__c = 'Processing', Item__c = 'Merino Hiking Socks (3-pack)',
        Final_Sale__c = false, Delivered_Date__c = null, Expected_Delivery_Date__c = today.addDays(6)),
    // Final sale, and inside the window: only final sale blocks the return.
    new Store_Order__c(Order_Number__c = 'RO-1006', Customer_Email__c = 'casey@example.com',
        Status__c = 'Delivered', Item__c = 'Alpine Down Jacket',
        Final_Sale__c = true, Delivered_Date__c = today.addDays(-9), Expected_Delivery_Date__c = today.addDays(-9)),

    // ── Practice-only orders ────────────────────────────────────────────────
    new Store_Order__c(Order_Number__c = 'RO-1007', Customer_Email__c = 'alex@example.com',
        Status__c = 'Delivered', Item__c = 'Cascade Sleeping Bag',
        Final_Sale__c = false, Delivered_Date__c = today.addDays(-12), Expected_Delivery_Date__c = today.addDays(-12)),
    new Store_Order__c(Order_Number__c = 'RO-1008', Customer_Email__c = 'jamie@example.com',
        Status__c = 'Delivered', Item__c = 'Trail Runner Shoes',
        Final_Sale__c = false, Delivered_Date__c = today.addDays(-41), Expected_Delivery_Date__c = today.addDays(-41)),
    new Store_Order__c(Order_Number__c = 'RO-1009', Customer_Email__c = 'drew@example.com',
        Status__c = 'Shipped', Item__c = 'Basecamp Stove',
        Final_Sale__c = false, Delivered_Date__c = null, Expected_Delivery_Date__c = today.addDays(2)),
    new Store_Order__c(Order_Number__c = 'RO-1010', Customer_Email__c = 'quinn@example.com',
        Status__c = 'Delivered', Item__c = 'Clearance Fleece Vest',
        Final_Sale__c = true, Delivered_Date__c = today.addDays(-5), Expected_Delivery_Date__c = today.addDays(-5)),
    new Store_Order__c(Order_Number__c = 'RO-1011', Customer_Email__c = 'avery@example.com',
        Status__c = 'Processing', Item__c = 'Summit Headlamp',
        Final_Sale__c = false, Delivered_Date__c = null, Expected_Delivery_Date__c = today.addDays(8)),
    new Store_Order__c(Order_Number__c = 'RO-1012', Customer_Email__c = 'parker@example.com',
        Status__c = 'Cancelled', Item__c = 'Folding Camp Chair',
        Final_Sale__c = false, Delivered_Date__c = null, Expected_Delivery_Date__c = null)
};

upsert orders Store_Order__c.Order_Number__c;
System.debug('Loaded ' + orders.size() + ' sample orders, dated relative to ' + today.format() + '.');
