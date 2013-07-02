require File.dirname(__FILE__) + '/shared.rb'

class PastEvents
	attr_accessor :gcalsession, :config, :client, :jenkins_api_job, :status, :pasttime
	#Log into google calendar
	#Read configuration values from config.yml
	#Update pasteventslastran status to status.yml
	#Create Jenkins Client session
	#Invoke capture events method
	def initialize
		puts 'login'
		@gcalsession = GData.new
		@config = YAML::load_file(File.dirname(__FILE__) + '/config.yml')
		@status = YAML::load_file(File.dirname(__FILE__) + '/status.yml')
		@client = JenkinsApi::Client.new(YAML.load_file(File.dirname(__FILE__) + '/config.yml'))
		jenkins_api_job = JenkinsApi::Client::Job.new @client
		token = gcalsession.login(config['googlecalendarusername'], config['googlecalendarpassword'])
		puts "token: #{token}"
		starttime = Time.now
		if status['pasteventslastran'] == 0
		@pasttime = starttime - (config['pasteventstime']*24*60*60)
		else
		@pasttime = status['pasteventslastran']
		end
		puts "here"
		puts pasttime
		status['pasteventslastran'] = starttime
		File.open(File.dirname(__FILE__) + '/status.yml', "w") {|f| f.write(status.to_yaml) }
		#File.write(File.dirname(__FILE__) + '/config.yml', d.to_yaml)
		capture_events
	end

	#Get all job names from jenkins server
	#Get all build numbers, time,  duration, result, url for all jobs
	#If build time is greater than pasteventslastran then render builds on google calendar
	def capture_events
		puts "--------- Adding last week build info. starts here -------"
		response_job_names = @client.api_get_request("")
		jobs = []
		response_job_names["jobs"].each { |job| jobs << job["name"] 
		}

		jobs.each { |job| 
		puts "Job: #{job}"
		response_json_builds = @client.api_get_request("/job/#{job}", "depth=1&tree=builds[id,duration,number,result,url]")
		filtered_jobs = []
		response_json_builds["builds"].each do |pastjob|
		buildtime = pastjob["id"].to_s.split('_')[0]
		puts "inside"
		puts pasttime
		   if Time.parse(buildtime) >= pasttime
			summary = job + " build #" + pastjob["number"].to_s + " " + pastjob["result"]
			content = "Check the status for build #" + pastjob["number"].to_s + " here "+ pastjob["url"]
			builddate = DateTime.parse(pastjob["id"].to_s.split('_')[0]+ " " + pastjob["id"].to_s.split('_')[1].gsub("-",":"))
			starttime = builddate.strftime(config['pasteventsdateformat'])
			buildendtime = Time.parse(starttime) + (pastjob["duration"]/(1000))
			googlestartdate = builddate.strftime(config['googledateformat'])+'T'+starttime.to_s+'.000Z'
			googleenddate = builddate.strftime(config['googledateformat'])+'T'+buildendtime.strftime(config['pasteventsdateformat'])+'.000Z'

			event = {
			  :title=>summary,  
			  :content=>content,
			  :author=>config['author'], 
			  :email=>config['email'], 
			  :startTime=>googlestartdate,
			  :endTime=>googleenddate}
			response = gcalsession.new_event(event, config['pasteventscalId'])
			puts 'done'
		   end
		end
		}
		puts "--------- Adding last week build info. ends here -------"
	end
end

puts PastEvents.new
