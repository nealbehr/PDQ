########################################################################
# This module holds various investment guideline checks:
# => Price Range
# => In MSA
# => Recent Sale
# => Property Type
# => New Construction
# => Other
# Date: 2016/04/20
# Author: Brad
########################################################################
module InvestGuidelines
  module_function

  # Constants
  PRICE_MIN = 250000
  PRICE_MAX = 5000000

  # This function checks whether the property valuation is 
  # within the investment guidelines
  def propertyValueCheck(output, prop_data)
    idx = output[:metricsNames].index("Estimated Value")
    value = prop_data[:propEstimate]
    output[:metrics][idx] = value
    output[:metricsPass][idx] = (value <= PRICE_MAX && PRICE_MIN >= min)
    output[:metricsComments][idx] = "< #{max} & > #{min}"
    return output
  end

  # This function checks whether the property is in an approved MSA
  def propertyMsaCheck(output, prop_data)
    idx = output[:metricsNames].index("Pre-approval")

    # Lookup MSA
    msaOutput = UrbanAreaData.getMSA(prop_data[:propUrbanCode])
    output[:metrics][idx] = msaOutput[:status]

    # Check status code of that MSA
    if msaOutput[:status] == -1
      output[:metricsPass][idx] = false
      output[:metricsComments][idx] = "Not in MSA: #{msaOutput[:name]}"

    elsif msaOutput[:status] == 1
      output[:metricsPass][idx] = true
      output[:metricsComments][idx] = "In MSA: #{msaOutput[:name]} || State: #{state}"

    else
      output[:metricsPass][idx] = false
      output[:metricsComments][idx] = "There was an error evaluating the MSA"
    end

    return output
  end

  # Function to check the build date of the property condition
  def propertyBuildYearCheck(output, prop_data)
    idx = output[:metricsNames].index("Build Date")
    output[:metricsComments][idx] = "Can't be built this year or last"

    # If the year build field exists - perform the checks
    if !prop_data[:propBuildYear].nil?
      check_years = [Time.now.year.to_i, Time.now.year.to_i-1]
      output[:metrics][idx] = prop_data[:propBuildYear]
      output[:metricsPass][idx] = !(check_years.include? prop_data[:propBuildYear].to_i)
      return output
    end

    # If it does not - check the last sale date and use that if present
    if prop_data[:propBuildYear].nil?
      output[:metrics][idx] = "Not available"
      output[:metricsPass][idx] = false
      if !prop_data[:propLastSold].nil?
        output[:metricsComments][idx] = "Can't be built this year or last | approved based on sale date"
        output[:metricsPass][idx] = output[:metricsPass][output[:metricsNames].index("Last Sold History")]
      end
      return output
    end
  end

  # Function to check the property type
  def propertyTypeCheck(output, prop_data)
    idx = output[:metricsNames].index("Property Use")
    output[:metricsComments][idx] = "Has to be Single family Condominium or Townhouse"

    # If the property type field exists - perform the checks
    if !prop_data[:propType].nil?
      acceptable_props = ["SingleFamily", "Condominium", "Townhouse"] # Zillow
      output[:metrics][idx] = prop_data[:propType]
      output[:metricsPass][idx] = acceptable_props.include? prop_data[:propType]
      return output
    end

    if prop_data[:propType].nil?
      output[:metrics][idx] = "Not Available"
      output[:metricsComments][idx] = "NA"
      output[:metricsPass][idx] = true
      return output
    end
  end

  # Function to check if the property was recently sold
  def propertyRecentSalesCheck(output, prop_data, product)
    idx = output[:metricsNames].index("Last Sold History")

    # If the value is present, perform the checks
    if !prop_data[:propLastSold].nil?
      date_value = Date.strptime(prop_data[:propLastSold], "%m/%d/%Y").to_s.sub(",", "")
      output[:metrics][idx] = date_value
      output[:metricsPass][idx] = (date_value < Date.today - 365)
      output[:metricsComments][idx] = "Time from today: " + ((Date.strptime(prop_data[:propLastSold], "%m/%d/%Y") - Date.today).to_i * -1).to_s + " days"
    end

    # If the value is not present
    if prop_data[:propLastSold].nil?
      output[:metrics][idx] = "Not Available"
      output[:metricsPass][idx] = true
      output[:metricsComments][idx] = "NA"
    end

    # Metric not used for RA
    if product == "RA"
      output[:metricsComments][idx] = "Not used for Rex Agreements" 
      output[:metricsPass][idx] = true
    end

    return output
  end

end