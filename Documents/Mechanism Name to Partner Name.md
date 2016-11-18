### Adjust Mechanism Name to Partner Name


To align with Panorama, the PPR provides mechanism names as a default instead of the partner name. If your country team finds it easier to work with mechanism names follows the steps below to adjust your PPR accordingly.


1. You need to first start by unhiding the data source. Right click on any tab, select Unhide and then select the RawData tab
2. To “fix” this “problem”, we are going to simply replace the mechanism names with the partner names. In the Raw Data tab, find the column listed as “primepartner” (column H) and select everything in the column EXCEPT the header in row. For example, if your data table had 100 rows, you would select H2:H100.
   * Place your cursor on H2 and hit Ctrl + Shift + Down Arrow to select all the partner names
   * Copy the names by hitting Ctrl + C
   * Navigate two columns over to column J and select the J2 cell.
   * Paste the copied partner names (Ctrl + V)
3. Now that you have replaced the names, you will need to update all the pivot tables in the workbook. In the ribbon at the top of Excel, navigate to Data > Connections and hit Refresh All.
4. With the names replaced and the pivot tables updated, you can now hide the raw data and then save your PPR. To hide the data tab, right click on the RawData tab and select hide.
