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
  RURALITY_SCORE_THRES = {:East => {:ruralityCutoff => 0.30,
                                    :ruralityLocalCutoff => 0.16},
                          :West => {:ruralityCutoff => 0.22,
                                    :ruralityLocalCutoff => 0.12}}

  # Function to get ZCTADensity
  def urbanDensityCheck(output, prop_data)
    idx = output[:metricsName].index("Urban Density")
    density = UrbanAreaData.getaZCTADensity(prop_data[:propUrbanCode]).round(2)
    pass = (density > DENSITY_THRES)
    comment = "< #{DENSITY_THRES} people/SqMi"

    # Current Return
    output[:metrics][idx] = density
    output[:metricsPass][idx] = pass
    output[:metricsComments][idx] = comment
    return output
    # return [density, pass, comment]
  end

  # Function to check the census tract density
  def censusTractDensityCheck(output, census_output)
    idx = output[:metricsName].index("Census Tract Density")

    # Get the census tract in db
    census_tract = Censustract.find_by(geoid: census_output["result"]["geographies"]["Census Tracts"][0]["GEOID"].to_s)

    # If error with census tract search
    if census_tract.nil?
      output[:metrics][idx] = 0
      output[:metricsPass][idx] = false
      output[:metricsComments][idx] = "Error with Census Tract Density"
      return output
    end

    # Compute density and save
    density = (censustract.hu.to_f / censustract.area.to_f).round(2)
    pass = (value > CENSUS_TRACT_THRES)
    comment = "< #{DENSITY_THRES} Houses/SqMi for tract #{censustract.name} || USB ID: #{censustract.home}"

    output[:metrics][idx] = density
    output[:metricsPass][idx] = pass
    output[:metricsComments][idx] = comment
    return output
    # return [density, pass, comment]
  end

  # Function to check the surrounding (neighbors) census tract densities
  def surroundingCensusDensityCheck(output, census_output)
    idx = output[:metricsName].index("Surrounding Census Tract Density")
    # Get the census tract in db
    census_tract = Censustract.find_by(geoid: census_output["result"]["geographies"]["Census Tracts"][0]["GEOID"].to_s)

    # If error with census tract search
    if census_tract.nil?
      output[:metrics][idx] = 0
      output[:metricsPass][idx] = false
      output[:metricsComments][idx] = "Error with Surrounding Census Tract Density"
      return output
    end

    # Get the neighbors in db
    censustractNeighbors = Neighbor.find_by(home: census_tract.home).neighbor.to_s.split("||")

    # If error with census tract neighbors search
    if censustractNeighbors.nil?
      output[:metrics][idx] = 0
      output[:metricsPass][idx] = false
      output[:metricsComments][idx] = "Error with Surrounding Census Tract Density"
      return output
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

    density =  censustractDensities.sort_by { |holder| holder[:tractdensity] }[0][:tractdensity].to_f.round(2)
    pass = (density > SURR_CENSUS_TRACT_THRES)
    comment = "> #{SURR_CENSUS_TRACT_THRES} houses/SqMi for tract: #{density} || Total of #{censustractDensities.uniq.size} tested."

    output[:metrics][idx] = density
    output[:metricsPass][idx] = pass
    output[:metricsComments][idx] = comment
    return output
    # return [density, pass, comment]
  end

  # Function to check the census block density and houses
  def censusBlockInfo(output, census_output)
    # Get data via Census API
    density, houses, url = CensusApi.getBlockInfo(census_output)
    output[:urlsToHit] << url
    den_idx = output[:metricsName].index("Census Block Density")
    hou_idx = output[:metricsName].index("Census Block Houses")
    # output = []

    # If error with density?
    if density.nil?
      output[:metrics][den_idx] = 0
      output[:metricsPass][den_idx] = false
      output[:metricsComments][den_idx] = "Error with Census Block Density"
      # output << [0, false, "Error with Census Block Density"]
    else
      pass = (density >= CENSUS_BLK_DENSITY_THRES)
      comment = "> #{CENSUS_BLK_DENSITY_THRES} Houses/SqMi for block: #{density}"
      output[:metrics][den_idx] = density
      output[:metricsPass][den_idx] = pass
      output[:metricsComments][den_idx] = comment
      # output << [density, pass, comment]
    end

    # If error with houses?
    if houses.nil?
      output[:metrics][hou_idx] = 0
      output[:metricsPass][hou_idx] = false
      output[:metricsComments][hou_idx] = "Error with Census Block Houses"
      # output << [0, false, "Error with Census Block Houses"]
    else
      pass = (houses >= CENSUS_BLK_HH_THRES)
      comment = "> #{CENSUS_BLK_HH_THRES} for block: #{houses}"
      output[:metrics][hou_idx] = houses
      output[:metricsPass][hou_idx] = pass
      output[:metricsComments][hou_idx] = comment
      # output << [density, pass, comment]
    end

    return output
  end

  def calcRuralityScore(output, prop_data)
    # Define property locale
    ['CA','WA','OR'].include? prop_data[:propState] ? loc = :West : loc = :East

    # Get variables
    urb_den = output[:metrics][output[:metricsNames].index("Urban Density")]
    cen_tract_den = output[:metrics][output[:metricsNames].index("Census Tract Density")]
    cen_blk_den = output[:metrics][output[:metricsNames].index("Census Block Density")]
    cen_blk_hou = output[:metrics][output[:metricsNames].index("Census Block Houses")]
    surr_cen_tract_den = output[:metricsPass][output[:metricsNames].index("Surrounding Census Tract Density")]
    cen_tract_den_pass = output[:metricsPass][output[:metricsNames].index("Census Tract Density")]

    # Compute Score
    idx = output[:metricsName].index("Rurality Score")
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
      output[:metrics][idx] = 1
      output[:metricsPass][idx] = false
      output[:metricsComments][idx] = "Error with calculating the Rurality Score"
      return output
      # return [1, false, "Error with calculating the Rurality Score"]
    end

    value = (Math.exp(ruralityScore) / (1.0 + Math.exp(ruralityScore))).round(5)
    pass = (value <= RURALITY_SCORE_THRES[loc][:ruralityCutoff])
    comment = "Probability of being rural || Rurality Exponent: #{ruralityScore.round(5)}"

    output[:metrics][idx] = value
    output[:metricsPass][idx] = pass
    output[:metricsComments][idx] = comment

    return output
    # return [value, pass, comment]
  end

  # Must be done after MSA Distance and other rurality checks
  def calcComboRural(output)
    idx = output[:metricsName].index("Combo Rural")
    r_score = output[:metrics][output[:metricsName].index("Rurality Score")]

    # Define property locale
    ['CA','WA','OR'].include? prop_data[:propState] ? loc = :West : loc = :East

    # if r_score > RURALITY_SCORE_THRES[loc][:ruralityLocalCutoff] && r_score > RURALITY_SCORE_THRES[loc][:ruralityCutoff]

    #   if



  end


end