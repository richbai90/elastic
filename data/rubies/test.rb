message = {
  'currRow' => nil,
  'currentrow' => 0,
  'eof' => false,
  'recordcount' => 7,
  'colcount' => 8,
  'recorddata' => [
    { 'updated_on' => { 'type' => 'integer',
                        'value' => '1552667729',
                        'formattedvalue' => '1552667729' },
      'time_spent' => { 'type' => 'bigint',
                        'value' => '0',
                        'formattedvalue' => '0' },
      'updated_by.id' => { 'type' => 'varchar',
                           'value' => 'SYSTEM-ESCALATION',
                           'formattedvalue' => 'SYSTEM-ESCALATION' },
      'source' => { 'type' => 'varchar',
                    'value' => 'VPME Escalation',
                    'formattedvalue' => 'VPME Escalation' },
      'text' => { 'type' => 'text',
                  'value' => 'This call has escalated and VPME emails were sent to: Owner',
                  'formattedvalue' => 'This call has escalated and VPME emails were sent to: Owner' },
      'unnamedcol1' => { 'type' => 'varchar',
                         'value' => 'SYSTEM',
                         'formattedvalue' => 'SYSTEM' },
      'metadata.id' => { 'type' => 'integer',
                         'value' => '8495',
                         'formattedvalue' => '8495' },
      'callref' => { 'type' => 'integer',
                     'value' => '1540',
                     'formattedvalue' => '1540' },
      '@metadata' => {} },
  ],
  'query' => "select udb.updatetxt as text,COALESCE(udb.udsource,'') as source, udb.aaid as 'updated_by.id', COALESCE(adb.name,'SYSTEM') as 'updated_by.name', udb.callref, udb.udid as 'metadata.id', COALESCE(udb.timespent,0) as time_spent, udb.updatetimex as updated_on from updatedb udb left join sw_systemdb.swanalysts adb on udb.aaid = adb.analystid where udb.callref = 1540"
}

def handle_unamed_cols(message)
  i = 1
  message['query'].scan(/\w+\(.*?as '?([\w\.]+)'?/) do |name|
    skip = false
    message['recorddata'].each do |row|
      skip = true unless row[name[0]].nil?
      next if skip == true

      col = row["unnamedcol#{i}"]
      col_name = name[0]
      row[col_name] = row.delete("unnamedcol#{i}") unless col.nil?
    end
    i += 1 unless skip == true
  end
end

def get_ready_for_evt(obj_to_get_ready)
    obj_to_get_ready.each_with_object({}) do |(obj_key, obj_value), ready_obj|
      ready_value = format(obj_value, obj_key)
      obj_keys = obj_key.split('.')
      obj_keys.slice!(0)
      obj_keys.each_with_index do |ready_key, index|
        unless ready_obj[ready_key].nil?
            ready_obj = ready_obj[ready_key]
            next
        end

        unless index == obj_keys.size - 1
          ready_obj[ready_key] = {}
          ready_obj = ready_obj[ready_key]
          next
        end

        ready_obj[ready_key] = ready_value unless ready_value.nil?
      end
    end
  end

  p get_ready_for_evt({"request.current_owner.id" => "admin", "request.current_owner.name" => "Foo"})
