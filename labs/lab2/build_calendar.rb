require "date"

def die(msg)
  STDERR.puts "Ошибка: #{msg}"
  exit 1
end

# Проврека аргументов командной строки
die("Нужно 4 аргумента: teams.txt, start_date, end_date, calendar.txt") if ARGV.size != 4

teams_path, start_str, end_str, out_path = ARGV

puts "Входной файл команд: #{teams_path}"
puts "Дата начала: #{start_str}"
puts "Дата конца: #{end_str}"
puts "Выходной файл: #{out_path}"

# Парсинг дат
begin
  start_date = Date.strptime(start_str, "%d.%m.%Y")
  end_date   = Date.strptime(end_str, "%d.%m.%Y")
rescue ArgumentError
  die("Неверный формат даты. Используй dd.mm.yyyy, например 01.08.2026")
end

die("Дата начала должна быть раньше даты конца") if start_date >= end_date

puts("Преобразовнные даты: #{start_date}...#{end_date}")



# Читаем команды из файла
die("Файл #{teams_path} не найден") unless File.exist?(teams_path)

teams = []
seen = {}

File.foreach(teams_path, chompp: true).with_index(1) do |line, lineo|
  line = line.strip
  next if line.empty?

  # Убираем числа в начале строки
  line = line.sub(/^\d+\.\s+/, "")
  parts = line.split("—").map(&:strip)

  name, city = parts
  die("Строка #{lineo}: пустое имя комнады") if name.empty?
  die("Строка #{lineo}: пустой город") if city.empty?
  die("Строка #{lineo}: команда '#{name}' уже встречалась") if seen[name]

  teams << {name: name, city: city}
  seen[name] = true
end 

die("Команд должно быть не менее 2") if teams.length < 2

puts("Прочитано #{teams.length} команд")


# Создание пар команд
matches = []

for i in 0...teams.length
  for j in (i+1)...teams.length
    matches << [teams[i], teams[j]]
  end
end

puts("Матчей создано:  #{matches.length}")

# Создание слотов для матчей
current_date = start_date
slots = []
times = ["12:00", "15:00", "18:00"]

while current_date <= end_date
  if current_date.wday == 5 || current_date.wday == 6 || current_date.wday == 0
    for time in times
      slots << {date: current_date, time: time, capacity: 2, matches: []}
    end
  end
  current_date += 1
end
puts "Слотов создано: #{slots.length}"
puts "Максимум матчей влезет: #{slots.length * 2}"

# Распределение матчей по слотам
p_total = slots.length * 2
m_total = matches.length

die("Недостаточно слотов для всех матчей. Нужно #{m_total}, а есть #{p_total}") if m_total > p_total

step = p_total.to_f / m_total

for k in 0...m_total
  match = matches[k]
  pos = (k * step).floor
  slot_index = pos / 2

  # если целевой слот заполнен — ищем следующий свободный
  while slot_index < slots.length && slots[slot_index][:capacity] == 0
    slot_index += 1
  end

  die("Внезапно закончились слоты") if slot_index >= slots.length

  slots[slot_index][:matches] << match
  slots[slot_index][:capacity] -= 1
end

puts "Матчи распределены РАВНОМЕРНО."

#Вывод календаря в файл
File.open(out_path, "w:UTF-8") do |f|
  for slot in slots
    next if slot[:matches].empty?

    date_str = slot[:date].strftime("%d.%m.%Y")
    f.puts "#{date_str} #{slot[:time]}"
    
    for match in slot[:matches]
      home = match[0]
      away = match[1]
      f.puts "  #{home[:name]} (#{home[:city]}) — #{away[:name]} (#{away[:city]})"
    end

    f.puts ""  # пустая строка между слотами
  end
end

puts "Календарь записан в файл: #{out_path}"