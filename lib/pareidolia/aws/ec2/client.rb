require 'aws-sdk'

module Pareidolia
  module Aws
    module EC2
      class Client
        METHODS = ::Aws::EC2::Client.public_instance_methods(false)
        DESCRIBE_METHODS = METHODS.select { |m| m.to_s.start_with? 'describe' }

        def initialize(**options)
          @options = options
          self
        end

        def classic_link_instances!
          @classic_link_instances = describe_classic_link_instances.instances
        end

        def host_reservations!
          @host_reservations = describe_host_reservations.host_reservation_set
        end

        def id_format!
          @id_format = describe_id_format.statuses
        end

        def image_attribute!(**options)
          describe_image_attribute options
        end

        alias image_attribute image_attribute!

        def instance_attribute!(**options)
          describe_instance_attribute options
        end

        alias instance_attribute instance_attribute!

        def instance_status!
          @instance_status = describe_instance_status.instance_statuses
        end

        def instance_status
          @instance_status ||= instance_status!
        end

        alias instance_statuses! instance_status!
        alias instance_statuses instance_status

        def reservations!
          @reservations = describe_instances.reservations
        end

        def reservations
          @reservations ||= reservations!
        end

        def instances!
          @instances = reservations!.flat_map(&:instances)
        end

        def moving_addresses!
          @moving_addresses = describe_moving_addresses.moving_address_statuses
        end

        def moving_addresses
          @moving_addresses ||= moving_addresses!
        end

        def network_interface_attribute!(**options)
          describe_network_interface_attribute options
        end

        alias network_interface_attribute network_interface_attribute!

        def scheduled_instance_availability!(**options)
          describe_scheduled_instance_availability options
        end

        alias scheduled_instance_availability scheduled_instance_availability!

        def security_group_references!(**options)
          describe_security_group_references(options).security_group_reference_set
        end

        alias security_group_references security_group_references!

        def snapshot_attribute!(**options)
          describe_snapshot_attribute options
        end

        alias snapshot_attribute snapshot_attribute!

        def spot_fleet_instances!(**options)
          describe_spot_fleet_instances options
        end

        alias spot_fleet_instances spot_fleet_instances!

        def spot_fleet_request_history!(**options)
          describe_spot_fleet_request_history options
        end

        alias spot_fleet_request_history spot_fleet_request_history!

        def stale_security_groups!(**options)
          describe_stale_security_groups options
        end

        alias stale_security_groups stale_security_groups!

        def volume_attribute!(**options)
          describe_volume_attribute options
        end

        alias volume_attribute volume_attribute!

        def vpc_attribute!(**options)
          describe_vpc_attribute options
        end

        alias vpc_attribute vpc_attribute!

        DESCRIBE_METHODS.each do |method|
          name = method.to_s.split('_').drop(1).join('_')
          raw = [name, '!'].join
          var = ['@', name].join

          define_method(raw) do |*args|
            r = send(method, *args)
            instance_variable_set var, (r.respond_to?(name) ? r.send(name) : r)
          end unless method_defined?(raw)

          define_method(name) do |*args|
            if instance_variable_defined? var
              instance_variable_get var
            else
              send(raw, *args)
            end
          end unless method_defined?(name)
        end

        private

        def ec2
          @ec2 ||= ::Aws::EC2::Client.new @options
        end

        def method_missing(method, *args)
          return super unless respond_to? method

          ec2.public_send(method, *args)
        rescue ::Aws::EC2::Errors::RequestLimitExceeded
          sleep rand 1..4.0
          retry
        end

        def respond_to?(method)
          ec2.respond_to?(method) || super
        end
      end
    end
  end
end
