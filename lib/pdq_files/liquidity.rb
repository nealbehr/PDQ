########################################################################
# This module holds all of the functions used to access liquidity
# Date: 2016/04/25
# Author: Brad
########################################################################
module Liquidity
  module_function

  # Constants
  COMPS_COUNT_THRES = 7
  COMPS_RECENCY_THRES = 3
  COMPS_SCORE_THRES = 6.0
  DATE_THRES = Date.today - 180

  def propertyLiquidity(output, comp_data, data_source)
    # Comps Count and Recency for all data sources
    getCompsCount(output, comp_data, data_source, usage = "Liquidity")
    getCompsRecency(output, comp_data, data_source)

    # Score only for Zillow
    getCompsScore(output, comp_data) if data_source.to_s == "Zillow"
  end

  # Function to compute the averge comps score (Zillow Only)
  def getCompsScore(output, comp_data)
    # If no comps are found
    if comp_data[:count] == 0
      score_value = 0
      score_pass = false
      score_comment = "N/A"
    end

    # If comps are found
    if comp_data[:count] > 0
      scores = comp_data[:scores].compact # remove nils

      score_value = scores.mean().round(2)
      score_pass = (scores.mean() > COMPS_SCORE_THRES)
      score_comment = " > #{COMPS_SCORE_THRES}"
    end

    # Store Values
    output[:Zillow][:dataSource] << "Zillow"
    output[:Zillow][:metricsUsage] << "Liquidity"
    output[:Zillow][:metricsNames] << "Comps Score"
    output[:Zillow][:metrics] << score_value
    output[:Zillow][:metricsPass] << score_pass
    output[:Zillow][:metricsComments] << score_comment
  end

  # Function to compute the averge comps score (Zillow Only)
  def getCompsRecency(output, comp_data, data_source)
    # If no comps are found
    if comp_data[:count] == 0
      rec_value = 0
      rec_pass = false
      rec_comment = "N/A"
    end

    # If comps are found
    if comp_data[:count] > 0
      # Comps Recency (remove nils)
      # If last sold date listed, check whether it was sold in last 6 mos
      sale_dates = comp_data[:lastSoldDates].compact

      rec_value = sale_dates.select { |d| d > DATE_THRES }.length
      rec_pass = (rec_value >= COMPS_RECENCY_THRES)
      rec_comment = "At least #{COMPS_RECENCY_THRES} comparable properties sold within 180 days"
    end

    # Store Values
    output[data_source.to_sym][:dataSource] << data_source.to_s
    output[data_source.to_sym][:metricsUsage] << "Liquidity"
    output[data_source.to_sym][:metricsNames] << "Comps Recency"
    output[data_source.to_sym][:metrics] << rec_value
    output[data_source.to_sym][:metricsPass] << rec_pass
    output[data_source.to_sym][:metricsComments] << rec_comment
  end

  # Function to check if the number of comps passes
  def getCompsCount(output, comp_data, data_source, usage)
    # Comps count
    cnt_value = comp_data[:count].to_i
    cnt_pass = (cnt_value >= COMPS_COUNT_THRES)
    cnt_comment = "At least #{COMPS_COUNT_THRES} comparable properties found"

    # If no comps are found
    cnt_comment = "N/A" if (comp_data[:count].nil? || comp_data[:count] == 0)

    # Store Values
    output[data_source.to_sym][:dataSource] << data_source.to_s
    output[data_source.to_sym][:metricsUsage] << usage
    
    output[data_source.to_sym][:metricsNames] << "Comps Count" if usage == "Liquidity"
    output[data_source.to_sym][:metricsNames] << "Properties Count" if usage == "Typicality"

    output[data_source.to_sym][:metrics] << cnt_value
    output[data_source.to_sym][:metricsPass] << cnt_pass
    output[data_source.to_sym][:metricsComments] << cnt_comment
    return cnt_pass if usage == "Typicality"
  end
end