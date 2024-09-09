require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin 
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue 
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numebr(phone_number)
  phone_number = phone_number.to_s.tr('^0-9','')
  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 11 && phone_number[0] == 1 
    phone_number.slice!(0)
  else 
    phone_number = '0000000000'
  end
end

def most_common_value(array)
  array.group_by(&:itself).values.max_by(&:size).first
end

puts "EventManager initialized"

hours_people_signed_up = []
day_of_the_week_people_signed_up = []


contents = CSV.open(
  "event_attendees.csv",
  headers: true,
  header_converters: :symbol
  )

template_letter = File.read("../form_letter.erb")
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_number = clean_phone_numebr(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  datetime = Time.strptime(row[:regdate],"%m/%d/%y %H:%M")

  hours_people_signed_up << datetime.hour
  day_of_the_week_people_signed_up << datetime.wday

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

puts "Most common sign-up hour: #{most_common_value(hours_people_signed_up)}"
puts "Most common sign-up day of the week: #{most_common_value(day_of_the_week_people_signed_up)}"
