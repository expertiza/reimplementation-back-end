require 'faker'

puts "Three example students with username and email:"
3.times do
  username = Faker::Internet.unique.username(separators: ['_'])
  email = Faker::Internet.unique.email
  puts "Username: #{username}"
  puts "Email: #{email}"
  puts "Password: password"
  puts "---"
end
