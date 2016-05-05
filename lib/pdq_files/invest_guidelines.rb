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
  def propertyValueCheck(output, prop_data, data_source)
    # Perform check
    value = prop_data[:propEstimate]
    pass = (value <= PRICE_MAX && value >= PRICE_MIN)
    comment = "< #{max} & > #{min}"

    # Save values
    output[data_source.to_sym][:dataSource] << data_source.to_s
    output[data_source.to_sym][:metricsNames] << "Estimated Value"
    output[data_source.to_sym][:metricsUsage] << "Price Range"
    output[data_source.to_sym][:metrics] << value
    output[data_source.to_sym][:metricsPass] << pass
    output[data_source.to_sym][:metricsComments] << comment
  end

  # This function checks whether the property is in an approved MSA
  def propertyMsaCheck(output, prop_data, data_source)
    idx = output[:metricsNames].index("Pre-approval")

    # Lookup MSA
    msaOutput = UrbanAreaData.getMSA(prop_data[:propUrbanCode])
    value = msaOutput[:status]

    # Check status code of that MSA
    if value == -1
      pass = false
      comment = "Not in MSA: #{msaOutput[:name]}"
    elsif value == 1
      value = true
      comment = "In MSA: #{msaOutput[:name]} || State: #{prop_data[:propState]}"
    else
      value = false
      comment = "There was an error evaluating the MSA"
    end

    # Save values
    output[data_source.to_sym][:dataSource] << data_source.to_s
    output[data_source.to_sym][:metricsNames] << "Pre-approval"
    output[data_source.to_sym][:metricsUsage] << "MSA Check"
    output[data_source.to_sym][:metrics] << value
    output[data_source.to_sym][:metricsPass] << pass
    output[data_source.to_sym][:metricsComments] << comment
  end

  # Function to check the build date of the property condition
  # Must run recency check before this one
  def propertyBuildYearCheck(output, prop_data)
    # Initialize comment
    comment = "Can't be built this year or last"

    # If the year build field exists - perform the checks
    if !prop_data[:propBuildYear].nil?
      check_years = [Time.now.year.to_i, Time.now.year.to_i-1]
      value = prop_data[:propBuildYear]
      pass = !(check_years.include? value.to_i)
    end

    # If it does not - check the last sale date and use that if present
    if prop_data[:propBuildYear].nil?
      value << "Not available"
      pass << false
      if !prop_data[:propLastSold].nil?
        comment = "Can't be built this year or last | approved based on sale date"
        pass = output[data_source.to_sym][:metricsPass][output[data_source.to_sym][:metricsNames].index("Last Sold History")]
      end
    end

    # Save values
    output[data_source.to_sym][:dataSource] << data_source.to_s
    output[data_source.to_sym][:metricsNames] << "Build Date"
    output[data_source.to_sym][:metricsUsage] << "New Construction"
    output[data_source.to_sym][:metrics] << value
    output[data_source.to_sym][:metricsPass] << pass
    output[data_source.to_sym][:metricsComments] << comment
  end

  # Function to check the property type
  def propertyTypeCheck(output, prop_data, data_source)
    comment = "Has to be Single family Condominium or Townhouse"

    # If the property type field exists - perform the checks
    if !prop_data[:propType].nil?
      acceptable_props = ["SingleFamily", "Condominium", "Townhouse"] # Zillow
      value = prop_data[:propType]
      pass = acceptable_props.include? prop_data[:propType]
    end

    if prop_data[:propType].nil?
      value = "Not Available"
      comment = "NA"
      pass = true
    end

    # Save values
    output[data_source.to_sym][:dataSource] << data_source.to_s
    output[data_source.to_sym][:metricsNames] << "Property Use"
    output[data_source.to_sym][:metricsUsage] << "Property Type"
    output[data_source.to_sym][:metrics] << value
    output[data_source.to_sym][:metricsPass] << pass
    output[data_source.to_sym][:metricsComments] << comment
  end

  # Function to check if the property was recently sold
  def propertyRecentSalesCheck(output, prop_data, product)
    # If the value is present, perform the checks
    if !prop_data[:propLastSold].nil?
      date_value = Date.strptime(prop_data[:propLastSold], "%m/%d/%Y").to_s.sub(",", "")
      pass = (date_value < Date.today - 365)
      comment = "Time from today: #{((Date.strptime(prop_data[:propLastSold], "%m/%d/%Y") - Date.today).to_i * -1)} days"
    end

    # If the value is not present
    if prop_data[:propLastSold].nil?
      value = "Not Available"
      pass = true
      comment = "NA"
    end

    # Metric not used for RA
    if product == "RA"
      comment = "Not used for Rex Agreements" 
      pass = true
    end

    # Save values
    output[data_source.to_sym][:dataSource] << data_source.to_s
    output[data_source.to_sym][:metricsNames] << "Last Sold History"
    output[data_source.to_sym][:metricsUsage] << "Recent Sale"
    output[data_source.to_sym][:metrics] << value
    output[data_source.to_sym][:metricsPass] << pass
    output[data_source.to_sym][:metricsComments] << comment
  end
end