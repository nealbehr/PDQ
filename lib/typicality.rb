########################################################################
# This module holds all of the functions used to access typicality
# Date: 2016/04/20
# Author: Brad
########################################################################
module Typicality
  module_function

  # Constants
  ZILLOW_TOKEN = "b49bd1d9d1932fc26ea257baf9395d26"

  # NEED TO CAPITALIZE THESE
  BD_THRES = .20
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
  def zillowTypicality(output, prop_data, comp_data, census_output)
    # Property count (same as comps data)
    count_idx = output[:metricsName].index("Properties Count")
    comps_count_idx = output[:metricsName].index("Comps Count")

    output[:metrics][count_idx] = comp_data[:compsCount].to_i
    output[:metricsPass][count_idx] = output[:metricsPass][comps_count_idx]
    output[:metricsComments][count_idx] = output[:metricsComments][comps_count_idx]

    # Number of bedrooms comparison
    num_bds = prop_data[:bd]
    output = zillowBedroomCheck(output, num_bds, census_output)

    # Square Footage
    comps_sqft_values = comp_data[:compsSqFt].compact
    sqft_idx = output[:metricsName].index("SqFt Typicality - Comps")

    if comps_sqft_values.length == 0 # lacking sqft comp data
      output[:metrics][sqft_idx] = 0
      output[:metricsPass][sqft_idx] = false
      output[:metricsComments][sqft_idx] = "SqFt not found"
    end

    if comps_sqft_values.length > 0
      sqft_ratio = ((prop_data[:propSqFt]/comp_sqft_values.mean())-1).to_f*100.0
      output[:metrics][sqft_idx] = sqft_ratio
      output[:metricsPass][sqft_idx] = sqft_ratio.abs <= SQFT_THRES
      output[:metricsComments][sqft_idx] = "SqFt must be within #{SQFT_THRES}% || Prop: #{prop_data[:propSqFt]} || Ave: #{comp_sqft_values.mean()}"
    end

    # Zestimates
    comps_zest_values = comp_data[:compsZestimate].compact
    est_idx = output[:metricsName].index("Estimate Typicality - Comps")

    if comps_zest_values.length == 0 # lacking zest comp data
      output[:metrics][est_idx] = 0
      output[:metricsPass][est_idx] = false
      output[:metricsComments][est_idx] = "N/A"
    end

    if comps_zest_values.length > 0 
      est_ratio = ((prop_data[:propZestimate]/comps_zest_values.mean())-1).to_f*100.0
      output[:metrics][est_idx] = est_ratio
      output[:metricsPass][est_idx] = est_ratio.abs <= EST_THRES
      output[:metricsComments][est_idx] = "Estimate must be within #{EST_THRES}% || Prop: #{prop_data[:propZestimate]} || Ave: #{comps_zest_values.mean()}"
    end

    # Lot Size
    output = zillowLotSizeCheck(output, prop_data[:propType], comp_data[:compsLotSize])

    # Distance and nearby comps
    comps_distances = comp_data[:compsDistance].compact
    dist_idx = output[:metricsName].index("Comps Distance")
    nearby_idx = output[:metricsName].index("Comps Nearby")

    if comps_distances.length == 0 # lacking distance comp data
      output[:metrics][dist_idx] = 0
      output[:metricsPass][dist_idx] = false
      output[:metricsComments][dist_idx] = "N/A"

      output[:metrics][nearby_idx] = 0
      output[:metricsPass][nearby_idx] = false
      output[:metricsComments][nearby_idx] = "N/A"
    end

    if comps_distances.length > 0 
      avg_dist_less_min = (comps_distances.mean() - comps_distances.min()).round(2)
      output[:metrics][dist_idx] = avg_dist_less_min
      output[:metricsPass][dist_idx] = avg_dist_less_min <= DIST_THRES_M
      output[:metricsComments][dist_idx] = "Average distance (less minimum distance) must be less than #{DIST_THRES_M} meters"
      #output[:urlsToHit] << comps_distances

      # Nearby Comps
      nearby_comps = comps_distances.select { |d| d <= DIST_THRES_M }.length
      output[:metrics][nearby_idx] = nearby_comps
      output[:metricsPass][nearby_idx] = nearby_comps >= NEARBY_THRES
      output[:metricsComments][nearby_idx] = "At least seven comparable properties within 6000 feet"

      # Eliminate double failing
      if (output[:metricsPass][nearby_idx] == false && output[:metricsPass][dist_idx] == false)
        output[:metricsPass][nearby_idx] = true
        output[:metricsComments][nearby_idx] = "We only count one if both Comps Nearby and Comps Distance fails"
      end

      if output[:metricsPass][count_idx] == false
        output[:metricsPass][nearby_idx] = true
        output[:metricsComments][nearby_idx] = "We do not double penalize if both Comps Nearby and Properties count fails"
      end
    end

    return output
  end

  # Function to do the lot size comparison for zillow data
  def zillowLotSizeCheck(output, prop_type, comp_lot_sizes)
    lotsize_idx = output[:metricsName].index("Lot Size Typicality - Comps")
    comps_lotsize_values = comp_lot_sizes.compact

    # Check if the property is a condo - lot size condition does not apply
    if prop_type == "Condominium"
      output[:metrics][lotsize_idx] = 0
      output[:metricsPass][lotsize_idx] = true
      output[:metricsComments][lotsize_idx] = "Does not apply to condominiums"
      return output
    end

    # Other Error checking
    if (comp_lot_sizes.length == 0 || prop_data[:lotSqFt].nil?)
      output[:metrics][lotsize_idx] = 0
      output[:metricsPass][lotsize_idx] = false
      output[:metricsComments][lotsize_idx] = "Unknown Lot Size"
      return output
    end

    comps_lotsize_values = comp_data[:compsLotSize].compact
    lotsize_ratio = ((prop_data[:lotSqFt]/comps_lotsize_values.mean())-1).to_f*100.0

    output[:metrics][lotsize_idx] = lotsize_ratio
    output[:metricsPass][lotsize_idx] = lotsize_ratio.abs <= LOTSIZE_THRES
    output[:metricsComments][lotsize_idx] = "Lot Size must be within #{LOTSIZE_THRES}% || Prop: #{prop_data[:lotSqFt]} || Ave: #{comps_lotsize_values.mean()}"

    return output
  end

  # Function to do the bedroom count comparison for zillow data
  def zillowBedroomCheck(output, num_bds, census_output)
    bds_idx = output[:metricsName].index("Bedrooms Typicality")
    output[:metrics][bds_idx] = num_bds

    # If the value is nil (i.e. missing data)
    if num_bds.nil?
      output[:metricsPass][bds_idx] = false
      output[:metricsComments][bds_idx] = "N/A"
      output[:metrics][bds_idx] = 0
      return output
    end

    # If bds between 2-4, we are good
    if num_bds <= 4 && num_bds >= 2
      output[:metricsPass][bds_idx] = true
      output[:metricsComments][bds_idx] = "Bedrooms between 2 and 4"
      return output
    end

    # If we are below 1 or above 5, fail and exit
    if num_bds < 1 && > 5
      output[:metricsPass][bds_idx] = false
      output[:metricsComments][bds_idx] = "Unconventional number of bedrooms"
      return output
    end

    # If bds equal 5 - check the census info
    if num_bds == 5 || num_bds == 1
      per_bd, census_url, outHH = CensusApi.getBedroomInfo(census_output, num_bds)
      per_bd >= BD_THRES ? output[:metricsPass][bd_idx] = true : output[:metricsPass][bd_idx] = false
      output[:metricsComments][bd_idx] = "#{num_bds} bedrooms || Percentage #{num_bds} bedrooms in the #{outHH} house area: #{per_bd.round(2)*100}"
      output[:urlsToHit].push(census_url)
      return output
    end
  end

  # Function to compute the neighbors typicality values for zillow
  def zillowNeighborsValues(output, prop_data)
    # Get the neighbors data from Zillow
    nb_data = ZillowApi.neighborsScrape(output, prop_data[:zpid])

    # Neighbors Availability
    neigh_cnt_idx = output[:metricsName].index("Neighbors Available")
    begin
      values = [nb_data[:totalPriceCount], nb_data[:totalBathroomsCount], nb_data[:totalBedroomsCount], nb_data[:totalSqFtCount]]
      output[:metrics][neigh_cnt_idx] = values.min
      output[:metricsPass][neigh_cnt_idx] = values.min >= NEIGHBOR_CNT_THRES
      output[:metricsComments][neigh_cnt_idx]= "Total number of neighbors must be at least #{NEIGHBOR_CNT_THRES}"
    rescue
      output[:metrics][neigh_cnt_idx]= 0    
      output[:metricsPass][neigh_cnt_idx] = false
      output[:metricsComments][neigh_cnt_idx]= "Data Unavailable"
    end

    # Neighbors Estimate Typicality
    neigh_est_idx = output[:metricsName].index("Estimate Typicality - Neighbors")
    begin
      neigh_est_avg = nb_data[:totalPrice].to_f/nb_data[:totalPriceCount].to_f
      est_ratio = ((prop_data[:propZestimate]/neigh_est_avg-1)*100).round(1)

      output[:metrics][neigh_est_idx] = est_ratio
      output[:metricsPass][neigh_est_idx] = est_ratio <= NEIGHBOR_EST_THRES
      output[:metricsComments][neigh_est_idx]= "% deviation from community within #{NEIGHBOR_EST_THRES}%   || Prop: #{prop_data[:propZestimate]}  || Avg: #{neigh_est_avg}"
    rescue
      output[:metrics][neigh_est_idx]= 0    
      output[:metricsPass][neigh_est_idx] = false
      output[:metricsComments][neigh_est_idx]= "Data Unavailable"
    end

    # Neighbors Bedroom Typicality
    neigh_bd_idx = output[:metricsName].index("Bedrooms Typicality - Neighbors")
    begin
      neigh_bd_avg = nb_data[:totalBedrooms].to_f/nb_data[:totalBedroomsCount].to_f
      bd_ratio = ((prop_data[:bd]/neigh_bd_avg-1)*100).round(1)

      output[:metrics][neigh_cnt_idx] = bd_ratio
      output[:metricsPass][neigh_bd_idx] = bd_ratio <= NEIGHBOR_BD_THRES
      output[:metricsComments][neigh_bd_idx]= "% deviation from community within #{NEIGHBOR_BD_THRES}%   || Prop: #{prop_data[:bd]}  || Avg: #{neigh_bd_avg}"
    rescue
      output[:metrics][neigh_bd_idx]= 0    
      output[:metricsPass][neigh_bd_idx] = false
      output[:metricsComments][neigh_bd_idx]= "Data Unavailable"
    end

    # Neighbors Sqft Typicality
    neigh_sqft_idx = output[:metricsName].index("SqFt Typicality - Neighbors")
    begin
      neigh_sqft_avg = nb_data[:totalSqFt].to_f/nb_data[:totalSqFtCount].to_f
      sqft_ratio = ((prop_data[:propSqFt]/neigh_sqft_avg-1)*100).round(1)

      output[:metrics][neigh_sqft_idx] = sqft_ratio
      output[:metricsPass][neigh_sqft_idx] = sqft_ratio <= NEIGHBOR_SQFT_THRES
      output[:metricsComments][neigh_sqft_idx]= "% deviation from community within #{NEIGHBOR_SQFT_THRES}%   || Prop: #{prop_data[:propSqFt]}  || Avg: #{neigh_sqft_avg}"
    rescue
      output[:metrics][neigh_sqft_idx]= 0    
      output[:metricsPass][neigh_sqft_idx] = false
      output[:metricsComments][neigh_sqft_idx]= "Data Unavailable"
    end

    return output
  end

  # Returns appropriate comparison data given mls comp data
  def mlsTypicality(output, prop_data, comp_data)
    # Compute comps recent sold count
    compsSold = comps_data[:sellInfo].select{ |i| (i["sellingPrice"] > 0 && i["sellingDate"].to_date > (Time.now.to_date - 180).to_date) }.length

    # Compute and return results (compact removes nil values)
    comp_results = {:avgBd => comp_data[:bd].mean, :medianBd => comp_data[:bd].median,
                    :avgBa => comp_data[:ba].mean, :medianBa => comp_data[:ba].median,
                    :avgValue => comp_data[:value].mean, :medianValue => comp_data[:value].median,
                    :avgSqFt => comp_data[:sqFt].compact.mean, :sqFtCount => comp_data[:sqFt].compact.length,
                    :avgLotSize => comp_data[:lotSize].compact.mean, :lotSizeCount => comp_data[:lotSize].compact.length,
                    :compsCount => comps.length, :execTime => Time.now-start_time,
                    :compsSoldCount => compsSold
                  }

    return comp_results
  end 


end