
function GatewaysTab(id)
{
    Tab.call(this, id, Constants.URL__GATEWAYS_VIEW_MODEL);
}

GatewaysTab.prototype = new Tab();

GatewaysTab.prototype.constructor = GatewaysTab;

GatewaysTab.prototype.initialize = function()
{
    Tab.prototype.initialize.call(this);

    this.nodesTable = Table.createTable("GatewaysNodes", this.getNodesColumns(), [[1, "asc"]], null, null, null, null);
};

GatewaysTab.prototype.getInitialSort = function()
{
    return [[0, "asc"]];
};

GatewaysTab.prototype.getColumns = function()
{
    return [
               {
                   "sTitle":  "Name",
                   "sWidth":  "100px",
                   "mRender": Format.formatStringCleansed
               },
               {
                   "sTitle":  "Index",
                   "sWidth":  "80px",
                   "sClass":  "cellRightAlign",
                   "mRender": Format.formatNumber
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
                   "sTitle":  "Description",
                   "sWidth":  "200px",
                   "mRender": Format.formatStringCleansed
               },
               {
                   "sTitle":  "CPU",
                   "sWidth":  "50px",
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
                   "sTitle":  "Nodes",
                   "sWidth":  "60px",
                   "sClass":  "cellRightAlign",
                   "mRender": Format.formatNumber
               },
               {
                   "sTitle":  "Available Capacity",
                   "sWidth":  "80px",
                   "sClass":  "cellRightAlign",
                   "mRender": Format.formatAvailableCapacity
               }
           ];
};

GatewaysTab.prototype.getNodesColumns = function()
{
    return [
               {
                   "sTitle":  "Name",
                   "sWidth":  "150px",
                   "mRender": Format.formatString
               },
               {
                   "sTitle":  "Available Capacity",
                   "sWidth":  "80px",
                   "sClass":  "cellRightAlign",
                   "mRender": Format.formatAvailableCapacity
               }
           ];
};

GatewaysTab.prototype.hideDetails = function()
{
    Tab.prototype.hideDetails.call(this);
    
    $("#GatewaysNodesTableContainer").hide();
};

GatewaysTab.prototype.clickHandler = function()
{
    this.itemClicked(2, 0);
};

GatewaysTab.prototype.showDetails = function(table, gateway, row)
{
    var data = gateway.data;
    
    this.addPropertyRow(table, "Name",                 gateway.name, true);
    this.addPropertyRow(table, "Index",                Format.formatNumber(gateway.index));
    this.addLinkRow(table,     "URI",                  gateway);
    this.addPropertyRow(table, "Supported Versions",   Format.formatString(this.getGatewaySupportedVersions(data)));
    this.addPropertyRow(table, "Description",          Format.formatString(data.config.service.description));
    this.addPropertyRow(table, "Started",              Format.formatDateString(data.start));
    this.addPropertyRow(table, "Uptime",               Format.formatUptime(data.uptime));
    this.addPropertyRow(table, "Cores",                Format.formatNumber(data.num_cores));
    this.addPropertyRow(table, "CPU",                  Format.formatNumber(data.cpu));
    this.addPropertyRow(table, "Memory",               Format.formatNumber(row[6]));
    this.addPropertyRow(table, "Available Capacity",   Format.formatNumber(row[8]));

    $("#GatewaysNodesTableContainer").show();
    
    var tableData = [];

    for (var index in data.nodes)
    {
        var node = data.nodes[index];

        var nodeRow = [];

        nodeRow.push(node.id);
        nodeRow.push(node.available_capacity);

        tableData.push(nodeRow);
    }

    this.nodesTable.fnClearTable();
    this.nodesTable.fnAddData(tableData);
};

GatewaysTab.prototype.getGatewaySupportedVersions = function(data)
{
    var result = "";

    if (data != null)
    {
        var versions = data.config.service.supported_versions;

        if (versions != null)
        {
            var versionAliases = data.config.service.version_aliases;

            if ((versionAliases != null) && (versionAliases.deprecated != null))
            {
                var index = versions.indexOf(versionAliases.deprecated);

                if (index >= 0)
                {               
                    versions.splice(index, 1);
                }
            }
            
            result = versions.toString();

            result = result.replace(",", ", ");
        }
    }

    return result;   
};
