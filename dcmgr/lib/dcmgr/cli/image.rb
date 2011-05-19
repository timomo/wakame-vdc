# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class Image < Base
    namespace :image
    M = Dcmgr::Models


    class AddOperation < Base
      namespace :add

      desc "local URI [options]", "Register local store machine image."
      method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new machine image."
      method_option :account_id, :type => :string, :aliases => "-a", :required => true, :desc => "The UUID of the account that this machine image belongs to."
      method_option :arch, :type => :string, :default => 'x86_64', :desc => "The architecture for the new machine image. [#{M::HostPool::SUPPORTED_ARCH.join(', ')}]"
      method_option :is_public, :type => :boolean, :aliases => "-p", :default => false, :desc => "A flag that determines whether the new machine image is public or not."
      method_option :state, :type => :string, :aliases => "-st", :default => "init", :desc => "The state for the new machine image."
      def local(uri)
        UnknownUUIDError.raise(options[:account_id]) if M::Account[options[:account_id]].nil?
        UnsupportedArchError.raise(options[:arch]) unless M::HostPool::SUPPORTED_ARCH.member?(options[:arch])
        #TODO: Check if :state is a valid state
        fields = options.dup
        fields[:boot_dev_type]=M::Image::BOOT_DEV_LOCAL
        fields[:source] = {
          :type => "http",
          :uri => uri,
        }
        puts add(M::Image, fields)
      end

      desc "volume snapshot_id [options]", "Register volume store machine image."
      method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new machine image."
      method_option :account_id, :type => :string, :aliases => "-a", :required => true, :desc => "The UUID of the account that this machine image belongs to."
      method_option :arch, :type => :string, :default => 'x86_64', :desc => "The architecture for the new machine image. [#{M::HostPool::SUPPORTED_ARCH.join(', ')}]"
      method_option :is_public, :type => :boolean, :aliases => "-p", :default => false, :desc => "A flag that determines whether the new machine image is public or not."
      method_option :state, :type => :string, :aliases => "-st", :default => "init", :desc => "The state for the new machine image."
      def volume(snapshot_id)
        UnknownUUIDError.raise(options[:account_id]) if M::Account[options[:account_id]].nil?
        UnsupportedArchError.raise(options[:arch]) unless M::HostPool::SUPPORTED_ARCH.member?(options[:arch])
        UnknownUUIDError.raise(snapshot_id) if M::VolumeSnapshot[snapshot_id].nil?
        #TODO: Check if :state is a valid state
        fields = options.dup
        fields[:boot_dev_type]=M::Image::BOOT_DEV_SAN
        fields[:source] = {
          :snapshot_id => snapshot_id,
        }
        puts add(M::Image, fields)
      end
      
      protected
      def self.basename
        "vdc-manage #{Image.namespace} #{self.namespace}"
      end
    end

    register AddOperation, 'add', "add IMAGE_TYPE [options]", "Add image metadata [#{AddOperation.tasks.keys.join(', ')}]"

    desc "del IMAGE_ID", "Delete registered machine image."
    def del(image_id)
      UnknownUUIDError.raise(image_id) if M::Image[image_id].nil?
      super(M::Image, image_id)
    end

    desc "show [IMAGE_ID]", "Show list of machine image and details."
    def show(uuid=nil)
      if uuid
        img = M::Image[uuid]
        print ERB.new(<<__END, nil, '-').result(binding)
UUID: <%= img.canonical_uuid %>
Boot Type: <%= img.boot_dev_type %>
Arch: <%= img.arch %>
<%- if img.description -%>
Description:
<%= img.description %>
<%- end -%>
Is Public: <%= img.is_public %>
State: <%= img.state %>
__END
      else
        cond = {}
        imgs = M::Image.filter(cond).all
        print ERB.new(<<__END, nil, '-').result(binding)
<%- imgs.each { |row| -%>
<%= "%-20s  %-15s %-15s" % [row.canonical_uuid, row.boot_dev_type, row.arch] %>
<%- } -%>
__END
      end
    end
  end
end
