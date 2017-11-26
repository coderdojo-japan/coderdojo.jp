namespace :dojo_event_services do
  desc '現在のyamlファイルを元にデータベースを更新します'
  task upsert: :environment do
    result = { inserted: [], updated: [], kept: [], skipped: [] }

    list = YAML.load_file(Rails.root.join('db','dojo_event_services.yaml'))
    list.each do |des|
      unless DojoEventService.names.keys.include?(des['name'])
        event_names = DojoEventService.names.keys.map {|s| "`#{s}`" }
        result[:skipped] << [des['dojo_id'], "Not used #{event_names.join(' or ')}"]
        next
      end

      dojo = Dojo.find_by(id: des['dojo_id'])
      unless dojo
        result[:skipped] << [des['dojo_id'], 'Not found record in `dojos` table']
        next
      end

      dojo_event_service = dojo.dojo_event_services.find_or_initialize_by(des)
      if dojo_event_service.changed?
        changes = dojo_event_service.changes
        new_record = dojo_event_service.new_record?
        dojo_event_service.save!
        (new_record ? result[:inserted] : result[:updated]) << ["#{des['dojo_id']}:#{dojo_event_service.id}", changes]
      else
        result[:kept] << ["#{des['dojo_id']}:#{dojo_event_service.id}"]
      end
    end

    # Dump result
    if !result[:inserted].empty? || !result[:updated].empty?
      result[:skipped] = result[:skipped].uniq {|s| s.first }
      result.except!(:kept, :skipped) unless ENV.key?('DEBUG')
      sorted = result.sort_by {|_, v| v.length }.reverse.to_h
      puts
      sorted.each do |k, v|
        puts "#{k.to_s.camelcase}: #{v.length}"
        v.each {|x| puts "  #{x.join(': ')}"}
      end
    end
  end
end
