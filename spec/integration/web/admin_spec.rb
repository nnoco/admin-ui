require 'rubygems'
require_relative '../../spec_helper'
require_relative '../../support/web_helper'

describe AdminUI::Admin, :type => :integration, :firefox_available => true do
  include_context :server_context
  include_context :web_context

  it 'requires valid credentials' do
    login(admin_user, 'bad_password', 'Login')
  end

  context 'authenticated' do
    before do
      login(admin_user, admin_password, 'Administration')
    end

    it 'has a title' do
      expect(@driver.find_element(:class => 'cloudControllerText').text).to eq(cloud_controller_uri)
    end

    it 'has tabs' do
      expect(@driver.find_element(:id => 'Organizations').displayed?).to    be_true
      expect(@driver.find_element(:id => 'Spaces').displayed?).to           be_true
      expect(@driver.find_element(:id => 'Applications').displayed?).to     be_true
      expect(@driver.find_element(:id => 'Developers').displayed?).to       be_true
      expect(@driver.find_element(:id => 'DEAs').displayed?).to             be_true
      expect(@driver.find_element(:id => 'CloudControllers').displayed?).to be_true
      expect(@driver.find_element(:id => 'HealthManagers').displayed?).to   be_true
      expect(@driver.find_element(:id => 'Gateways').displayed?).to         be_true
      expect(@driver.find_element(:id => 'Routers').displayed?).to          be_true
      expect(@driver.find_element(:id => 'Components').displayed?).to       be_true
      expect(@driver.find_element(:id => 'Logs').displayed?).to             be_true
      expect(@driver.find_element(:id => 'Tasks').displayed?).to            be_true
      expect(@driver.find_element(:id => 'Stats').displayed?).to            be_true
    end

    it 'has a refresh button' do
      expect(@driver.find_element(:id => 'RefreshButton').displayed?).to be_true
    end

    it 'shows the logged in user' do
      expect(@driver.find_element(:class => 'userContainer').displayed?).to be_true
      expect(@driver.find_element(:class => 'user').text).to eq(admin_user)
    end

    context 'tabs' do
      before do
        @driver.find_element(:id => tab_id).click
        expect(@driver.find_element(:class_name => 'menuItemSelected').attribute('id')).to eq(tab_id)
        expect(@driver.find_element(:id => "#{ tab_id }Page").displayed?).to be_true
      end

      context 'Organizations' do
        let(:tab_id) { 'Organizations' }
        it 'has a table' do
          check_table_layout([
                               {
                                 :columns         => @driver.find_elements(:xpath => "//div[@id='OrganizationsTableContainer']/div/div[5]/div[1]/div/table/thead/tr[1]/th"),
                                 :expected_length => 5,
                                 :labels          => ['', 'App States', 'App Package States', 'Reserved', 'Used'],
                                 :colspans        => %w(5 3 3 2 3)
                               },
                               {
                                 :columns         => @driver.find_elements(:xpath => "//div[@id='OrganizationsTableContainer']/div/div[5]/div[1]/div/table/thead/tr[2]/th"),
                                 :expected_length => 16,
                                 :labels          => ['Name', 'Status', 'Created', 'Spaces', 'Developers', 'Total', 'Started', 'Stopped', 'Pending', 'Staged', 'Failed', 'Memory', 'Disk', 'Memory', 'Disk', '% CPU'],
                                 :colspans        => nil
                               }
                             ])
          check_table_data(@driver.find_elements(:xpath => "//table[@id='OrganizationsTable']/tbody/tr/td"),
                           [
                             cc_organizations['resources'][0]['entity']['name'],
                             cc_organizations['resources'][0]['entity']['status'].upcase,
                             @driver.execute_script("return Format.formatDateString(\"#{ cc_organizations['resources'][0]['metadata']['created_at'] }\")"),
                             cc_spaces['resources'].length.to_s,
                             cc_users_deep['resources'].length.to_s,
                             cc_apps['resources'].length.to_s,
                             cc_apps['resources'][0]['entity']['state'] == 'STARTED' ? '1' : '0',
                             cc_apps['resources'][0]['entity']['state'] == 'STOPPED' ? '1' : '0',
                             cc_apps['resources'][0]['entity']['package_state'] == 'PENDING' ? '1' : '0',
                             cc_apps['resources'][0]['entity']['package_state'] == 'STAGED'  ? '1' : '0',
                             cc_apps['resources'][0]['entity']['package_state'] == 'FAILED'  ? '1' : '0',
                             cc_apps['resources'][0]['entity']['memory'].to_s,
                             cc_apps['resources'][0]['entity']['disk_quota'].to_s,
                             @driver.execute_script("return Utilities.convertBytesToMega(#{ varz_dea['instance_registry']['application1']['application1_instance1']['used_memory_in_bytes'] })").to_s,
                             @driver.execute_script("return Utilities.convertBytesToMega(#{ varz_dea['instance_registry']['application1']['application1_instance1']['used_disk_in_bytes'] })").to_s,
                             @driver.execute_script("return Format.formatNumber(#{ varz_dea['instance_registry']['application1']['application1_instance1']['computed_pcpu'] * 100 })").to_s
                           ])
        end
        context 'selectable' do
          before do
            select_first_row
          end
          it 'has details' do
            check_details([
                            { :label => 'Name',            :tag => 'div', :value => cc_organizations['resources'][0]['entity']['name'] },
                            { :label => 'Status',          :tag =>   nil, :value => cc_organizations['resources'][0]['entity']['status'].upcase },
                            { :label => 'Created',         :tag =>   nil, :value => @driver.execute_script("return Format.formatDateString(\"#{ cc_organizations['resources'][0]['metadata']['created_at'] }\")") },
                            { :label => 'Billing Enabled', :tag =>   nil, :value => cc_organizations['resources'][0]['entity']['billing_enabled'].to_s },
                            { :label => 'Spaces',          :tag =>   'a', :value => cc_spaces['resources'].length.to_s },
                            { :label => 'Developers',      :tag =>   'a', :value => cc_users_deep['resources'].length.to_s },
                            { :label => 'Total Apps',      :tag =>   'a', :value => cc_apps['resources'].length.to_s },
                            { :label => 'Started Apps',    :tag =>   nil, :value => cc_apps['resources'][0]['entity']['state'] == 'STARTED' ? '1' : '0' },
                            { :label => 'Stopped Apps',    :tag =>   nil, :value => cc_apps['resources'][0]['entity']['state'] == 'STOPPED' ? '1' : '0' },
                            { :label => 'Pending Apps',    :tag =>   nil, :value => cc_apps['resources'][0]['entity']['package_state'] == 'PENDING' ? '1' : '0' },
                            { :label => 'Staged Apps',     :tag =>   nil, :value => cc_apps['resources'][0]['entity']['package_state'] == 'STAGED'  ? '1' : '0' },
                            { :label => 'Failed Apps',     :tag =>   nil, :value => cc_apps['resources'][0]['entity']['package_state'] == 'FAILED'  ? '1' : '0' },
                            { :label => 'Memory Reserved', :tag =>   nil, :value => cc_apps['resources'][0]['entity']['memory'].to_s },
                            { :label => 'Disk Reserved',   :tag =>   nil, :value => cc_apps['resources'][0]['entity']['disk_quota'].to_s },
                            { :label => 'Memory Used',     :tag =>   nil, :value => @driver.execute_script("return Utilities.convertBytesToMega(#{ varz_dea['instance_registry']['application1']['application1_instance1']['used_memory_in_bytes'] })").to_s },
                            { :label => 'Disk Used',       :tag =>   nil, :value => @driver.execute_script("return Utilities.convertBytesToMega(#{ varz_dea['instance_registry']['application1']['application1_instance1']['used_disk_in_bytes'] })").to_s },
                            { :label => 'CPU Used',        :tag =>   nil, :value => @driver.execute_script("return Format.formatNumber(#{ varz_dea['instance_registry']['application1']['application1_instance1']['computed_pcpu'] * 100 })").to_s }
                          ])
          end
          it 'has spaces link' do
            check_filter_link('Organizations', 4, 'Spaces', "#{ cc_organizations['resources'][0]['entity']['name'] }/")
          end
          it 'has developers link' do
            check_filter_link('Organizations', 5, 'Developers', "#{ cc_organizations['resources'][0]['entity']['name'] }/")
          end
          it 'has applications link' do
            check_filter_link('Organizations', 6, 'Applications', "#{ cc_organizations['resources'][0]['entity']['name'] }/")
          end
        end
      end

      context 'Spaces' do
        let(:tab_id) { 'Spaces' }
        it 'has a table' do
          check_table_layout([
                               {
                                 :columns         => @driver.find_elements(:xpath => "//div[@id='SpacesTableContainer']/div/div[5]/div[1]/div/table/thead/tr[1]/th"),
                                 :expected_length => 5,
                                 :labels          => ['', 'App States', 'App Package States', 'Reserved', 'Used'],
                                 :colspans        => %w(4 3 3 2 3)
                               },
                               {
                                 :columns         => @driver.find_elements(:xpath => "//div[@id='SpacesTableContainer']/div/div[5]/div[1]/div/table/thead/tr[2]/th"),
                                 :expected_length => 15,
                                 :labels          => ['Name', 'Target', 'Created', 'Developers', 'Total', 'Started', 'Stopped', 'Pending', 'Staged', 'Failed', 'Memory', 'Disk', 'Memory', 'Disk', '% CPU'],
                                 :colspans        => nil
                               }
                             ])
          check_table_data(@driver.find_elements(:xpath => "//table[@id='SpacesTable']/tbody/tr/td"),
                           [
                             cc_spaces['resources'][0]['entity']['name'],
                             "#{ cc_organizations['resources'][0]['entity']['name'] }/#{ cc_spaces['resources'][0]['entity']['name'] }",
                             @driver.execute_script("return Format.formatDateString(\"#{ cc_spaces['resources'][0]['metadata']['created_at'] }\")"),
                             cc_users_deep['resources'].length.to_s,
                             cc_apps['resources'].length.to_s,
                             cc_apps['resources'][0]['entity']['state'] == 'STARTED' ? '1' : '0',
                             cc_apps['resources'][0]['entity']['state'] == 'STOPPED' ? '1' : '0',
                             cc_apps['resources'][0]['entity']['package_state'] == 'PENDING' ? '1' : '0',
                             cc_apps['resources'][0]['entity']['package_state'] == 'STAGED'  ? '1' : '0',
                             cc_apps['resources'][0]['entity']['package_state'] == 'FAILED'  ? '1' : '0',
                             cc_apps['resources'][0]['entity']['memory'].to_s,
                             cc_apps['resources'][0]['entity']['disk_quota'].to_s,
                             @driver.execute_script("return Utilities.convertBytesToMega(#{ varz_dea['instance_registry']['application1']['application1_instance1']['used_memory_in_bytes'] })").to_s,
                             @driver.execute_script("return Utilities.convertBytesToMega(#{ varz_dea['instance_registry']['application1']['application1_instance1']['used_disk_in_bytes'] })").to_s,
                             @driver.execute_script("return Format.formatNumber(#{ varz_dea['instance_registry']['application1']['application1_instance1']['computed_pcpu'] * 100 })").to_s
                           ])
        end
        context 'selectable' do
          before do
            select_first_row
          end
          it 'has details' do
            check_details([
                            { :label => 'Name',         :tag => 'div', :value => cc_spaces['resources'][0]['entity']['name'] },
                            { :label => 'Organization', :tag =>   'a', :value => cc_organizations['resources'][0]['entity']['name'] },
                            { :label => 'Created',      :tag =>   nil, :value => @driver.execute_script("return Format.formatDateString(\"#{ cc_spaces['resources'][0]['metadata']['created_at'] }\")") },
                            { :label => 'Developers',   :tag =>   'a', :value => cc_users_deep['resources'].length.to_s },
                            { :label => 'Total Apps',   :tag =>   'a', :value => cc_apps['resources'].length.to_s },
                            { :label => 'Started Apps', :tag =>   nil, :value => cc_apps['resources'][0]['entity']['state'] == 'STARTED' ? '1' : '0' },
                            { :label => 'Stopped Apps', :tag =>   nil, :value => cc_apps['resources'][0]['entity']['state'] == 'STOPPED' ? '1' : '0' },
                            { :label => 'Pending Apps', :tag =>   nil, :value => cc_apps['resources'][0]['entity']['package_state'] == 'PENDING' ? '1' : '0' },
                            { :label => 'Staged Apps',  :tag =>   nil, :value => cc_apps['resources'][0]['entity']['package_state'] == 'STAGED'  ? '1' : '0' },
                            { :label => 'Failed Apps',  :tag =>   nil, :value => cc_apps['resources'][0]['entity']['package_state'] == 'FAILED'  ? '1' : '0' },
                            { :label => 'Memory Reserved', :tag =>   nil, :value => cc_apps['resources'][0]['entity']['memory'].to_s },
                            { :label => 'Disk Reserved',   :tag =>   nil, :value => cc_apps['resources'][0]['entity']['disk_quota'].to_s },
                            { :label => 'Memory Used',     :tag =>   nil, :value => @driver.execute_script("return Utilities.convertBytesToMega(#{ varz_dea['instance_registry']['application1']['application1_instance1']['used_memory_in_bytes'] })").to_s },
                            { :label => 'Disk Used',       :tag =>   nil, :value => @driver.execute_script("return Utilities.convertBytesToMega(#{ varz_dea['instance_registry']['application1']['application1_instance1']['used_disk_in_bytes'] })").to_s },
                            { :label => 'CPU Used',        :tag =>   nil, :value => @driver.execute_script("return Format.formatNumber(#{ varz_dea['instance_registry']['application1']['application1_instance1']['computed_pcpu'] * 100 })").to_s }
                          ])
          end
          it 'has organization link' do
            check_select_link('Spaces', 1, 'Organizations', cc_organizations['resources'][0]['entity']['name'])
          end
          it 'has developers link' do
            check_filter_link('Spaces', 3, 'Developers', "#{ cc_organizations['resources'][0]['entity']['name'] }/#{ cc_spaces['resources'][0]['entity']['name'] }")
          end
          it 'has applications link' do
            check_filter_link('Spaces', 4, 'Applications', "#{ cc_organizations['resources'][0]['entity']['name'] }/#{ cc_spaces['resources'][0]['entity']['name'] }")
          end
        end
      end

      context 'Applications' do
        let(:tab_id) { 'Applications' }
        it 'has a table' do
          check_table_layout([
                               {
                                 :columns         => @driver.find_elements(:xpath => "//div[@id='ApplicationsTableContainer']/div/div[5]/div[1]/div/table/thead/tr[1]/th"),
                                 :expected_length => 4,
                                 :labels          => ['', 'Reserved', 'Used', ''],
                                 :colspans        => %w(8 2 3 2)
                               },
                               {
                                 :columns         => @driver.find_elements(:xpath => "//div[@id='ApplicationsTableContainer']/div/div[5]/div[1]/div/table/thead/tr[2]/th"),
                                 :expected_length => 15,
                                 :labels          => ['Name', 'State', "Package\nState", 'Started', 'URI', 'Buildpack', 'Instance', 'Services', 'Memory', 'Disk', 'Memory', 'Disk', '% CPU', 'Target', 'DEA'],
                                 :colspans        => nil
                               }
                             ])
          check_table_data(@driver.find_elements(:xpath => "//table[@id='ApplicationsTable']/tbody/tr/td"),
                           [
                             cc_apps['resources'][0]['entity']['name'],
                             cc_apps['resources'][0]['entity']['state'],
                             @driver.execute_script('return Constants.STATUS__STAGED'),
                             @driver.execute_script("return Format.formatDateNumber(#{ (varz_dea['instance_registry']['application1']['application1_instance1']['state_running_timestamp'] * 1000) })"),
                             "http://#{ varz_dea['instance_registry']['application1']['application1_instance1']['application_uris'][0] }",
                             cc_apps['resources'][0]['entity']['detected_buildpack'],
                             varz_dea['instance_registry']['application1']['application1_instance1']['instance_index'].to_s,
                             varz_dea['instance_registry']['application1']['application1_instance1']['services'].length.to_s,
                             cc_apps['resources'][0]['entity']['memory'].to_s,
                             cc_apps['resources'][0]['entity']['disk_quota'].to_s,
                             @driver.execute_script("return Utilities.convertBytesToMega(#{ varz_dea['instance_registry']['application1']['application1_instance1']['used_memory_in_bytes'] })").to_s,
                             @driver.execute_script("return Utilities.convertBytesToMega(#{ varz_dea['instance_registry']['application1']['application1_instance1']['used_disk_in_bytes'] })").to_s,
                             @driver.execute_script("return Format.formatNumber(#{ varz_dea['instance_registry']['application1']['application1_instance1']['computed_pcpu'] * 100 })").to_s,
                             "#{ cc_organizations['resources'][0]['entity']['name'] }/#{ cc_spaces['resources'][0]['entity']['name'] }",
                             nats_dea['host']
                           ])
        end
        context 'selectable' do
          before do
            select_first_row
          end
          it 'has details' do
            check_details([
                            { :label => 'Name',            :tag => 'div', :value => cc_apps['resources'][0]['entity']['name'] },
                            { :label => 'State',           :tag =>   nil, :value => cc_apps['resources'][0]['entity']['state'] },
                            { :label => 'Package State',   :tag =>   nil, :value => cc_apps['resources'][0]['entity']['package_state'] },
                            { :label => 'Started',         :tag =>   nil, :value => @driver.execute_script("return Format.formatDateNumber(#{ (varz_dea['instance_registry']['application1']['application1_instance1']['state_running_timestamp'] * 1000) })") },
                            { :label => 'URI',             :tag =>   'a', :value => "http://#{ varz_dea['instance_registry']['application1']['application1_instance1']['application_uris'][0] }" },
                            { :label => 'Buildpack',       :tag =>   nil, :value => cc_apps['resources'][0]['entity']['detected_buildpack'] },
                            { :label => 'Instance Index',  :tag =>   nil, :value => varz_dea['instance_registry']['application1']['application1_instance1']['instance_index'].to_s },
                            { :label => 'Instance State',  :tag =>   nil, :value => varz_dea['instance_registry']['application1']['application1_instance1']['state'] },
                            { :label => 'Services',        :tag =>   nil, :value => varz_dea['instance_registry']['application1']['application1_instance1']['services'].length.to_s },
                            { :label => 'Droplet Hash',    :tag =>   nil, :value => varz_dea['instance_registry']['application1']['application1_instance1']['droplet_sha1'].to_s },
                            { :label => 'Memory Reserved', :tag =>   nil, :value => cc_apps['resources'][0]['entity']['memory'].to_s },
                            { :label => 'Disk Reserved',   :tag =>   nil, :value => cc_apps['resources'][0]['entity']['disk_quota'].to_s },
                            { :label => 'Memory Used',     :tag =>   nil, :value => @driver.execute_script("return Utilities.convertBytesToMega(#{ varz_dea['instance_registry']['application1']['application1_instance1']['used_memory_in_bytes'] })").to_s },
                            { :label => 'Disk Used',       :tag =>   nil, :value => @driver.execute_script("return Utilities.convertBytesToMega(#{ varz_dea['instance_registry']['application1']['application1_instance1']['used_disk_in_bytes'] })").to_s },
                            { :label => 'CPU Used',        :tag =>   nil, :value => @driver.execute_script("return Format.formatNumber(#{ varz_dea['instance_registry']['application1']['application1_instance1']['computed_pcpu'] * 100 })").to_s },
                            { :label => 'Space',           :tag =>   'a', :value => cc_spaces['resources'][0]['entity']['name'] },
                            { :label => 'Organization',    :tag =>   'a', :value => cc_organizations['resources'][0]['entity']['name'] },
                            { :label => 'DEA',             :tag =>   'a', :value => nats_dea['host'] }
                          ])
          end
          it 'has services' do
            expect(@driver.find_element(:id => 'ApplicationsServicesDetailsLabel').displayed?).to be_true
            check_table_headers(:columns         => @driver.find_elements(:xpath => "//div[@id='ApplicationsServicesTableContainer']/div[2]/div[5]/div[1]/div/table/thead/tr/th"),
                                :expected_length => 5,
                                :labels          => ['Instance Name', 'Provider', 'Service Name', 'Version', 'Plan Name'],
                                :colspans        => nil)
            check_table_data(@driver.find_elements(:xpath => "//table[@id='ApplicationsServicesTable']/tbody/tr/td"),
                             [
                               varz_dea['instance_registry']['application1']['application1_instance1']['services'][0]['name'],
                               varz_dea['instance_registry']['application1']['application1_instance1']['services'][0]['provider'],
                               varz_dea['instance_registry']['application1']['application1_instance1']['services'][0]['vendor'],
                               varz_dea['instance_registry']['application1']['application1_instance1']['services'][0]['version'],
                               varz_dea['instance_registry']['application1']['application1_instance1']['services'][0]['plan'],
                             ])
          end
          it 'has space link' do
            check_select_link('Applications', 15, 'Spaces', cc_spaces['resources'][0]['entity']['name'])
          end
          it 'has organization link' do
            check_select_link('Applications', 16, 'Organizations', cc_organizations['resources'][0]['entity']['name'])
          end
          it 'has DEA link' do
            check_select_link('Applications', 17, 'DEAs', nats_dea['host'])
          end
        end
      end

      context 'Developers' do
        let(:tab_id) { 'Developers' }
        it 'has a table' do
          check_table_layout([
                               {
                                 :columns         => @driver.find_elements(:xpath => "//div[@id='DevelopersTableContainer']/div/div[5]/div[1]/div/table/thead/tr/th"),
                                 :expected_length => 5,
                                 :labels          => %w(Email Space Organization Target Created),
                                 :colspans        => nil
                               }
                             ])
          check_table_data(@driver.find_elements(:xpath => "//table[@id='DevelopersTable']/tbody/tr/td"),
                           [
                             "#{ uaa_users['resources'][0]['emails'][0]['value'] }",
                             cc_spaces['resources'][0]['entity']['name'],
                             cc_organizations['resources'][0]['entity']['name'],
                             "#{ cc_organizations['resources'][0]['entity']['name'] }/#{ cc_spaces['resources'][0]['entity']['name'] }",
                             @driver.execute_script("return Format.formatDateString(\"#{ uaa_users['resources'][0]['meta']['created'] }\")"),
                           ])
        end
        context 'selectable' do
          before do
            select_first_row
          end
          it 'has details' do
            groups = []
            uaa_users['resources'][0]['groups'].each do |group|
              groups.push(group['display'])
            end
            groups.sort!
            index = 0
            groups_string = ''
            while index < groups.length
              groups_string += ', ' unless index == 0
              groups_string += groups[index]
              index += 1
            end
            check_details([
                            { :label => 'Email',        :tag => 'div', :value => "mailto:#{ uaa_users['resources'][0]['emails'][0]['value'] }" },
                            { :label => 'Created',      :tag =>   nil, :value => @driver.execute_script("return Format.formatDateString(\"#{ uaa_users['resources'][0]['meta']['created'] }\")") },
                            { :label => 'Modified',     :tag =>   nil, :value => @driver.execute_script("return Format.formatDateString(\"#{ uaa_users['resources'][0]['meta']['lastModified'] }\")") },
                            { :label => 'Authorities',  :tag =>   nil, :value => groups_string },
                            { :label => 'Space',        :tag =>   'a', :value => cc_spaces['resources'][0]['entity']['name'] },
                            { :label => 'Organization', :tag =>   'a', :value => cc_organizations['resources'][0]['entity']['name'] }
                          ])
          end
          it 'has space link' do
            check_select_link('Developers', 4, 'Spaces', cc_spaces['resources'][0]['entity']['name'])
          end
          it 'has organization link' do
            check_select_link('Developers', 5, 'Organizations', cc_organizations['resources'][0]['entity']['name'])
          end
        end
      end

      context 'DEAs' do
        let(:tab_id) { 'DEAs' }
        it 'has a table' do
          check_table_layout([
                               {
                                 :columns         => @driver.find_elements(:xpath => "//div[@id='DEAsTableContainer']/div/div[5]/div[1]/div/table/thead/tr[1]/th"),
                                 :expected_length => 2,
                                 :labels          => ['', '% Free'],
                                 :colspans        => %w(6 2)
                               },
                               {
                                 :columns         => @driver.find_elements(:xpath => "//div[@id='DEAsTableContainer']/div/div[5]/div[1]/div/table/thead/tr[2]/th"),
                                 :expected_length => 8,
                                 :labels          => %w(Name Status Started CPU Memory Apps Memory Disk),
                                 :colspans        => nil
                               }
                             ])
          check_table_data(@driver.find_elements(:xpath => "//table[@id='DEAsTable']/tbody/tr/td"),
                           [
                             varz_dea['host'],
                             @driver.execute_script('return Constants.STATUS__RUNNING'),
                             @driver.execute_script("return Format.formatDateString(\"#{ varz_dea['start'] }\")"),
                             varz_dea['cpu'].to_s,
                             varz_dea['mem'].to_s,
                             varz_dea['instance_registry'].length.to_s,
                             @driver.execute_script("return Format.formatNumber(#{ varz_dea['available_memory_ratio'].to_f * 100 })"),
                             @driver.execute_script("return Format.formatNumber(#{ varz_dea['available_disk_ratio'].to_f * 100 })")
                           ])
        end
        it 'has a create DEA button' do
          expect(@driver.find_element(:id => 'DEAsCreateButton').displayed?).to be_true
        end
        context 'selectable' do
          before do
            select_first_row
          end
          it 'has details' do
            check_details([
                            { :label => 'Name',         :tag => nil, :value => varz_dea['host'] },
                            { :label => 'URI',          :tag => 'a', :value => nats_dea_varz },
                            { :label => 'Host',         :tag => nil, :value => varz_dea['host'] },
                            { :label => 'Started',      :tag => nil, :value => @driver.execute_script("return Format.formatDateString(\"#{ varz_dea['start'] }\")") },
                            { :label => 'Uptime',       :tag => nil, :value => @driver.execute_script("return Format.formatUptime(\"#{ varz_dea['uptime'] }\")") },
                            { :label => 'Apps',         :tag => 'a', :value => varz_dea['instance_registry'].length.to_s },
                            { :label => 'Cores',        :tag => nil, :value => varz_dea['num_cores'].to_s },
                            { :label => 'CPU',          :tag => nil, :value => varz_dea['cpu'].to_s },
                            { :label => 'CPU Load Avg', :tag => nil, :value => "#{ @driver.execute_script("return Format.formatNumber(#{ varz_dea['cpu_load_avg'].to_f * 100 })") }%" },
                            { :label => 'Memory',       :tag => nil, :value => varz_dea['mem'].to_s },
                            { :label => 'Memory Free',  :tag => nil, :value => "#{ @driver.execute_script("return Format.formatNumber(#{ varz_dea['available_memory_ratio'].to_f * 100 })") }%" },
                            { :label => 'Disk Free',    :tag => nil, :value => "#{ @driver.execute_script("return Format.formatNumber(#{ varz_dea['available_disk_ratio'].to_f * 100 })") }%" }
                          ])
          end
          it 'has applications link' do
            check_filter_link('DEAs', 5, 'Applications', varz_dea['host'])
          end
        end
      end

      context 'Cloud Controllers' do
        let(:tab_id) { 'CloudControllers' }
        it 'has a table' do
          check_table_layout([
                               {
                                 :columns         => @driver.find_elements(:xpath => "//div[@id='CloudControllersTableContainer']/div/div[5]/div[1]/div/table/thead/tr/th"),
                                 :expected_length => 6,
                                 :labels          => %w(Name State Started Cores CPU Memory),
                                 :colspans        => nil
                               }
                             ])
          check_table_data(@driver.find_elements(:xpath => "//table[@id='CloudControllersTable']/tbody/tr/td"),
                           [
                             nats_cloud_controller['host'],
                             @driver.execute_script('return Constants.STATUS__RUNNING'),
                             @driver.execute_script("return Format.formatDateString(\"#{ varz_cloud_controller['start'] }\")"),
                             varz_cloud_controller['num_cores'].to_s,
                             varz_cloud_controller['cpu'].to_s,
                             varz_cloud_controller['mem'].to_s
                           ])
        end
        context 'selectable' do
          it 'has details' do
            select_first_row
            check_details([
                            { :label => 'Name',             :tag => nil, :value => nats_cloud_controller['host'] },
                            { :label => 'URI',              :tag => 'a', :value => nats_cloud_controller_varz },
                            { :label => 'Started',          :tag => nil, :value => @driver.execute_script("return Format.formatDateString(\"#{ varz_cloud_controller['start'] }\")") },
                            { :label => 'Uptime',           :tag => nil, :value => @driver.execute_script("return Format.formatUptime(\"#{ varz_cloud_controller['uptime'] }\")") },
                            { :label => 'Cores',            :tag => nil, :value => varz_cloud_controller['num_cores'].to_s },
                            { :label => 'CPU',              :tag => nil, :value => varz_cloud_controller['cpu'].to_s },
                            { :label => 'Memory',           :tag => nil, :value => varz_cloud_controller['mem'].to_s },
                            { :label => 'Requests',         :tag => nil, :value => varz_cloud_controller['vcap_sinatra']['requests']['completed'].to_s },
                            { :label => 'Pending Requests', :tag => nil, :value => varz_cloud_controller['vcap_sinatra']['requests']['outstanding'].to_s }
                          ])
          end
        end
      end

      context 'Health Managers' do
        let(:tab_id) { 'HealthManagers' }
        it 'has a table' do
          check_table_layout([
                               {
                                 :columns         => @driver.find_elements(:xpath => "//div[@id='HealthManagersTableContainer']/div/div[5]/div[1]/div/table/thead/tr/th"),
                                 :expected_length => 9,
                                 :labels          => %w(Name State Started Cores CPU Memory Users Applications Instances),
                                 :colspans        => nil
                               }
                             ])
          check_table_data(@driver.find_elements(:xpath => "//table[@id='HealthManagersTable']/tbody/tr/td"),
                           [
                             nats_health_manager['host'],
                             @driver.execute_script('return Constants.STATUS__RUNNING'),
                             @driver.execute_script("return Format.formatDateString(\"#{ varz_health_manager['start'] }\")"),
                             varz_health_manager['num_cores'].to_s,
                             varz_health_manager['cpu'].to_s,
                             varz_health_manager['mem'].to_s,
                             varz_health_manager['total_users'].to_s,
                             varz_health_manager['total_apps'].to_s,
                             varz_health_manager['total_instances'].to_s
                           ])
        end
        context 'selectable' do
          it 'has details' do
            select_first_row
            check_details([
                            { :label => 'Name',              :tag => nil, :value => nats_health_manager['host'] },
                            { :label => 'URI',               :tag => 'a', :value => nats_health_manager_varz },
                            { :label => 'Started',           :tag => nil, :value => @driver.execute_script("return Format.formatDateString(\"#{ varz_health_manager['start'] }\")") },
                            { :label => 'Uptime',            :tag => nil, :value => @driver.execute_script("return Format.formatUptime(\"#{ varz_health_manager['uptime'] }\")") },
                            { :label => 'Cores',             :tag => nil, :value => varz_health_manager['num_cores'].to_s },
                            { :label => 'CPU',               :tag => nil, :value => varz_health_manager['cpu'].to_s },
                            { :label => 'Memory',            :tag => nil, :value => varz_health_manager['mem'].to_s },
                            { :label => 'Users',             :tag => nil, :value => varz_health_manager['total_users'].to_s },
                            { :label => 'Applications',      :tag => nil, :value => varz_health_manager['total_apps'].to_s },
                            { :label => 'Instances',         :tag => nil, :value => varz_health_manager['total_instances'].to_s },
                            { :label => 'Running Instances', :tag => nil, :value => varz_health_manager['running_instances'].to_s },
                            { :label => 'Crashed Instances', :tag => nil, :value => varz_health_manager['crashed_instances'].to_s }
                          ])
          end
        end
      end

      context 'Service Gateways' do
        let(:tab_id) { 'Gateways' }
        before do
          @capacity = 0
          varz_provisioner['nodes'].each do |node|
            unless node[1]['available_capacity'].nil?
              @capacity += node[1]['available_capacity']
            end
          end
        end
        it 'has a table' do
          check_table_layout([
                               {
                                 :columns         => @driver.find_elements(:xpath => "//div[@id='GatewaysTableContainer']/div/div[5]/div[1]/div/table/thead/tr/th"),
                                 :expected_length => 8,
                                 :labels          => ['Name', 'State', 'Started', 'Description', 'CPU', 'Memory', 'Nodes', "Available\nCapacity"],
                                 :colspans        => nil
                               }
                             ])
          check_table_data(@driver.find_elements(:xpath => "//table[@id='GatewaysTable']/tbody/tr/td"),
                           [
                             nats_provisioner['type'][0..-13],
                             @driver.execute_script('return Constants.STATUS__RUNNING'),
                             @driver.execute_script("return Format.formatDateString(\"#{ varz_provisioner['start'] }\")"),
                             varz_provisioner['config']['service']['description'],
                             varz_provisioner['cpu'].to_s,
                             varz_provisioner['mem'].to_s,
                             varz_provisioner['nodes'].length.to_s,
                             @capacity.to_s
                           ])
        end
        context 'selectable' do
          before do
            select_first_row
          end
          it 'has details' do
            check_details([
                            { :label => 'Name',                 :tag => nil, :value => nats_provisioner['type'][0..-13] },
                            { :label => 'URI',                  :tag => nil, :value => nats_provisioner_varz },
                            { :label => 'Supported Versions',   :tag => nil, :value => varz_provisioner['config']['service']['supported_versions'][0] },
                            { :label => 'Description',          :tag => nil, :value => varz_provisioner['config']['service']['description'] },
                            { :label => 'Started',              :tag => nil, :value => @driver.execute_script("return Format.formatDateString(\"#{ varz_provisioner['start'] }\")") },
                            { :label => 'Uptime',               :tag => nil, :value => @driver.execute_script("return Format.formatUptime(\"#{ varz_provisioner['uptime'] }\")") },
                            { :label => 'Cores',                :tag => nil, :value => varz_provisioner['num_cores'].to_s },
                            { :label => 'CPU',                  :tag => nil, :value => varz_provisioner['cpu'].to_s },
                            { :label => 'Memory',               :tag => nil, :value => varz_provisioner['mem'].to_s },
                            { :label => 'Available Capacity',   :tag => nil, :value => "#{ @capacity}" }
                          ])
          end
          it 'has nodes' do
            expect(@driver.find_element(:id => 'GatewaysNodesDetailsLabel').displayed?).to be_true
            check_table_headers(:columns         => @driver.find_elements(:xpath => "//div[@id='GatewaysNodesTableContainer']/div[2]/div[5]/div[1]/div/table/thead/tr/th"),
                                :expected_length => 2,
                                :labels          => ['Name', 'Available Capacity'],
                                :colspans        => nil)
            check_table_data(@driver.find_elements(:xpath => "//table[@id='GatewaysNodesTable']/tbody/tr/td"),
                             [
                               varz_provisioner['nodes'].keys[0],
                               varz_provisioner['nodes'][varz_provisioner['nodes'].keys[0]]['available_capacity'].to_s,
                             ])
          end
        end
      end

      context 'Routers' do
        let(:tab_id) { 'Routers' }
        it 'has a table' do
          check_table_layout([
                               {
                                 :columns         => @driver.find_elements(:xpath => "//div[@id='RoutersTableContainer']/div/div[5]/div[1]/div/table/thead/tr/th"),
                                 :expected_length => 9,
                                 :labels          => ['Name', 'State', 'Started', 'Cores', 'CPU', 'Memory', 'Droplets', 'Requests', 'Bad Requests'],
                                 :colspans        => nil
                               }
                             ])
          check_table_data(@driver.find_elements(:xpath => "//table[@id='RoutersTable']/tbody/tr/td"),
                           [
                             nats_router['host'],
                             @driver.execute_script('return Constants.STATUS__RUNNING'),
                             @driver.execute_script("return Format.formatDateString(\"#{ varz_router['start'] }\")"),
                             varz_router['num_cores'].to_s,
                             varz_router['cpu'].to_s,
                             varz_router['mem'].to_s,
                             varz_router['droplets'].to_s,
                             varz_router['requests'].to_s,
                             varz_router['bad_requests'].to_s
                           ])
        end
        context 'selectable' do
          it 'has details' do
            select_first_row
            check_details([
                            { :label => 'Name',          :tag => nil, :value => nats_router['host'] },
                            { :label => 'URI',           :tag => 'a', :value => nats_router_varz },
                            { :label => 'Started',       :tag => nil, :value => @driver.execute_script("return Format.formatDateString(\"#{ varz_router['start'] }\")") },
                            { :label => 'Uptime',        :tag => nil, :value => @driver.execute_script("return Format.formatUptime(\"#{ varz_router['uptime'] }\")") },
                            { :label => 'Cores',         :tag => nil, :value => varz_router['num_cores'].to_s },
                            { :label => 'CPU',           :tag => nil, :value => varz_router['cpu'].to_s },
                            { :label => 'Memory',        :tag => nil, :value => varz_router['mem'].to_s },
                            { :label => 'Droplets',      :tag => nil, :value => varz_router['droplets'].to_s },
                            { :label => 'Requests',      :tag => nil, :value => varz_router['requests'].to_s },
                            { :label => 'Bad Requests',  :tag => nil, :value => varz_router['bad_requests'].to_s },
                            { :label => '2XX Responses', :tag => nil, :value => varz_router['responses_2xx'].to_s },
                            { :label => '3XX Responses', :tag => nil, :value => varz_router['responses_3xx'].to_s },
                            { :label => '4XX Responses', :tag => nil, :value => varz_router['responses_4xx'].to_s },
                            { :label => '5XX Responses', :tag => nil, :value => varz_router['responses_5xx'].to_s },
                            { :label => 'XXX Responses', :tag => nil, :value => varz_router['responses_xxx'].to_s }
                          ])
          end
        end
      end

      context 'Components' do
        let(:tab_id) { 'Components' }
        it 'has a table' do
          check_table_layout([
                               {
                                 :columns         => @driver.find_elements(:xpath => "//div[@id='ComponentsTableContainer']/div/div[5]/div[1]/div/table/thead/tr/th"),
                                 :expected_length => 4,
                                 :labels          => %w(Name Type State Started),
                                 :colspans        => nil
                               }
                             ])
          check_table_data(@driver.find_elements(:xpath => "//table[@id='ComponentsTable']/tbody/tr/td"),
                           [
                             nats_cloud_controller['host'],
                             nats_cloud_controller['type'],
                             @driver.execute_script('return Constants.STATUS__RUNNING'),
                             @driver.execute_script("return Format.formatDateString(\"#{ varz_cloud_controller['start'] }\")")
                           ])
        end
        it 'has a remove all components button' do
          expect(@driver.find_element(:id => 'ComponentsRemoveAllButton').displayed?).to be_true
        end
        context 'selectable' do
          it 'has details' do
            select_first_row
            check_details([
                            { :label => 'Name',    :tag => nil, :value => nats_cloud_controller['host'] },
                            { :label => 'Type',    :tag => nil, :value => nats_cloud_controller['type'] },
                            { :label => 'Started', :tag => nil, :value => @driver.execute_script("return Format.formatDateString(\"#{ varz_cloud_controller['start'] }\")") },
                            { :label => 'URI',     :tag => 'a', :value => nats_cloud_controller_varz },
                            { :label => 'State',   :tag => nil, :value => @driver.execute_script('return Constants.STATUS__RUNNING') }
                          ])
          end
        end
      end

      context 'Logs' do
        let(:tab_id) { 'Logs' }
        it 'has a table' do
          check_table_layout([
                               {
                                 :columns         => @driver.find_elements(:xpath => "//div[@id='LogsTableContainer']/div/div[5]/div[1]/div/table/thead/tr/th"),
                                 :expected_length => 3,
                                 :labels          => ['Path', 'Size', 'Last Modified'],
                                 :colspans        => nil
                               }
                             ])
        end
        it 'has contents' do
          row = get_first_row
          row.click
          columns = row.find_elements(:tag_name => 'td')
          expect(columns.length).to eq(3)
          expect(columns[0].text).to eq(log_file_displayed)
          expect(columns[1].text).to eq(log_file_displayed_contents_length.to_s)
          expect(columns[2].text).to eq(@driver.execute_script("return Format.formatDateNumber(#{ log_file_displayed_modified_milliseconds })"))
          expect(@driver.find_element(:id => 'LogContainer').displayed?).to be_true
          expect(@driver.find_element(:id => 'LogLink').text).to eq(columns[0].text)
          expect(@driver.find_element(:id => 'LogContents').text).to eq(log_file_displayed_contents)
        end
      end

      context 'Tasks' do
        let(:tab_id) { 'Tasks' }
        it 'has a table' do
          check_table_layout([
                               {
                                 :columns         => @driver.find_elements(:xpath => "//div[@id='TasksTableContainer']/div/div[5]/div[1]/div/table/thead/tr/th"),
                                 :expected_length => 3,
                                 :labels          => %w(Command State Started),
                                 :colspans        => nil
                               }
                             ])
        end
        it 'can show task output' do
          expect(@driver.find_element(:xpath => "//table[@id='TasksTable']/tbody/tr").text).to eq('No data available in table')
          @driver.find_element(:id => 'DEAs').click
          @driver.find_element(:id => 'DEAsCreateButton').click
          @driver.find_element(:id => 'DialogOkayButton').click
          @driver.find_element(:id => 'Tasks').click
          expect(@driver.find_elements(:xpath => "//table[@id='TasksTable']/tbody/tr").length).to eq(1)
          cells = @driver.find_elements(:xpath => "//table[@id='TasksTable']/tbody/tr/td")
          expect(cells[0].text).to eq(File.join(File.dirname(__FILE__)[0..-22], 'lib/admin/scripts', 'newDEA.sh'))
          expect(cells[1].text).to eq(@driver.execute_script('return Constants.STATUS__RUNNING'))
          @driver.find_elements(:xpath => "//table[@id='TasksTable']/tbody/tr")[0].click
          expect(@driver.find_element(:id => 'TaskContents').text.length > 0).to be_true
        end
      end

      context 'Stats' do
        let(:tab_id) { 'Stats' }
        context 'statistics' do
          before do
            add_stats
            @driver.find_element(:id => 'RefreshButton').click
          end
          it 'has a table' do
            check_stats_table('Stats')
          end
          it 'has a chart' do
            check_stats_chart('Stats')
          end
        end
        it 'can show current stats' do
          expect(@driver.find_element(:xpath => "//table[@id='StatsTable']/tbody/tr").text).to eq('No data available in table')
          @driver.find_element(:id => 'StatsCreateButton').click
          expect(@driver.find_element(:xpath => "//span[@id='DialogText']/span").text.length > 0).to be_true
          rows = @driver.find_elements(:xpath => "//span[@id='DialogText']/div/table/tbody/tr")
          rows.each do |row|
            expect(row.find_element(:class_name => 'cellRightAlign').text).to eq('1')
          end
          @driver.find_element(:id => 'DialogCancelButton').click
          expect(@driver.find_element(:xpath => "//table[@id='StatsTable']/tbody/tr").text).to eq('No data available in table')
        end
        it 'can create stats' do
          expect(@driver.find_element(:xpath => "//table[@id='StatsTable']/tbody/tr").text).to eq('No data available in table')
          @driver.find_element(:id => 'StatsCreateButton').click
          date = @driver.find_element(:xpath => "//span[@id='DialogText']/span").text
          @driver.find_element(:id => 'DialogOkayButton').click
          Selenium::WebDriver::Wait.new(:timeout => 5).until { @driver.find_element(:xpath => "//table[@id='StatsTable']/tbody/tr").text != 'No data available in table' }
          check_table_data(@driver.find_elements(:xpath => "//table[@id='StatsTable']/tbody/tr/td"), [date, '1', '1', '1', '1', '1', '1', '1'])
        end
      end
    end
  end
end
