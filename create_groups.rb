data = {}
[1, 2, 3, 4, 5, 6].each do |c|
  data["course_#{c}"] = []
end

File.open('data/groups.txt').each do |l|
  data["course_#{l[19]}"].push({ name: l[0..10].strip, count: l[22..23].strip, weeks: 0 })
end

# Сортируем по названиям, чтобы была правильная последовательность подгрупп.
[1, 2, 3, 4, 5, 6].each do |c|
  data["course_#{c}"].sort { |a, b| a[:name] <=> b[:name] }
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

  row[:corpus] = case l[3].encode('UTF-8')
    when 'ГИ'
      4
    when 'ИДиЖ'
      7
    when 'ИТиМ'
      1
    when 'ПТ'
      1
    when 'РиСО'
      1
    when 'ЭиМ'
      4
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

uniq_preps = preps.uniq { |item| item[:department] + item[:name] }

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
