########################################################################
# This module holds all of the functions used to access typicality
# Date: 2016/04/20
# Author: Brad
########################################################################
module Typicality
  module_function

  # Constants
  BD_PCT_THRES = 0.20
  BD_CNT_THRES = 1
  BA_CNT_THRES = 1
  SQFT_THRES = 40
  EST_THRES = 40
  LOTSIZE_THRES = 40
  DIST_THRES_M = 1828.8
  DIST_THRES_FT = 6000
  NEARBY_THRES = 7
  NEIGHBOR_CNT_THRES = 2
  NEIGHBOR_EST_THRES = 33
  NEIGHBOR_BD_THRES = 66
  NEIGHBOR_SQFT_THRES = 33

  # Computes the typicality values (for comparables) using Zillow data
  def propertyTypicality(output, prop_data, comp_data, census_output, data_source)
    # Property count
    count_pass = Liquidity.getCompsCount(output, comp_data, data_source, usage = "Typicality")

    # Estimates
    propertyEstimateCheck(output, prop_data[:estimate], comp_data[:estimates], data_source)

    # Number of bedrooms comparison
    propertyBedroomCheck(output, prop_data[:bd], comp_data[:bds], census_output, data_source)

    # Number of bathroom comparison (Not Zillow)
    propertyBathroomCheck(output, prop_data[:ba], comp_data[:bas], data_source) unless data_source.to_s == "Zillow"

    # Sqft Check
    propertySqFtCheck(output, prop_data[:propSqFt], comp_data[:propSqFts], data_source)

    # Lot Size
    propertyLotSizeCheck(output, prop_data[:propType], prop_data[:lotSqFt], comp_data[:lotSizes], data_source)

    # Distance and Nearby Check (Zillow Only right now)
    nearbyCompCheck(output, comp_data, count_pass, data_source) if data_source == "Zillow"
  end

  # Function to do the estimates comparison
  def propertyEstimateCheck(output, prop_estimate, comps_estimates, data_source)
    output[data_source.to_sym][:dataSource] << data_source.to_s
    output[data_source.to_sym][:metricsUsage] << "Typicality"
    output[data_source.to_sym][:metricsNames] << "Estimate Typicality - Comps"

    # If the property estimate is not present
    if prop_estimate.nil?
      output[data_source.to_sym][:metrics] << 0
      output[data_source.to_sym][:metricsPass] << false
      output[data_source.to_sym][:metricsComments] << "Property Estimate Not Available"
      return
    end

    # Estimates
    comps_est_values = comps_estimates.compact

    if comps_est_values.length == 0 # lacking zest comp data
      output[data_source.to_sym][:metrics] << 0
      output[data_source.to_sym][:metricsPass] << false
      output[data_source.to_sym][:metricsComments] << "No comp ests found"
      return
    end

    # Compute values and save
    comp_est_mean = comps_est_values.mean.round(2)
    comp_est_med = comps_est_values.median.round(2)

    est_ratio = (((prop_estimate/comp_est_mean)-1).to_f*100.0).round(2)
    pass = (est_ratio.abs <= EST_THRES)
    comment = "Estimate must be within #{EST_THRES}% | Prop: #{prop_estimate} | Ave: #{comp_est_mean}; Med: #{comp_est_med}"

    output[data_source.to_sym][:metrics] << est_ratio
    output[data_source.to_sym][:metricsPass] << pass
    output[data_source.to_sym][:metricsComments] << comment 
  end

  # Function to do the sqft comparison
  def propertySqFtCheck(output, prop_sqft, comp_sqft, data_source)
    output[data_source.to_sym][:dataSource] << data_source.to_s
    output[data_source.to_sym][:metricsUsage] << "Typicality"
    output[data_source.to_sym][:metricsNames] << "SqFt Typicality - Comps"

    # If the property sqft is not present
    if prop_sqft.nil? || prop_sqft == 0
      output[data_source.to_sym][:metrics] << 0
      output[data_source.to_sym][:metricsPass] << false
      output[data_source.to_sym][:metricsComments] << "Property sqft 0 or not available"
      return
    end

    # Remove nils from Square Footage
    comps_sqft_values = comp_sqft.compact

    # Error checking - lacking sqft comp data
    if comps_sqft_values.length == 0
      output[data_source.to_sym][:metrics] << 0
      output[data_source.to_sym][:metricsPass] << false
      output[data_source.to_sym][:metricsComments] << "No comp sqft ests found"
      return
    end

    # Perform check and store values
    comp_sqft_mean = comps_sqft_values.mean.round(2)
    comp_sqft_median = comps_sqft_values.median.round(2)

    sqft_ratio = (((prop_sqft/comp_sqft_mean)-1).to_f*100.0).round(2)
    pass = (sqft_ratio.abs <= SQFT_THRES)
    comment = "SqFt must be within #{SQFT_THRES}% | Prop: #{prop_sqft} | Ave: #{comp_sqft_mean}; Med: #{comp_sqft_median}"

    output[data_source.to_sym][:metrics] << sqft_ratio
    output[data_source.to_sym][:metricsPass] << pass
    output[data_source.to_sym][:metricsComments] << comment
  end

  # Function to do the lot size comparison
  def propertyLotSizeCheck(output, prop_type, prop_lotsize, comp_lot_sizes, data_source)
    output[data_source.to_sym][:dataSource] << data_source.to_s
    output[data_source.to_sym][:metricsUsage] << "Typicality"
    output[data_source.to_sym][:metricsNames] << "Lot Size Typicality - Comps"

    # For Zillow - Check if the property is a condo - lot size condition does not apply
    if data_source.to_s == "Zillow" && prop_type == "Condominium"
      output[data_source.to_sym][:metrics] << 0
      output[data_source.to_sym][:metricsPass] << true
      output[data_source.to_sym][:metricsComments] << "Zillow - Does not apply to condominiums"
      return
    end

    # If the lot sqft is not present
    if prop_lotsize.nil?
      output[data_source.to_sym][:metrics] << 0 
      output[data_source.to_sym][:metricsPass] << false
      output[data_source.to_sym][:metricsComments] << "Property lot sqft not available"
      return
    end

    # Remove nils from the lot sizes
    comps_lotsize_values = comp_lot_sizes.compact

    # Error checking
    if (comp_lot_sizes.length == 0 || prop_lotsize.nil?)
      output[data_source.to_sym][:metrics] << 0
      output[data_source.to_sym][:metricsPass] << false
      output[data_source.to_sym][:metricsComments] << "No comp lot sizes found"
      return
    end

    # Compute ratio and store
    comp_lotsize_mean = comps_lotsize_values.mean.round(2)
    comp_lotsize_med = comps_lotsize_values.median.round(2)

    lotsize_ratio = (((prop_lotsize/comp_lotsize_mean)-1).to_f*100.0).round(2)
    pass = (lotsize_ratio.abs <= LOTSIZE_THRES)
    comment = "Lot Size must be within #{LOTSIZE_THRES}% | Prop: #{prop_lotsize} | Ave: #{comp_lotsize_mean}; Med: #{comp_lotsize_med}"

    # Store values
    output[data_source.to_sym][:metrics] << lotsize_ratio
    output[data_source.to_sym][:metricsPass] << pass
    output[data_source.to_sym][:metricsComments] << comment
  end

  # Function to do the bedroom count comparison
  def propertyBedroomCheck(output, num_bds, comps_bds, census_output, data_source)
    output[data_source.to_sym][:dataSource] << data_source.to_s
    output[data_source.to_sym][:metricsUsage] << "Typicality"
    output[data_source.to_sym][:metricsNames] << "Bedrooms Typicality"

    # If the value is nil (i.e. missing data)
    if num_bds.nil?
      output[data_source.to_sym][:metrics] << "N/A"
      output[data_source.to_sym][:metricsPass] << false
      output[data_source.to_sym][:metricsComments] << "Property bd count not available"
      return
    end

    # Store the number of bedrooms
    output[data_source.to_sym][:metrics] << num_bds

    # Data source is Zillow
    if data_source.to_s == "Zillow"
      # If bds between 2-4, we are good
      if num_bds <= 4 && num_bds >= 2
        output[data_source.to_sym][:metricsPass] << true
        output[data_source.to_sym][:metricsComments] << "Bedrooms between 2 and 4"
        return
      end

      # If we are below 1 or above 5, fail and exit
      if num_bds < 1 || num_bds > 5
        output[data_source.to_sym][:metricsPass] << false
        output[data_source.to_sym][:metricsComments] << "Unconventional number of bedrooms"
        return
      end

      # If bds equal 5 - check the census info
      if num_bds == 5 || num_bds == 1
        per_bd, census_url, outHH = CensusApi.getBedroomInfo(census_output, num_bds)

        pass = (per_bd >= BD_PCT_THRES)
        comment = "#{num_bds} bedrooms | % of #{num_bds} bedrooms in the #{outHH} house area: #{(per_bd*100).round(2)}% | Must be >= #{BD_PCT_THRES*100}%"

        output[data_source.to_sym][:metricsPass] << pass
        output[data_source.to_sym][:metricsComments] << comment
        output[:urlsToHit] << census_url
        return
      end
    end

    # Add functionality for MLS/FA - just average of nearby values
    if !(data_source.to_s == "Zillow")
      comps_avg_bd = comps_bds.mean.round(2)
      comps_med_bd = comps_bds.median.round(2)
      pass = (num_bds >= comps_avg_bd - BD_CNT_THRES && num_bds <= comps_avg_bd + BD_CNT_THRES)
      comment = "Bd between +/- #{BD_CNT_THRES} of Comps Avg. | Avg: #{comps_avg_bd}; Med: #{comps_med_bd}"

      output[data_source.to_sym][:metricsPass] << pass
      output[data_source.to_sym][:metricsComments] << comment
    end
  end

  # Function to compare property bathroom count vs. comps (Not Zillow)
  def propertyBathroomCheck(output, num_bas, comps_bas, data_source)
    output[data_source.to_sym][:dataSource] << data_source.to_s
    output[data_source.to_sym][:metricsUsage] << "Typicality"
    output[data_source.to_sym][:metricsNames] << "Bathrooms Typicality"

    # If the value is nil (i.e. missing data)
    if num_bas.nil?
      output[data_source.to_sym][:metrics] << "N/A"
      output[data_source.to_sym][:metricsPass] << false
      output[data_source.to_sym][:metricsComments] << "Property ba count not available"
      return
    end

    # Store the number of bedrooms
    output[data_source.to_sym][:metrics] << num_bas

    comps_avg_ba = comps_bas.mean.round(2)
    comps_med_ba = comps_bas.median.round(2)
    pass = (num_bas >= comps_avg_ba - BA_CNT_THRES && num_bas <= comps_avg_ba + BA_CNT_THRES)
    comment = "Ba between +/- #{BA_CNT_THRES} of Comps Avg. | Avg: #{comps_avg_ba}; Med: #{comps_med_ba}"

    output[data_source.to_sym][:metricsPass] << pass
    output[data_source.to_sym][:metricsComments] << comment
  end

  # Function to examine distance and determine "nearby" comp count - Mainly for Zillow
  def nearbyCompCheck(output, comp_data, count_pass, data_source)
    output[data_source.to_sym][:dataSource].push(data_source.to_s, data_source.to_s)
    output[data_source.to_sym][:metricsUsage].push("Typicality", "Typicality")
    output[data_source.to_sym][:metricsNames].push("Comps Distance", "Comps Nearby")

    # Remove nil values from distances array
    comps_distances = comp_data[:distances].compact

    # Error checking - lacking distance comp data
    if comps_distances.length == 0 
      output[data_source.to_sym][:metrics].push(0, 0)
      output[data_source.to_sym][:metricsPass].push(false, false)
      output[data_source.to_sym][:metricsComments].push("No comps found", "No comps found")
      return
    end

    # Distances
    avg_dist_less_min = (comps_distances.mean - comps_distances.min).round(2)
    dist_pass = (avg_dist_less_min <= DIST_THRES_M)
    dist_comment = "Average distance (less minimum distance) must be less than #{DIST_THRES_M} meters (#{DIST_THRES_FT} feet)"

    # Nearby Comps
    nearby_comps = comps_distances.select { |d| d <= DIST_THRES_M }.length
    nearby_pass = (nearby_comps >= NEARBY_THRES)
    nearby_comment = "At least seven comparable properties within #{DIST_THRES_M} meters (#{DIST_THRES_FT} feet)"

    # Eliminate double failing
    if !nearby_pass && !dist_pass
      nearby_pass = true
      nearby_comment = "We do not double penalize if both Comps Nearby and Comps Distance fails"
    end

    if !count_pass
      nearby_pass = true
      nearby_comment = "We do not double penalize if both Comps Nearby and Properties count fails"
    end

    # Store values
    output[data_source.to_sym][:metrics].push(avg_dist_less_min, nearby_comps)
    output[data_source.to_sym][:metricsPass].push(dist_pass, nearby_pass) 
    output[data_source.to_sym][:metricsComments].push(dist_comment, nearby_comment) 
  end

  # Function to compute the neighbors typicality (Zillow Only)
  def zillowNeighborsValues(output, prop_data)
    # Get the neighbors data from Zillow
    nb_data = ZillowApi.neighborsScrape(output, prop_data[:zpid])

    # Store Values
    output[:Zillow][:dataSource].push("Zillow", "Zillow", "Zillow", "Zillow")
    output[:Zillow][:metricsUsage].push("Typicality", "Typicality", "Typicality", "Typicality")

    # Neighbors Availability
    output[:Zillow][:metricsNames] << "Neighbors Available" 
    begin
      nb_values = [nb_data[:totalPriceCount], nb_data[:totalBathroomsCount], nb_data[:totalBedroomsCount], nb_data[:totalSqFtCount]]
      cnt_value = nb_values.min
      cnt_pass = cnt_value >= NEIGHBOR_CNT_THRES
      cnt_comment = "Total number of neighbors must be at least #{NEIGHBOR_CNT_THRES}"
    rescue
      cnt_value = 0
      cnt_pass = false
      cnt_comment = "Data Unavailable"
    end

    # Neighbors Estimate Typicality
    output[:Zillow][:metricsNames] << "Estimate Typicality - Neighbors" 
    begin
      neigh_est_avg = (nb_data[:totalPrice].to_f/nb_data[:totalPriceCount].to_f).round(0)
      est_nb_value = ((prop_data[:estimate]/neigh_est_avg-1)*100).round(1)
      est_nb_pass = (est_nb_value <= NEIGHBOR_EST_THRES)
      est_nb_comment = "% deviation from community within #{NEIGHBOR_EST_THRES}% | Prop: #{prop_data[:estimate]} | Avg: #{neigh_est_avg}"
    rescue
      est_nb_value = 0
      est_nb_pass = false
      est_nb_comment = "Data Unavailable"
    end

    # Neighbors Bedroom Typicality
    output[:Zillow][:metricsNames] << "Bedrooms Typicality - Neighbors"
    begin
      neigh_bd_avg = (nb_data[:totalBedrooms].to_f/nb_data[:totalBedroomsCount].to_f).round(2)
      bd_nb_value = ((prop_data[:bd]/neigh_bd_avg-1)*100).round(1)
      bd_nb_pass = (bd_nb_value <= NEIGHBOR_BD_THRES)
      bd_nb_comment = "% deviation from community within #{NEIGHBOR_BD_THRES}% | Prop: #{prop_data[:bd]} | Avg: #{neigh_bd_avg}"
    rescue
      bd_nb_value = 0
      bd_nb_pass = false
      bd_nb_comment = "Data Unavailable"
    end

    # Neighbors Sqft Typicality
    output[:Zillow][:metricsNames] << "SqFt Typicality - Neighbors"
    begin
      neigh_sqft_avg = (nb_data[:totalSqFt].to_f/nb_data[:totalSqFtCount].to_f).round(0)
      sqft_nb_value = ((prop_data[:propSqFt]/neigh_sqft_avg-1)*100).round(1)
      sqft_nb_pass = (sqft_nb_value <= NEIGHBOR_SQFT_THRES)
      sqft_nb_comment = "% deviation from community within #{NEIGHBOR_SQFT_THRES}% | Prop: #{prop_data[:propSqFt]} | Avg: #{neigh_sqft_avg}"
    rescue
      sqft_nb_value = 0
      sqft_nb_pass = false
      sqft_nb_comment = "Data Unavailable"
    end

    # Store Values
    output[:Zillow][:metrics].push(cnt_value, est_nb_value, bd_nb_value, sqft_nb_value)
    output[:Zillow][:metricsPass].push(cnt_pass, est_nb_pass, bd_nb_pass, sqft_nb_pass) 
    output[:Zillow][:metricsComments].push(cnt_comment, est_nb_comment, bd_nb_comment, sqft_nb_comment) 
  end

end