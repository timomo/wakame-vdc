# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class Group < Base
    namespace :group
    M = Dcmgr::Models

    desc "add [options]", "Add a new security group"
    method_option :uuid, :type => :string, :desc => "The UUID for the new security group."
    method_option :account_id, :type => :string, :desc => "The UUID of the account this security group belongs to.", :required => true
    method_option :description, :type => :string, :desc => "The description for this new security group."
    def add
      UnknownUUIDError.raise(options[:account_id]) if M::Account[options[:account_id]].nil?
      
      puts super(M::NetfilterGroup,options)
    end
    
    desc "del UUID", "Delete a security group"
    def del(uuid)
      super(M::NetfilterGroup,uuid)
    end
    
    desc "show [UUID]", "Show security group(s)"
    def show(uuid=nil)
      if uuid
        group = M::NetfilterGroup[uuid] || UnknownUUIDError.raise(uuid)
        puts ERB.new(<<__END, nil, '-').result(binding)
Group UUID:
  <%= group.canonical_uuid %>
Account id:
  <%= group.account_id %>
<%- if group.description -%>
Description:
  <%= group.description %>
<%- end -%>
<%- unless group.netfilter_rules.empty? -%>
Rules:
<%- group.netfilter_rules.each { |rule| -%>
  <%= rule.permission %>
<%- } -%>
<%- end -%>
__END
      else
        puts ERB.new(<<__END, nil, '-').result(binding)
<%- M::NetfilterGroup.all { |row| -%>
<%= row.canonical_uuid %>\t<%= row.account_id %>\t<%= row.description %>
<%- } -%>
__END
      end
    end
    
    desc "modify UUID [options]", "Modify an existing security group"
    method_option :account_id, :type => :string, :desc => "The UUID of the account this security group belongs to."
    method_option :description, :type => :string, :desc => "The description for this new security group."
    def modify(uuid)
      UnknownUUIDError.raise(options[:account_id]) if options[:account_id] && M::Account[options[:account_id]].nil?
      super(M::NetfilterGroup,uuid,options)
    end
    
    desc "apply UUID [options]", "Apply a security group to an instance"
    method_option :instance, :type => :string, :required => :true, :desc => "The instance to apply the group to"
    def apply(uuid)
      group = M::NetfilterGroup[uuid] || UnknownUUIDError.raise(uuid)
      instance = M::Instance[options[:instance]] || UnknownUUIDError.raise(options[:instance])
      Error.raise("Group #{uuid} is already applied to instance #{options[:instance]}.",100) if group.instances.member?(instance)
      group.add_instance(instance)
    end
    
    desc "remove UUID [options]", "Remove a security group from an instance"
    method_option :instance, :type => :string, :required => :true, :desc => "The instance to remove the group from"
    def remove(uuid)
      group = M::NetfilterGroup[uuid] || UnknownUUIDError.raise(uuid)
      instance = M::Instance[options[:instance]] || UnknownUUIDError.raise(options[:instance])
      Error.raise("Group #{uuid} is not applied to instance #{options[:instance]}.",100) unless group.instances.member?(instance)
      group.remove_instance(instance)
    end
    
    desc "addrule UUID RULE", "Add a rule to a security group"
    def addrule(g_uuid, rulestr)
      UnknownUUIDError.raise(g_uuid) if M::NetfilterGroup[g_uuid].nil?
      
      #TODO: check rule syntax
      new_rule = M::NetfilterRule.new(:permission => rulestr)
      new_rule.netfilter_group = M::NetfilterGroup[g_uuid]
      new_rule.save
    end
    
    desc "delrule UUID RULE", "Delete a rule from a security group"
    def delrule(g_uuid, rulestr)
      UnknownUUIDError.raise(g_uuid) if M::NetfilterGroup[g_uuid].nil?
      rule = M::NetfilterRule.find(:netfilter_group_id => M::NetfilterGroup[g_uuid].id, :permission => rulestr)
      Error.raise("Group '#{g_uuid}' does not contain rule '#{rulestr}'.",100) if rule.nil?
      
      rule.destroy
    end
  end
end
