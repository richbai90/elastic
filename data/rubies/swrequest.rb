def add_default_keys_to_event(event, keys)
  keys.each do |name|
    name = "@metadata" if name == "metadata"
    name = name.split(".")
    name[0] =~ /s$/ ? event.set(name[0], []) : event.set(name[0], {})
  end
end

def handle_unamed_cols(message)
  i = 1
  message["query"].scan(/\w+\(.*?as '?([\w\.]+)'?/) do |name|
    skip = false
    message["recorddata"].each do |row|
      skip = true unless row[name[0]].nil?
      next if skip == true

      col = row["unnamedcol#{i}"]
      col_name = name[0]
      row[col_name] = row.delete("unnamedcol#{i}") unless col.nil?
    end
    i += 1 unless skip == true
  end
end

def setup_event(event, message)
  handle_unamed_cols(message)
  keys = message["recorddata"][0].keys
  @object_keys = (keys.each_with_object([]) do |key, obj_keys|
    obj_keys << key.to_s.split(".")[0] if key.to_s =~ /.+(\.).+/
  end).uniq
  @other_keys = keys.reject { |key| key =~ /.+(\.).+/ }
  add_default_keys_to_event(event, @object_keys)
end

def format_status(obj)
  return obj["value"] unless obj["type"] == "integer"

  formatted_value = case obj["value"]
                    when "1"
                      "pending"
                    when "2"
                      "unassigned"
                    when "3"
                      "unaccepted"
                    when "4"
                      "on hold"
                    when "5"
                      "off hold"
                    when "6"
                      "resolved"
                    when "7"
                      "deferred"
                    when "8"
                      "incoming"
                    when "9"
                      "escalated to owner"
                    when "10"
                      "escalated to group"
                    when "11"
                      "escalated to all"
                    when "15"
                      "lost call"
                    when "16"
                      "closed"
                    when "17"
                      "cancelled"
                    when "18"
                      "closed chargable"
                    else
                      obj["value"]
                    end
  formatted_value
end

def format(obj, key)
  return nil if obj["value"].nil? || obj["value"].empty?

  case key
  when "status"
    return format_status(obj)
  when /_on$/
    # elastic search expects milli epoch time
    return obj["type"] == "integer" ? obj["value"].to_i * 1000 : obj["value"]
  else
    return obj["type"] == "integer" ? obj["value"].to_i : obj["value"]
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

def add_objs_to_event(event, obj)
  @object_keys.each do |key|
    cols_for_obj = obj.select { |col, _val| col.split(".")[0] == key.split(".")[0] }
    ready = get_ready_for_evt(cols_for_obj)
    key = "@metadata" if key == "metadata"
    ready = event.get(key) << ready if key =~ /s$/ && !ready.empty?
    event.set(key, ready) unless ready.empty?
  end
end

def add_values_to_event(event, obj)
  @other_keys.each do |key|
    ready_value = format(obj[key], key)
    event.set(key, ready_value) unless ready_value.nil?
  end
end

def add_items(event, message)
  message["recorddata"].each do |row|
    add_objs_to_event(event, row)
    add_values_to_event(event, row)
  end
end

def cleanup(event)
  @object_keys.select { |key| key =~ /s$/ }.each do |key|
    cleaned = event.get(key).uniq do |item|
      item.each_with_object("") do |(k, v), str|
        str << "#{k}:#{v}:"
      end
    end
    event.set(key, cleaned)
  end
end

def filter(event)
  message = event.get("message")
  # we expect recordata to be an array
  message["recorddata"] = [message["recorddata"]].flatten
  setup_event(event, message)
  add_items(event, message)
  cleanup(event)
  event.remove("message")
  [event]
end
