xml.instruct! :xml, :version => '1.0'
xml.Report :id => @entity.name, :start => @date_start, :end => @date_end do
  xml.Summary do
    xml.Answer :total => @summary[:answer_total]
    xml.IVR :total => @summary[:ivr_total]
    xml.DurationExpected :complete_total => @summary[:complete_duration_expected], :not_complete_total => @summary[:not_complete_duration_expected]
  end
  
  xml.Campaigns do
    @summary_by_campaign.each do |campaign, summary| 
      xml.Campaign :id=>campaign do
        xml.Summary do
          xml.Answer :total => summary[:answer_total]
          xml.DurationExpected :complete_total => summary[:complete_duration_expected], :not_complete_total => summary[:not_complete_duration_expected]
          xml.IVR :total => summary[:ivr_total] do
            xml.ImplementSummaryOfResponses
          end
        end

        xml.CDR do
          summary[:cdrs].each do |cdr|
            duration_expected = cdr.billsec >= @duration_expected ? true : false #@todo esto no va aqui, pero si uso IF de MySQL reduzco mas la DBI
            xml.callDetail :duration_expected_p => duration_expected, :answer_stamp => cdr.answer_stamp, :hangup_cause => cdr.hangup_cause, :start_stamp => cdr.start_stamp, :end_stamp => cdr.end_stamp, :destination_number => cdr.destination_number
          end
        end

      end
    end
  end
end
