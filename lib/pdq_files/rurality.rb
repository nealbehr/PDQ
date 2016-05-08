########################################################################
# This module holds all of the functions used tin rurality assessment
# Date: 2016/04/25
# Author: Brad
########################################################################
module Rurality
  module_function

  # Constants
  DENSITY_THRES = 500
  CENSUS_TRACT_THRES = 500
  SURR_CENSUS_TRACT_THRES = 35.0
  CENSUS_BLK_DENSITY_THRES = 500
  CENSUS_BLK_HH_THRES = 15
  CR_RANGE_THRES = 25000
  CR_FRAC = (2.0/3.0)
  CR_CAP = 60000
  RURALITY_SCORE_THRES = {:East => {:ruralityCutoff => 0.30,
                                    :ruralityLocalCutoff => 0.16},
                          :West => {:ruralityCutoff => 0.22,
                                    :ruralityLocalCutoff => 0.12}
                        }

  # Collect the rurality metrics (as of now this is independent of property data source)
  def propertyRurality(output, address, census_output, closest_cities)
    state = address.citystatezip.split(" ")[-2]
    zip = address.citystatezip.split(" ")[-1]

    # Get the census tract in db
    census_tract = Censustract.find_by(geoid: census_output[:fullGeoId].to_s)

    # Compute rurality checks using census geo info, collect values as inputs to the score
    score_inputs = Hash.new
    score_inputs[:ud] = urbanDensityCheck(output, zip)
    score_inputs[:ctd] = censusTractDensityCheck(output, census_tract)
    score_inputs[:sctd] = surroundingCensusDensityCheck(output, census_tract)
    score_inputs[:cbd], score_inputs[:cbh] = censusBlockInfo(output, census_output)

    # Define property locale
    ['CA','WA','OR'].include? state ? loc = :West : loc = :East
    output[:region] = loc.to_s # save region for decision

    # Compute rurality score
    r_score = calcRuralityScore(output, score_inputs, loc)

    # Combo rural. Requires MSA distance to be run first!
    calcComboRural(output, r_score, loc, closest_cities)
  end

  # Function to get ZCTADensity
  def urbanDensityCheck(output, zipcode)
    output[:Census][:dataSource] << "Census"
    output[:Census][:metricsUsage] << "Rurality"
    output[:Census][:metricsNames] << "Urban Density"

    density = UrbanAreaData.getaZCTADensity(zipcode.to_i).round(2)
    pass = (density > DENSITY_THRES)
    comment = "< #{DENSITY_THRES} people/SqMi"

    # Current Return
    output[:Census][:metrics] << density
    output[:Census][:metricsPass] << pass
    output[:Census][:metricsComments] << comment
    return [density, pass]
  end

  # Function to check the census tract density
  def censusTractDensityCheck(output, census_tract)
    output[:Census][:dataSource] << "Census"
    output[:Census][:metricsUsage] << "Rurality"
    output[:Census][:metricsNames] << "Census Tract Density"

    # If error with census tract search
    if census_tract.nil?
      output[:Census][:metrics] << 0
      output[:Census][:metricsPass] << false
      output[:Census][:metricsComments] << "Error with Census Tract Density"
      return [0, false]
    end

    # Compute density and save
    density = (census_tract.hu.to_f / census_tract.area.to_f).round(2)
    pass = (density > CENSUS_TRACT_THRES)
    comment = "< #{DENSITY_THRES} Houses/SqMi for tract #{census_tract.name} | USB ID: #{census_tract.home}"

    output[:Census][:metrics] << density
    output[:Census][:metricsPass] << pass
    output[:Census][:metricsComments] << comment
    return [density, pass]
  end

  # Function to check the surrounding (neighbors) census tract densities
  def surroundingCensusDensityCheck(output, census_tract)
    output[:Census][:dataSource] << "Census"
    output[:Census][:metricsUsage] << "Rurality"
    output[:Census][:metricsNames] << "Surrounding Census Tract Density"

    # If error with census tract search
    if census_tract.nil?
      output[:Census][:metrics] << 0
      output[:Census][:metricsPass] << false
      output[:Census][:metricsComments] << "Error with Surrounding Census Tract Density"
      return [0, false]
    end

    # Get the neighbors in db
    censustractNeighbors = Neighbor.find_by(home: census_tract.home).neighbor.to_s.split("||")

    # If error with census tract neighbors search
    if censustractNeighbors.nil?
      output[:Census][:metrics] << 0
      output[:Census][:metricsPass] << false
      output[:Census][:metricsComments] << "Error with Surrounding Census Tract Density"
      return [0, false]
    end

    censustractDensities = []
    for x in 0..censustractNeighbors.size-1
      censustract = Censustract.find_by(home: censustractNeighbors[x])
      if censustract.area > 0.007 && censustract.pop / 20 < censustract.hu
        censustractDensities[x] = {censustract: censustract.name, tractdensity: censustract.hu / censustract.area}
      else
        censustractDensities[x] = {censustract: censustract.name, tractdensity: 31415}
      end
    end

    density =  censustractDensities.sort_by { |h| h[:tractdensity] }[0][:tractdensity].to_f.round(2)
    pass = (density > SURR_CENSUS_TRACT_THRES)
    comment = "> #{SURR_CENSUS_TRACT_THRES} houses/SqMi for tract: #{density} | Total of #{censustractDensities.uniq.size} tested."

    output[:Census][:metrics] << density
    output[:Census][:metricsPass] << pass
    output[:Census][:metricsComments] << comment
    return [density, pass]
  end

  # Function to check the census block density and houses
  def censusBlockInfo(output, census_output)
    # Get data via Census API
    density, houses, url = CensusApi.getBlockInfo(census_output)
    output[:urlsToHit] << url

    # Store values
    output[:Census][:dataSource].push("Census", "Census")
    output[:Census][:metricsUsage].push("Rurality", "Rurality")
    output[:Census][:metricsNames].push("Census Block Density","Census Block Density")

    # If error with density?
    if density.nil?
      output[:Census][:metrics] << 0
      output[:Census][:metricsPass]<< false
      output[:Census][:metricsComments] << "Error with Census Block Density"
    else
      den_pass = (density >= CENSUS_BLK_DENSITY_THRES)
      comment = "> #{CENSUS_BLK_DENSITY_THRES} Houses/SqMi for block: #{density}"

      output[:Census][:metrics] << density
      output[:Census][:metricsPass] << den_pass
      output[:Census][:metricsComments] << comment
    end

    # If error with houses?
    if houses.nil?
      output[:Census][:metrics] << 0
      output[:Census][:metricsPass] << false
      output[:Census][:metricsComments] << "Error with Census Block Houses"
    else
      hou_pass = (houses >= CENSUS_BLK_HH_THRES)
      comment = "> #{CENSUS_BLK_HH_THRES} for block: #{houses}"

      output[:Census][:metrics] << houses
      output[:Census][:metricsPass] << hou_pass
      output[:Census][:metricsComments] << comment
    end 
    return [density, den_pass], [houses, hou_pass]
  end

  def calcRuralityScore(output, score_inputs, loc)
    output[:Census][:dataSource] << "Census"
    output[:Census][:metricsUsage] << "Rurality"
    output[:Census][:metricsNames] << "Rurality Score"

    # Get variables
    urb_den = score_inputs[:ud][0]
    cen_tract_den = score_inputs[:ctd][0]
    cen_blk_den = score_inputs[:cbd][0]
    cen_blk_hou = score_inputs[:cbh][0]
    surr_cen_tract_den = score_inputs[:sctd][1]
    cen_tract_den_pass = score_inputs[:ctd][1]

    # Compute Score
    begin
      ruralityScore = (1.71820658968186 +
            (-15.41353150512030 * urb_den +
             -10.1395242746364 * cen_tract_den +
             -4.15071740631704 * cen_blk_den +
             -16.9412115229678 * ([cen_blk_hou, 80.0].min) +
             -6982.74818338132 * (surr_cen_tract_den ? 0.0 : 1.0) +
             -10000.0000000000 * (cen_tract_den_pass ? 0.0 : 1.0) +  
              0.0 ) /10000.0)
    rescue StandardError => e
      output[:Census][:metrics] << 1
      output[:Census][:metricsPass] << false
      output[:Census][:metricsComments] << "Error with calculating the Rurality Score"
      return 1
    end

    value = (Math.exp(ruralityScore) / (1.0 + Math.exp(ruralityScore))).round(5)
    pass = (value <= RURALITY_SCORE_THRES[loc][:ruralityCutoff])
    comment = "Probability of being rural | Rurality Exponent: #{ruralityScore.round(5)}"

    output[:Census][:metrics] << value
    output[:Census][:metricsPass] << pass
    output[:Census][:metricsComments] << comment
    return value
  end

  # Must be done after MSA Distance and other rurality checks
  def calcComboRural(output, r_score, loc, closest_cities)
    output[:Census][:dataSource] << "Census"
    output[:Census][:metricsUsage] << "Rurality"
    output[:Census][:metricsNames] << "Combo Rural"

    # Check if the rurality score is "in between" cutoffs for locale
    if r_score > RURALITY_SCORE_THRES[loc][:ruralityLocalCutoff] && r_score <= RURALITY_SCORE_THRES[loc][:ruralityCutoff]

      # If there was an error in MSA Distance break out of function
      if closest_cities[0] == "N/A"
        output[:Census][:metrics] << 0
        output[:Census][:metricsPass] << false
        output[:Census][:metricsComments] << "Error in MSA distances. Cannot conduct Combo Rural | Rurality Score is: #{r_score}"
        return
      end

      # Search for the ranges in the MsaDistance values
      ranges = closest_cities.select { |c| c[2] }
      comment = "Must be within 2/3 of a city range if Rurality Score is between #{RURALITY_SCORE_THRES[loc][:ruralityLocalCutoff]} and #{RURALITY_SCORE_THRES[loc][:ruralityCutoff]}"

      # If so, check the ranges
      if ranges[0] >= CR_RANGE_1
        value = closest_cities[0][0]
        pass = (value < [range[0].to_f*CR_FRAC, CR_CAP].min)

      elsif range[1] >= CR_RANGE_1
        value = closest_cities[1][0]
        pass = (value < [range[1].to_f*CR_FRAC, CR_CAP].min)
      else
        value = closest_cities[2][0]
        pass = (value < [range[2].to_f*CR_FRAC, CR_CAP].min)
      end

      # Store values
      output[:Census][:metrics] << value
      output[:Census][:metricsPass] << pass
      output[:Census][:metricsComments] << comment

    else
      output[:Census][:metrics] << 0
      output[:Census][:metricsPass] << true
      output[:Census][:metricsComments] << "Test does not apply | Rurality Score is: #{r_score}"
    end
  end
end