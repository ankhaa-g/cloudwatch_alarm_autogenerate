require 'aws-sdk-ec2'
require 'aws-sdk-cloudwatch'
require 'json'
load "config.rb"

def lambda_handler(event:, context:)

  # get running and CloudWatchAgent installed instances
  instances = get_ec2s()

  # get all Cloudwatch alarms
  all_alarms = get_alarms()

  created_alarm_count = 0

  # loop through each instances
  instances.each do |inst|

    # loop through required alarms
    REQUIRED_EC2ALARM_TEMPLATES.each do |alarm_template|

      # if reqiured alarm does not exists then create missing alarm
      if not alarm_exists?(inst.id, alarm_template[:metric_name], all_alarms) then

        alarm_args = Marshal.load(Marshal.dump(alarm_template)) # copy properties from template alarm
        alarm_args[:alarm_name] = get_ec2name(inst) + "_" + inst.id + " " + alarm_template[:alarm_name]
        alarm_args[:dimensions][0][:name] = "InstanceId"
        alarm_args[:dimensions][0][:value] = inst.id
        create_alarm(alarm_args)
        created_alarm_count += 1

      end
    end
  end

  puts "#{created_alarm_count} alarms created."
  return { statusCode: 200, body: JSON.generate("#{created_alarm_count} alarms created.") }
end

def get_ec2s
  ec2 = Aws::EC2::Resource.new(region: 'ap-northeast-1')

  # get running and CloudWatchAgent installed instances
  where = [
    { name: 'instance-state-name', values: ['running'] },
    { name: 'tag:CloudWatchAgent', values: ['installed'] }
  ]
  return ec2.instances({filters: where})
end

def get_ec2name(inst)
  name_tag = inst.tags.select{|tag| tag.key == 'Name'}.first
  return (name_tag ? name_tag.value : "" )
end

def get_alarms
  client = Aws::CloudWatch::Client.new(region: 'ap-northeast-1')
  ret_alarms = []

  ao = client.describe_alarms()
  ret_alarms.concat(ao.metric_alarms)

  #describe_alarms ni defaultaar 50 sh pagingeer avchirdag tul loopdej bugdiig avah
  while not ao.next_token.nil? do
    ao = client.describe_alarms({next_token: ao.next_token})
    ret_alarms.concat(ao.metric_alarms)
  end

  return ret_alarms
end

def alarm_exists?(instance_id, metric_name, alarms)
  alarms.each do |alarm|
    if alarm.metric_name == metric_name then
      alarm.dimensions.each do |d|
        if d.name == "InstanceId" and d.value == instance_id then
          return true
        end
      end
    end
  end
  return false
end

def create_alarm(alarm_args)
  client = Aws::CloudWatch::Client.new(region: 'ap-northeast-1')
  client.put_metric_alarm(alarm_args)
end

# use this if you testing on local
# puts lambda_handler(event: nil, context: nil)