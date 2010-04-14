module Wakame
  module Actions
    class LaunchVM < Action
      def initialize(notes_key, vm_spec)
        @notes_key = notes_key
        @vm_spec = vm_spec
      end

      USER_DATA_TMPL=<<__END__
node=agent
amqp_server=%s
__END__

      def run
        require 'right_aws'
        ec2 = RightAws::Ec2.new(Wakame.config.aws_access_key, Wakame.config.aws_secret_key, {:cache=>false})

        ref_attr = @vm_spec.merge(cluster.template_vm_attr)

        user_data = sprintf(USER_DATA_TMPL, cluster.advertised_amqp_servers)
        Wakame.log.debug("#{self.class}: Lauching VM: #{ref_attr.inspect}\nuser_data: #{user_data}")
        res = ec2.run_instances(ref_attr[:image_id], 1, 1,
                                ref_attr[:security_groups],
                                ref_attr[:key_name],
                                user_data,
                                'public', # addressing_type
                                ref_attr[:instance_type], # instance_type
                                nil, # kernel_id
                                nil, # ramdisk_id
                                ref_attr[:availability_zone], # availability_zone
                                nil # block_device_mappings
                                )[0]
        inst_id = res[:aws_instance_id]

        ConditionalWait.wait { | cond |
          cond.wait_event(Event::AgentMonitored) { |event|
            event.agent.vm_attr[:aws_instance_id] == inst_id
          }
          
          cond.poll(5, 360) {
            begin
              d = ec2.describe_instances([inst_id])[0]
              Wakame.log.debug("#{self.class}: Polling describe_instances(#{inst_id}): #{d[:aws_state]} ")
              d[:aws_state] == "running"
            rescue RightAws::AwsError => e
              if e.include?(%r'InvalidInstanceID.NotFound')
                # describe_instances() sometime fails due to this error when it is called just after sending run_instances().
                # This is the timing issue in AWS so that continues the polling check.
                Wakame.log.warn("Polling to describe_instances() got InvalidInstanceID.NotFound error with #{inst_id}. Retry again.")
                next
              else
                raise e
              end
            end
          }
        }

        notes[@notes_key] = inst_id

      end
    end
  end
end
