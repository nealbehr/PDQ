########################################################################
# This module holds all of the functions used in the research controller
# Date: 2016/04/08
# Author: Brad
########################################################################
module ResearchFunctions
  module_function

	# Load in gems
  require 'net/http'
  require 'uri'
  require 'nokogiri'
  require 'rubygems'
  require 'open-uri'
  require 'json'
  require 'openssl'
  require 'date'
  require 'time'
  require 'mixpanel-ruby'
  require 'httparty'

#################################
# Main functions
#################################

	# This function takes a PDQ ID as input and returns relevant rurality data in a JSON
	def getRuralityData(prop_data, rurality_names)
		puts "In getRuralityData function"

    # Set up storage; collect House, Location, PDQ ID
    results = Hash.new
    results['Id'] = prop_data.id
    results['Street'] = prop_data.street
    results['City-State-Zip'] = prop_data.citystatezip

		# Handle Property not found issues -----------------
  	if prop_data.reason.to_s.delete("[]\"").split(",").map(&:lstrip)[0] == "Not Found"
  	  	results["Status"] = "Property Not Found".to_json
  
		# If property ran correctly collect the data
  	else
  		# remove unwanted characters, leading whitespace from names, metrics,
	  	# and passes; separate into an arrays
	  	stripped_names = prop_data.names.to_s.delete("[]\"").split(",").map(&:lstrip) 
	  	stripped_metrics = prop_data.numbers.to_s.delete("[]\"").split(",").map(&:lstrip)
	  	stripped_passes = prop_data.passes.to_s.delete("[]\"").split(",").map(&:lstrip)

	  	# Collect variables of interest - if the id is historical, skip
	  	rurality_names.each do |x|
        begin
  	  		tmp_ind = stripped_names.index(x)
  	  		results[(x + ' Metric').to_sym] = stripped_metrics[tmp_ind]
  	  		results[(x + ' Pass').to_sym] = stripped_passes[tmp_ind]
        rescue
          results[(x + ' Metric').to_sym] = nil
          results[(x + ' Pass').to_sym] = nil
        end
	  	end
		end
		
		return results.to_json
	end


#################################
# Helper functions
#################################


end

