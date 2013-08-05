data = {}
[1, 2, 3, 4, 5, 6].each do |c|
  data["course_#{c}"] = []
end

File.open('data/groups.txt').each do |l|
  data["course_#{l[19]}"].push({ name: l[0..10].strip, count: l[22..23].strip, weeks: 0, corpus: 0 })
end

# Сортируем по названиям, чтобы была правильная последовательность подгрупп.
[1, 2, 3, 4, 5, 6].each do |c|
  data["course_#{c}"].sort! { |a, b| a[:name] <=> b[:name] }
end

# 3 - факультет
# 5 - дисциплина
# 6 - курс/семестр или курс/сессия
# 7 - группа
# 8 - кол-во студентов
# 9 - кол-во недель
# 10 - вид занятий
# 11 - часов (на поток, группу, студента)
# 21 - преподаватель
# 22 - номер потока
# 23 - индикатор первой группы потока
# 24 - рекомендуемая аудитория
# 27 - кафедра
require 'csv'
mega = []
CSV.foreach('data/mmega.txt', row_sep: :auto, col_sep: "\t", encoding: 'windows-1251') do |l|
  row = {
      department: l[3].encode('UTF-8'),
      subject:    l[5].encode('UTF-8'),
      group:      l[7].encode('UTF-8'),
      count:      l[8].encode('UTF-8'),
      weeks:      l[9].nil? ? 0 : l[9].encode('UTF-8').to_i,
      type:       l[10].encode('UTF-8'),
      hours:      l[11].encode('UTF-8'),
      prep:       l[21].nil? ? nil : l[21].encode('UTF-8'),
      flow:       l[22].nil? ? nil : l[22].encode('UTF-8'),
      flow_number:l[23].nil? ? nil : l[23].encode('UTF-8'),
      room:       l[24].nil? ? nil : l[24].encode('UTF-8'),
      department: l[27].nil? ? nil : l[27].encode('UTF-8')
  }

  # Пропускаем заочку и вечёрку.
  next if 'З' == row[:group][0]
  next if 'В' == row[:group][0]

  # Если количество недель указано как 0, то это "скорее всего" какая-то практика.
  next if 0 == row[:weeks].to_i

  # Пропускаем аспирантуру.
  next if row[:group].include?('А-')

  name = l[7].encode('UTF-8')
  case name[1]
    when 'Г'
      row[:corpus] = 4
    when 'К'
      row[:corpus] = 7
    when 'Ц'
      row[:corpus] = 1
    when 'Т'
      row[:corpus] = 1
    when 'Р'
      row[:corpus] = 1
    when 'Э'
      row[:corpus] = 4
  end

  mega.push row
end

# Генерация файлов CL_1.DAT, CL_2.DAT, CL_3.DAT, CL_4.DAT, CL_5.DAT, CL_6.DAT,
# CLASS.DAT, CL_WEEKS.DAT.

cl_1_f = File.open('CL_1.DAT', 'w:windows-1251')
cl_1_f.write("#{data['course_1'].length}\r\n")
data['course_1'].each do |l|
  cl_1_f.write("#{l[:name]}\r\n")
end
cl_1_f.close

cl_2_f = File.open('CL_2.DAT', 'w:windows-1251')
cl_2_f.write("#{data['course_2'].length}\r\n")
data['course_2'].each do |l|
  cl_2_f.write("#{l[:name]}\r\n")
end
cl_2_f.close

cl_3_f = File.open('CL_3.DAT', 'w:windows-1251')
cl_3_f.write("#{data['course_3'].length}\r\n")
data['course_3'].each do |l|
  cl_3_f.write("#{l[:name]}\r\n")
end
cl_3_f.close

cl_4_f = File.open('CL_4.DAT', 'w:windows-1251')
cl_4_f.write("#{data['course_4'].length}\r\n")
data['course_4'].each do |l|
  cl_4_f.write("#{l[:name]}\r\n")
end
cl_4_f.close

cl_5_f = File.open('CL_5.DAT', 'w:windows-1251')
cl_5_f.write("#{data['course_5'].length}\r\n")
data['course_5'].each do |l|
  cl_5_f.write("#{l[:name]}\r\n")
end
cl_5_f.close

cl_6_f = File.open('CL_6.DAT', 'w:windows-1251')
cl_6_f.write("#{data['course_6'].length}\r\n")
data['course_6'].each do |l|
  cl_6_f.write("#{l[:name]}\r\n")
end
cl_6_f.close

total_count = 0
[1, 2, 3, 4, 5, 6].each do |c|
  total_count += data["course_#{c}"].length
end

# Определяем максимальное количество учебных недель для каждой группы.
[1, 2, 3, 4, 5, 6].each do |c|
  data["course_#{c}"].each do |g|

    mega.each do |row|
      if row[:group] == g[:name]
        g[:corpus] = row[:corpus]

        if row[:weeks] > g[:weeks]
          g[:weeks] = row[:weeks]
        end
      end
    end

  end
end

class_f = File.open('CLASS.DAT', 'w:windows-1251')
class_f.write("#{total_count.to_s}\r\n")
[1, 2, 3, 4, 5, 6].each do |c|
  data["course_#{c}"].each do |g|
    class_f.write('%03s' % g[:count])
    class_f.write(" 254 255 255 255 255 255 255 255 255 255 255   7   #{g[:corpus]}\r\n")
  end
end

cl_weeks_f = File.open('CL_WEEKS.DAT', 'w:windows-1251')
cl_weeks_f.write("%04s\r\n" % total_count.to_s)
[1, 2, 3, 4, 5, 6].each do |c|
  data["course_#{c}"].each do |g|
    cl_weeks_f.write("#{g[:weeks]}\r\n")
  end
end

# Формируем списки преподавателей.
preps = []
mega.each do |row|
  next if row[:prep].nil?
  next if row[:prep] == 'Вакансия'

  name = row[:prep][1..row[:prep].length]
  preps.push({ name: name, department: row[:department] })
end
uniq_preps = preps.uniq { |item| item[:department] + item[:name] }.sort { |a,b| a[:name] <=> b[:name] }

i = 1
uniq_preps.each_slice(20) do |group|
  name_f = File.open("NAME#{i}.DAT", 'w:windows-1251')
  name_f.write("#{group.length}\r\n")
  group.each do |prep|
    name_f.write("   2#{'%04s' % prep[:department]} 0 254 255 255 255 255 255 255 255 255 255 255   7 #{prep[:name]}\r\n")
  end

  i += 1
end

while i <= 99 do
  name_f = File.open("NAME#{i}.DAT", 'w:windows-1251')
  name_f.write("0\r\n")

  i += 1
end

# Формируем списки дисциплин.
subjects = []
mega.each do |row|
  next if row[:subject].nil?

  name = row[:subject]
  subjects.push(name)
end
uniq_subjects = subjects.uniq.sort { |a, b| a <=> b }

predmets_f = File.open('PREDMETS.DAT', 'w:windows-1251')
uniq_subjects.each do |s|
  raise s if s.length > 100
  predmets_f.write("#{s[0..99]}\r\n")
  predmets_f.write("#{s[0..24]}\r\n")
  predmets_f.write("#{s[0..7]}\r\n")
end

[1,2,3,4,5,6].each do |c|
  data["course_#{c}"].each do |g|
    g[:lectures] = []

    mega.each do |row|
      if g[:name] == row[:group]
        # Лекции
        if 'Лек' == row[:type] || 'лек' == row[:type]
          g[:lectures].push row
        end
      end
    end

    puts g.inspect
  end
end

# Формирование учебных планов!!!
baza_f = File.open('BAZA.DAT', 'w:windows-1251')
baza_f.write(" 21 21 21 324\r\n")

## Часы.
[1,2,3,4,5,6].each do |c|
  data["course_#{c}"].each do |g|
    written = 21
    g[:lectures].each do |lecture|
      next if 0 == lecture[:count].to_i
      next if 0 == lecture[:hours].to_i

      hours_to_weeks = lecture[:hours].to_f / lecture[:weeks].to_f
      if hours_to_weeks >= 1
        if 0 == hours_to_weeks % 1
          baza_f.write("#{'%04s' % hours_to_weeks.to_i.to_s}")
          written -= 1
          next
        end
      end

      baza_f.write("#{'%04s' % 0.to_s}")
      written -= 1
    end
    written.times { baza_f.write('   0') }

    written = 21
    written.times { baza_f.write('   0') }

    written = 21
    written.times { baza_f.write('   0') }

    baza_f.write("\r\n")
  end
end

## Преподаватели.
[1,2,3,4,5,6].each do |c|
  data["course_#{c}"].each do |g|
    written = 21
    g[:lectures].each do |lecture|
      next if 0 == lecture[:count].to_i
      next if lecture[:prep].nil?
      next if 'Вакансия' == lecture[:prep]
      #puts uniq_preps
      #puts lecture[:prep].inspect
      baza_f.write("#{'%05s' % (uniq_preps.index { |p| p[:name] == lecture[:prep][1..-1] } + 1).to_s}")
      written -= 1
    end
    written.times { baza_f.write('    0') }

    written = 21
    written.times { baza_f.write('    0') }

    written = 21
    written.times { baza_f.write('    0') }

    baza_f.write("\r\n")
  end
end

## Как?.
[1,2,3,4,5,6].each do |c|
  data["course_#{c}"].each do |g|
    written = 21
    g[:lectures].each do |lecture|
      next if 0 == lecture[:count].to_i
      #baza_f.write("#{'%06s' % (uniq_subjects.index(lecture[:subject]) + 1).to_s}")
      #written -= 1
    end
    written.times { baza_f.write(' 0') }

    written = 21
    written.times { baza_f.write(' 0') }

    written = 21
    written.times { baza_f.write(' 0') }

    baza_f.write("\r\n")
  end
end

## Особенности.
[1,2,3,4,5,6].each do |c|
  data["course_#{c}"].each do |g|
    written = 21
    g[:lectures].each do |lecture|
      next if 0 == lecture[:count].to_i
      if lecture[:flow].nil?
        baza_f.write('  0')
      else
          baza_f.write('  7')
      end
      written -= 1
    end
    written.times { baza_f.write('  0') }

    written = 21
    written.times { baza_f.write('  0') }

    written = 21
    written.times { baza_f.write('  0') }

    baza_f.write("\r\n")
  end
end

## Дисциплины.
[1,2,3,4,5,6].each do |c|
  data["course_#{c}"].each do |g|
    written = 21
    g[:lectures].each do |lecture|
      next if 0 == lecture[:count].to_i
      baza_f.write("#{'%06s' % (uniq_subjects.index(lecture[:subject]) + 1).to_s}")
      written -= 1
    end
    written.times { baza_f.write('     0') }

    written = 21
    written.times { baza_f.write('     0') }

    written = 21
    written.times { baza_f.write('     0') }

    baza_f.write("\r\n")
  end
end

## Часы на нечётной неделе.
[1,2,3,4,5,6].each do |c|
  data["course_#{c}"].each do |g|
    written = 21
    g[:lectures].each do |lecture|
      next if 0 == lecture[:count].to_i
      #baza_f.write("#{'%06s' % (uniq_subjects.index(lecture[:subject]) + 1).to_s}")
      #written -= 1
    end
    written.times { baza_f.write('   0') }

    written = 21
    written.times { baza_f.write('   0') }

    written = 21
    written.times { baza_f.write('   0') }

    baza_f.write("\r\n")
  end
end
