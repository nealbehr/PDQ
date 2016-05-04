########################################################################
# This module holds all of the functions used to access liquidity
# Date: 2016/04/25
# Author: Brad
########################################################################
module Liquidity
  module_function

  # Constants
  comps_count_thres = 7
  comps_recency_thres = 3
  comps_score_thres = 6.0
  date_thres = Date.today - 180

  def zillowLiquidity(output, comp_data)
    # Extract data and find indices
    score_idx = output[:metricsNames].index("Comps Score")
    recency_idx = output[:metricsNames].index("Comps Recency")
    count_idx = output[:metricsNames].index("Comps Count")

    # If no comps are found - all three fail and return
    if comp_data[:compsCount] == 0
      output[:metrics][score_idx] = "Comps not found"
      output[:metrics][recency_idx] = "Comps not found"
      output[:metrics][count_idx] = "Comps not found"

      output[:metricsPass][score_idx] = false
      output[:metricsPass][recency_idx] = false
      output[:metricsPass][count_idx] = false

      output[:metricsComments][score_idx] = "NA"
      output[:metricsComments][recency_idx] = "NA"
      output[:metricsComments][count_idx] = "NA"

      return output
    end

    # Comps count
    output[:metrics][count_idx] = comp_data[:compsCount].to_i
    output[:metricsPass][count_idx] = comp_data[:compsCount].to_i >= comps_count_thres
    output[:metricsComments][count_idx] = "At least #{comps_count_thres} comparable properties found" 

    # Comps Recency (remove nils)
    # If last sold date listed, check whether it was sold in last 6 mos
    sale_dates = comp_data[:compsLastSold].compact
    cnt = sale_dates.select { |d| d > date_thres }.length

    output[:metrics][recency_idx] = cnt
    output[:metricsPass][recency_idx] = (cnt >= comps_recency_thres)
    output[:metricsComments][recency_idx] = "At least #{comps_recency_thres} comparable properties sold within 180 days"

    # Comps Scores (remove nils)
    scores = comp_data[:compsScore].compact
    output[:metrics][score_idx] = scores.mean().round(2)
    output[:metricsPass][score_idx] = scores.mean() > comps_score_thres
    output[:metricsComments][score_idx] = " > #{comps_score_thres}"
    
    return output
  end

  def mlsLiquidity
  end

  def firstAmLiquidity
  end

end