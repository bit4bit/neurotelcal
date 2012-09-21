namespace :fix do
  desc 'Fix bug with plivo_calls.uuid and cdrs.uuid when not match. Bug 20 sep 2012'
  task :uuid => :environment do
    #Intentamos arreglar el error de almacenaje de los UUID
    Cdr.all.each do |cdr|
      unless PlivoCall.where(:uuid => cdr.uuid).exists?
        Rails.logger.debug('fix: trying fix cdr uuid:%s' % cdr.uuid)
        #plivos posibles
        plivos = PlivoCall.where('updated_at >= ? AND updated_at <= ? AND number = ? AND hangup_enumeration = ?', cdr.start_stamp, cdr.end_stamp, cdr.destination_number, cdr.hangup_cause)
        if plivos.count == 1
          plivo = plivos.first
          Rails.logger.debug('fix: plivo %d with uuid:%s to cdr uuid:%s' % [plivo.id, plivo.uuid, cdr.uuid])
          plivo.uuid = cdr.uuid
          plivo.save()
        elsif plivos.count > 1
          Rails.logger.debug('fix: cdr with id %d has %d plivos' % [cdr.id, plivos.count])
        end
      else
        Rails.logger.debug('fix: cdr with id %d not have plivos' % cdr.id)
      end
    end
  end
end
