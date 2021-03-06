
function ApplicationInstancesTab(id)
{
    Tab.call(this, id, Constants.URL__APPLICATION_INSTANCES_VIEW_MODEL);
}

ApplicationInstancesTab.prototype = new Tab();

ApplicationInstancesTab.prototype.constructor = ApplicationInstancesTab;

ApplicationInstancesTab.prototype.getInitialSort = function()
{
    return [[1, "asc"]];
};

ApplicationInstancesTab.prototype.getColumns = function()
{
    return [
               {
                   "sTitle":    "&nbsp;",
                   "sWidth":    "2px",
                   "sClass":    "cellCenterAlign",
                   "bSortable": false,
                   "mRender":   function(value, type, item)
                   {
                       return Tab.prototype.formatCheckbox(item[1], value);
                   }
               },
               {
                   "sTitle": "Name",
                   "sWidth": "150px",
                   "mRender": Format.formatApplicationName
               },
               {
                   "sTitle": "Application GUID",
                   "sWidth": "200px",
                   "mRender": Format.formatString
               },
               {
                   "sTitle":  "Index",
                   "sWidth":  "70px",
                   "sClass":  "cellRightAlign",
                   "mRender": Format.formatNumber
               },
               {
                   "sTitle": "Instance ID",
                   "sWidth": "200px",
                   "mRender": Format.formatString
               },
               {
                   "sTitle":  "State",
                   "sWidth":  "80px",
                   "mRender": Format.formatStatus
               },
               {
                   "sTitle":  "Started",
                   "sWidth":  "180px",
                   "mRender": Format.formatString
               },
               {
                   "sTitle": "URIs",
                   "sWidth": "200px",
                   "mRender": Format.formatURIs
               },
               {
                   "sTitle": "Stack",
                   "sWidth": "200px",
                   "mRender": Format.formatStackName
               },
               {
                   "sTitle":  "Memory",
                   "sWidth":  "70px",
                   "sClass":  "cellRightAlign",
                   "mRender": Format.formatNumber
               },
               {
                   "sTitle":  "Disk",
                   "sWidth":  "70px",
                   "sClass":  "cellRightAlign",
                   "mRender": Format.formatNumber
               },
               {
                   "sTitle":  "% CPU",
                   "sWidth":  "70px",
                   "sClass":  "cellRightAlign",
                   "mRender": Format.formatNumber
               },
               {
                   "sTitle":  "Memory",
                   "sWidth":  "70px",
                   "sClass":  "cellRightAlign",
                   "mRender": Format.formatNumber
               },
               {
                   "sTitle":  "Disk",
                   "sWidth":  "70px",
                   "sClass":  "cellRightAlign",
                   "mRender": Format.formatNumber
               },
               {
                   "sTitle":  "Target",
                   "sWidth":  "200px",
                   "mRender": Format.formatTarget
               },
               {
                   "sTitle": "DEA",
                   "sWidth": "150px",
                   "mRender": function(value, type)
                   {
                       if (value == null)
                       {
                           return "";
                       }
                      
                       if (Format.doFormatting(type))
                       {
                           var result = "<div>" + value;

                           if (value != null)
                           {
                               result += "<img onclick='ApplicationInstancesTab.prototype.filterApplicationInstanceTable(event, \"" + value + "\");' src='images/filter.png' style='height: 16px; width: 16px; margin-left: 5px; vertical-align: middle;'>";
                           }

                           result += "</div>";

                           return result;
                       }
                       else
                       {
                           return value;
                       }
                   }
               }
           ];
};

ApplicationInstancesTab.prototype.getActions = function()
{
    return [
               {
                   text: "Restart",
                   click: $.proxy(function()
                   {
                       this.deleteChecked("Are you sure you want to restart the selected application instances?",
                                          "Restart",
                                          "Restarting Application Instances",
                                          Constants.URL__APPLICATIONS,
                                          "");
                   }, 
                   this)
               }
           ];
};

ApplicationInstancesTab.prototype.clickHandler = function()
{
    this.itemClicked(-1, 2, 4);
};

ApplicationInstancesTab.prototype.showDetails = function(table, objects, row)
{
    var application_instance = objects.application_instance;
    var organization         = objects.organization;
    var space                = objects.space;
    var stack                = objects.stack;

    this.addJSONDetailsLinkRow(table, "Name", Format.formatString(application_instance.application_name), objects, true);
    this.addFilterRow(table, "Application GUID", Format.formatString(application_instance.application_id), application_instance.application_id, AdminUI.showApplications);
    this.addPropertyRow(table, "Index", Format.formatNumber(application_instance.instance_index));
    this.addPropertyRow(table, "Instance ID", Format.formatString(application_instance.instance_id));
    this.addPropertyRow(table, "State", Format.formatString(application_instance.state));

    this.addRowIfValue(this.addPropertyRow, table, "Started", Format.formatDateNumber, row[6]);

    var appURIs = row[7];
    if (appURIs != null)
    {
        for (var appURIIndex = 0; appURIIndex < appURIs.length; appURIIndex++)
        {
            this.addURIRow(table, "URI", "http://" + appURIs[appURIIndex]);
        }
    }

    if (stack != null)
    {
        this.addFilterRow(table, "Stack", Format.formatStringCleansed(stack.name), stack.guid, AdminUI.showStacks);
    }

    this.addRowIfValue(this.addPropertyRow, table, "Droplet Hash", Format.formatString, application_instance.droplet_sha1);
    this.addRowIfValue(this.addPropertyRow, table, "Memory Used", Format.formatNumber, row[9]);
    this.addRowIfValue(this.addPropertyRow, table, "Disk Used",   Format.formatNumber, row[10]);
    this.addRowIfValue(this.addPropertyRow, table, "CPU Used",    Format.formatNumber, row[11]);
    this.addPropertyRow(table, "Memory Reserved",  Format.formatNumber(row[12]));
    this.addPropertyRow(table, "Disk Reserved",    Format.formatNumber(row[13]));

    if (space != null)
    {
        this.addFilterRow(table, "Space", Format.formatStringCleansed(space.name), space.guid, AdminUI.showSpaces);
    }

    if (organization != null)
    {
        this.addFilterRow(table, "Organization", Format.formatStringCleansed(organization.name), organization.guid, AdminUI.showOrganizations);
    }

    if (row[15] != null)
    {
        this.addFilterRow(table, "DEA", Format.formatStringCleansed(row[15]), row[15], AdminUI.showDEAs);
    }
};

ApplicationInstancesTab.prototype.filterApplicationInstanceTable = function(event, value)
{
    var tableTools = TableTools.fnGetInstance("ApplicationInstancesTable");

    tableTools.fnSelectNone();

    $("#ApplicationInstancesTable").dataTable().fnFilter(value);

    event.stopPropagation();

    return false;
};
