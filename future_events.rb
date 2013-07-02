require File.dirname(__FILE__) + '/shared.rb'

class FutureEvents
		attr_accessor :gcalsession, :config, :client, :jenkins_api_job
	#Log into google calendar
	#Read configuration values from config.yml
	#Create Jenkins Client session
	#Invoke capture events method
	def initialize
		puts 'login'
		@gcalsession = GData.new
		@config = YAML::load_file(File.dirname(__FILE__) + '/config.yml')
		@client = JenkinsApi::Client.new(YAML.load_file(File.dirname(__FILE__) + '/config.yml'))
		jenkins_api_job = JenkinsApi::Client::Job.new @client
		token = gcalsession.login(config['googlecalendarusername'], config['googlecalendarpassword'])
		puts "token: #{token}"
		capture_events
	end
	
	#Get all job names from jenkins server
	#Read each job configuration xml for trigger value
	#Get downstreamProjects and lastSuccessfulBuild
	#Parse trigger value and convert it to google date format
	#Create events and render it on google calendar
	def capture_events
		puts "--------- Adding future builds starts here -------"
		response_job_names = @client.api_get_request("")
		jobs = []
		response_job_names["jobs"].each { |job| jobs << job["name"] 
		}

		jobs.each { |job|
		puts "Job: #{job}" 
		configs =''
		configs << @client.get_config("/job/#{job}")
		response_job_details = @client.api_get_request("/job/#{job}")
		childjobs = response_job_details["downstreamProjects"]
		str1="<spec>"
		str2="<\/spec>"
		triggervalue = configs[/#{str1}(.*?)#{str2}/m, 1]
		build = response_job_details["lastSuccessfulBuild"]
		if !(build.nil?)
		build = response_job_details["lastSuccessfulBuild"]["number"]
		else
		build = @client.job.get_current_build_number(job)
		end
		if !(build.nil?) && build > 0
		response_build_details = @client.api_get_request("/job/#{job}/#{build}")
		esttime = response_build_details["duration"]
		esttime = ((esttime.to_f()/1000)%60)
		end
		buildno = @client.job.get_current_build_number(job)
		if !(triggervalue.to_s.start_with?('@')) && !(triggervalue.to_s.start_with?('H')) && triggervalue.to_s != ''
		cron_parser = CronParser.new(triggervalue)
		time = Time.now
		lastday = time + (config['futureeventstime']*24*60*60)
		while time < lastday do
		starttime = time
		next_comming_time = cron_parser.next(time)
		buildno = buildno.to_i()+1
		time=next_comming_time
		endtime = time + (esttime)

		googlestartdate = time.strftime(config['googledateformat'])+'T'+time.to_s.split(' ')[1]
		googleenddate = endtime.strftime(config['googledateformat'])+'T'+endtime.to_s.split(' ')[1]

		summary = job + " #" + buildno.to_s + " Estimated time to complete " + esttime.to_i().to_s + "sec"
		childDesc = ''
		if childjobs.any?
		childDesc = "Child Jobs"
		childDesc = "\n" + childDesc + "------------------"
		childjobs.each {|childjob|
		childDesc = childDesc + childjob["name"].to_s + "\n"
		}
		childDesc = childDesc + "------------------"
		end
		if childDesc.length>0
		summary = summary + "\n" + childDesc
		end

		event = {:title=>summary,
			  :author=>config['author'], 
			  :email=>config['email'], 
			  :startTime=>googlestartdate,
			  :endTime=>googleenddate}
		response = gcalsession.new_event(event)
		status = YAML::load_file(File.dirname(__FILE__) + '/status.yml')
		status['futureeventstilldate'] = starttime
		File.open(File.dirname(__FILE__) + '/status.yml', "w") {|f| f.write(status.to_yaml) }
		puts 'done'
		end
		end
		}
		puts "-------- Adding future builds ends here -------"
	end

end

puts FutureEvents.new
