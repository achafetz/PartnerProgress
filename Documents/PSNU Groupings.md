### Create PSNU Groups


In some countries, teams may find it useful to group two or more geographically contiguous SNUs rather than keep look at the SNUs seperately.

Let's consider the country PEPFAR Land where the small district of Brownsville neighbors the country's capital, Arrow City. Due to a number of factors including access, facility size, and quality of care, many of Brownsville's residents visit facilities in Arrow City rather than the ones in their own district. The influx of patients inflates the volume at facilities in Arrow City, where we attribute the patient numbers geographically. In this instance, it makes sense for the team in PEPFAR Land to group the two SNUs.

This grouping method will rename the districts you want groups with a common identify. We will use the find and replace function in Excel to do this.

    | PSNU Name   | PSNUs Name Grouped      | Grouped |
    |-------------|-------------------------|---------|
    | Arrow City  | Arrow City area (Group) | Yes     |
    | Brownsville | Arrow City area (Group) | Yes     |
    | Cedartown   | Cedartown               | No      |
    | Deerpark    | Deerpark                | No      |

1. Before you begin, start with a list of SNUs that you would like to group together (see the table above)
2. You need to first start by unhiding the data source. Right click on any tab, select Unhide and then select the RawData tab
3. Find the that contains the PSNU names (column D) and select the whole column.
4. We will want to replace all the SNUs in the new group with the same name.
   * With the psnu column selected, hit Ctrl + H.
   * In the "Find what:" box, enter the name of one of the SNUs you want to group
   * In the "Replace with" box, enter the SNU group name. Be sure to add group or some other marker to make it clear this is not just the single SNU.
   * Repeat this process for all SNUs in that group and then for any other grouped SNUs
5.Now that you have replaced the names, you will need to update all the pivot tables in the workbook. In the ribbon at the top of Excel, navigate to Data > Connections and hit Refresh All.
6. With the names replaced and the pivot tables updated, you can now hide the raw data and then save your PPR. To hide the data tab, right click on the RawData tab and select hide.
