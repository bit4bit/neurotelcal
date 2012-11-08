namespace :fix do
  desc 'Fix new update using Plivo from Bit4bit'
  task :billsec => :environment do
    PlivoCall.all.each do |plivo_call|
      cdr = Cdr.where(:uuid => plivo_call.uuid).first
      if cdr
        plivo_call.update_column(:bill_duration, cdr.billsec)
        plivo_call.call.update_column(:bill_duration, cdr.billsec)
      end
      
    end
  end
  
  desc 'Fix bug with plivo_calls.uuid and cdrs.uuid when not match. Bug 20 sep 2012'
  task :uuid => :environment do
    #Intentamos arreglar el error de almacenaje de los UUID
    PlivoCall.all.each do |plivo_call|
      cdrs = Cdr.where(:destination_number => plivo_call.number, :hangup_cause => plivo_call.hangup_enumeration).all
      Rails.logger.debug('fix: find n %d cdrs for client phonenumber %s and hangup_cause %s ' % [cdrs.count, plivo_call.number, plivo_call.hangup_enumeration]) if cdrs.count > 0
      
      if cdrs.count > 1 and plivo_call.hangup_enumeration == 'NORMAL_CLEARING'
        plcs = PlivoCall.where(:number => cdrs.first.destination_number, :hangup_enumeration => cdrs.first.hangup_cause)
        if plcs.count == cdrs.count
          plcs.all.each_index{|ip| plcs.all[ip].uuid = cdrs[ip].uuid; plcs.all[ip].save(:validate => false)}
          Rails.logger.debug("\tfix: fixeds")
        else
          Rails.logger.debug("\tfix: we not know how to fix the plivoCall.id %d with hangup cause NORMAL_CLEARING for multiples CDRs" % plivo_call.id)
        end
      elsif cdrs.count > 1
        plcs = PlivoCall.where(:number => cdrs.first.destination_number, :hangup_enumeration => cdrs.first.hangup_cause)
        if plcs.count > cdrs.count
          diff = plcs.count - cdrs.count
          rplcs = plcs.all[0..diff]
          crplcs = rplcs.count
          rplcs.each{|rp| rp.destroy; PlivoCall.all.delete(rp)}
          Rails.logger.debug("\tfix: we found more plivo %d calls with cdr %d so we destroy %d ..not need are calls we not response" % [plcs.count, cdrs.count, crplcs])

        end
        
        plcs = PlivoCall.where(:number => cdrs.first.destination_number, :hangup_enumeration => cdrs.first.hangup_cause).all
        if plcs.count == cdrs.count
          plcs.each_index{|ip| plcs[ip].uuid = cdrs[ip].uuid; 
            Rails.logger.debug("\tfix: cannot fix plivoCall %d" % plcs[ip].id) unless plcs[ip].save!
            Rails.logger.debug("\tfix: fixed plivocall %d uuid %s cdr uuid %s" % [plcs[ip].id, plcs[ip].uuid, cdrs[ip].uuid])
          }
          Rails.logger.debug("\tfix: we found plivocalls with exact cdrs.fixeds")
        else
          Rails.logger.debug("\tfix: not match plivoCalls %d with cdrs %d" % [plcs.count, cdrs.count])
        end
      elsif cdrs.count > 0
        if plivo_call.uuid == cdrs.first.uuid
          Rails.logger.debug("\tfix: omit")
          next
        end
        
        Rails.logger.debug("\tfix: fixed")
        plivo_call.uuid = cdrs.first.uuid
        plivo_call.save(:validate => false)
      end
    end
  end
end
