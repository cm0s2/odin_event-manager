# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phonenumber(phonenumber)
  cleaned_phonenumber = phonenumber.to_s.delete('^0-9')

  if cleaned_phonenumber.length == 11 && cleaned_phonenumber[0] == '1'
    cleaned_phonenumber[1..-1]
  elsif cleaned_phonenumber.length == 10
    cleaned_phonenumber
  else
    '0000000000'
  end
  # rjust(10, '0')[0..9]
end

def clean_date(date)
  Time.strptime(date, '%m/%d/%y %R')
end

def peak_registration_hours(dates)
  peak = dates.reduce(Hash.new(0)) do |result, date|
    result[date.hour] += 1
    result
  end
  peak.sort_by { |_hour, times| times }.reverse.to_h
end

def peak_registration_dow(dates)
  peak = dates.reduce(Hash.new(0)) do |result, date|
    wday = Date::DAYNAMES[date.wday]
    result[wday] += 1
    result
  end
  peak.sort_by { |_day, times| times }.reverse.to_h
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
  rescue Google::Apis::ClientError => e
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

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

registration_dates = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  #phonenumber = clean_phonenumber(row[:homephone])
  #legislators = legislators_by_zipcode(zipcode)

  phonenumber = row[:homephone]
  cleaned_phonenumber = clean_phonenumber(phonenumber)


  registration_date = clean_date(row[:regdate])
  registration_dates.push(registration_date)


  

  # form_letter = erb_template.result(binding)
  # save_thank_you_letter(id, form_letter)
end

puts peak_registration_hours(registration_dates)
puts peak_registration_dow(registration_dates)