require 'mysql2'
require 'dotenv/load'

# Parse DATABASE_URL from environment
db_url = ENV['DATABASE_URL']

if db_url
  # Extract database name - assuming format: mysql2://user:pass@host:port/dbname
  db_name = db_url.split('/').last.split('?').first
  db_name = db_name.sub('expertiza', 'expertiza_development')

  # Extract credentials
  uri = URI.parse(db_url.sub('mysql2://', 'http://'))

  begin
    client = Mysql2::Client.new(
      host: uri.host || 'localhost',
      port: uri.port || 3306,
      username: uri.user || 'root',
      password: uri.password || '',
      database: db_name
    )

    # Get Student role ID
    role_result = client.query("SELECT id FROM roles WHERE name = 'Student' LIMIT 1")
    student_role_id = role_result.first['id'] if role_result.first

    if student_role_id
      # Get 3 student usernames
      results = client.query("SELECT name FROM users WHERE role_id = #{student_role_id} LIMIT 3")

      puts "Three student usernames:"
      results.each do |row|
        puts "- #{row['name']}"
      end
    else
      puts "No Student role found in database"
    end

    client.close
  rescue => e
    puts "Error: #{e.message}"
    puts "\nTrying with default credentials..."

    # Try default connection
    begin
      client = Mysql2::Client.new(
        host: 'localhost',
        username: 'root',
        password: '',
        database: 'expertiza_development'
      )

      role_result = client.query("SELECT id FROM roles WHERE name = 'Student' LIMIT 1")
      student_role_id = role_result.first['id'] if role_result.first

      if student_role_id
        results = client.query("SELECT name FROM users WHERE role_id = #{student_role_id} LIMIT 3")

        puts "Three student usernames:"
        results.each do |row|
          puts "- #{row['name']}"
        end
      else
        puts "No Student role found"
      end

      client.close
    rescue => e2
      puts "Failed: #{e2.message}"
    end
  end
else
  puts "DATABASE_URL not set"
end
