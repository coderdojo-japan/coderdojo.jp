namespace :dojo_event_services do
  desc '現在のyamlファイルを元にデータベースを更新します'
  task upsert: :environment do
    puts 'Task as `dojo_event_services:upsert` starting...'

    result = { inserted: [], updated: [], kept: [], skipped: [] }

    list = YAML.load_file(Rails.root.join('db','dojo_event_services.yaml'))
    list.each do |des|
      unless DojoEventService.names.keys.include?(des['name'])
        event_names = DojoEventService.names.keys.map {|s| "`#{s}`" }
        result[:skipped] << [des['dojo_name'], "Not used #{event_names.join(' or ')}"]
        next
      end

      dojo = Dojo.find_by(name: des['dojo_name'])
      unless dojo
        result[:skipped] << [des['dojo_name'], 'Not found record in `dojos` table']
        next
      end

      insert = false
      unless dojo.dojo_event_service
        dojo.build_dojo_event_service
        insert = true
      end

      dojo.dojo_event_service.assign_attributes(des.except('dojo_name'))
      if dojo.dojo_event_service.changed?
        changes = dojo.dojo_event_service.changes
        dojo.dojo_event_service.save!
        (insert ? result[:inserted] : result[:updated]) << [des['dojo_name'], changes]
      else
        result[:kept] << [des['dojo_name']]
      end
    end

    # Dump result
    sorted = result.sort_by {|_, v| v.length }.reverse.to_h
    puts
    sorted.each do |k, v|
      puts "#{k.to_s.camelcase}: #{v.length}"
      v.each {|x| puts "  #{x.join(': ')}"}
    end
  end
end
