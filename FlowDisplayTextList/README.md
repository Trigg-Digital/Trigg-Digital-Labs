# Trigg-Digital-Labs
Trigg Digital's Labs projects where we deliver useful, re-useable and innovative developments to help your business needs


**Pass Collection in to Flow and Recieve Unordered list for screen flow**

This flow allows you as users to display a neat list of records on a screen flow. You could use this screen flow to show end-users a list of Accounts underneath another Account or owned by the user within lightning pages on Salesforce without the need to have lookup components and related record components clogging up the view to the users. Use the subflow to make it easier to display data within a screenflow. This re-usable subflow can be expanded to multiple objects so it is scalable to your needs and can be reused quickly rather than building out the same flow multiple times.

**Pre-reqs**

**Install:**
Using VSCode: Download the contents of this folder and deploy the manifest in package.xml file

Using Workbench: Download the contents of this folder and compress to a zip file

**Use:**
1. Add a subflow node to a screen flow and pass a collection variable to the flow in the input variables
2. Reference the outputDisplayText in your screen 

**Enhance:**

_To enhance the flow to handle new objects:_
1. Create a new Collection Variable of the object required and set it to allow Inputs
2. Add decisions within the "IsCollectionOf?" node and pass it the new collection variable of the object of your choice.
3. Copy the loop and it's related nodes (3 nodes)
4. Update the links to choose the Text Variable you'd like to display to the user such as Account.Name or a custom formula field that puts your text in to a joint format
5. KEEP the Constants in the assignment as this formats your HTML rendering on the screen


_To enhance the flow to have an ordered list (NUMBERED):_

1.Update the Defualt Value of OutputDisplayText and EndULMarkup Value to <OL> for numberred lists

**Contact**
Please contact us on Github or though our media channels to answer questions or find out more about Trigg Digital
