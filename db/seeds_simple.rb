# Simple seed file for Campfire - creates basic data quickly
require 'faker'

puts "🔥 Starting Campfire simple database seed..."
puts "=" * 80

# Clean existing data
puts "\n🧹 Cleaning existing data..."
[Message, Session, Search, Membership, Room, User, Account].each do |model|
  count = model.count
  if count > 0
    print "  Removing #{count} #{model.name.pluralize}... "
    model.destroy_all
    puts "✓"
  end
end

# Reset SQLite sequences
ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name IN ('accounts', 'users', 'rooms', 'messages', 'memberships', 'searches', 'sessions', 'webhooks', 'push_subscriptions', 'boosts')")
puts "  Reset SQLite sequences ✓"
puts "Cleanup complete!\n"

# Create main account
puts "\n🏢 Creating Account..."
account = Account.create!(
  name: "Acme Corporation",
  join_code: "ACME2024",
  custom_styles: ""
)
puts "✓ Created account: #{account.name}"

# Create users
puts "\n👥 Creating Users..."
users = []

# Admin user
admin = User.create!(
  name: "Admin User",
  email_address: "admin@acme.com",
  password: "password123",
  role: "administrator",
  bio: "Platform administrator"
)
users << admin
puts "  ✓ Created admin user"

# Regular users
10.times do |i|
  user = User.create!(
    name: Faker::Name.name,
    email_address: "user#{i}@acme.com",
    password: "password123",
    role: "member",
    bio: Faker::Lorem.sentence
  )
  users << user
end
puts "  ✓ Created 10 regular users"

# Bot user
bot = User.create!(
  name: "CampBot",
  email_address: "bot@acme.com",
  password: SecureRandom.hex(16),
  role: "bot",
  bio: "Automated assistant"
)
users << bot
puts "  ✓ Created bot user"

puts "Total users created: #{users.count}"

# Create rooms
puts "\n🏠 Creating Rooms..."
rooms = []

# Open rooms (accessible to all)
open_room_names = ["General", "Random", "Announcements", "Tech Talk", "Water Cooler"]
open_room_names.each do |name|
  room = Rooms::Open.create!(
    name: name,
    creator: admin
  )
  rooms << room
end
puts "  ✓ Created #{open_room_names.count} open rooms"

# Closed rooms (invite only)
closed_room_names = ["Engineering", "Marketing", "Executive", "Product", "Design"]
closed_room_names.each do |name|
  room = Rooms::Closed.create!(
    name: name,
    creator: admin
  )
  # Add some users to each closed room
  room.memberships.grant_to(users.sample(5))
  rooms << room
end
puts "  ✓ Created #{closed_room_names.count} closed rooms"

# Direct message rooms
5.times do
  user_pair = users.sample(2)
  Current.user = user_pair.first  # Set current user for room creation
  room = Rooms::Direct.find_or_create_for(user_pair)
  rooms << room unless rooms.include?(room)
end
puts "  ✓ Created direct message rooms"

puts "Total rooms created: #{rooms.count}"

# Create messages
puts "\n💬 Creating Messages..."
message_count = 0

rooms.each do |room|
  # Skip if room has no members
  room_users = room.users.any? ? room.users : users.sample(3)
  
  # Create between 10-30 messages per room
  rand(10..30).times do
    creator = room_users.sample
    
    # Set current user for the message creation
    Current.user = creator
    
    message = room.messages.create!(
      body: Faker::Lorem.paragraph(sentence_count: rand(1..3)),
      creator: creator,
      client_message_id: SecureRandom.uuid
    )
    message_count += 1
    
    # Add some boosts randomly (20% chance)
    if rand < 0.2
      boosters = room_users.sample(rand(1..3))
      boosters.each do |booster|
        message.boosts.create!(booster: booster) rescue nil
      end
    end
  end
end

puts "✓ Created #{message_count} messages"

# Create some searches
puts "\n🔍 Creating Searches..."
search_count = 0
users.sample(5).each do |user|
  rand(1..3).times do
    Search.create!(
      user: user,
      query: Faker::Lorem.word
    )
    search_count += 1
  end
end
puts "✓ Created #{search_count} searches"

# Final statistics
puts "\n" + "=" * 80
puts "🎉 SEED COMPLETE!"
puts "=" * 80
puts "\n📊 Final Statistics:"
puts "  • Accounts: #{Account.count}"
puts "  • Users: #{User.count}"
puts "  • Rooms: #{Room.count}"
puts "  • Messages: #{Message.count}"
puts "  • Boosts: #{Boost.count}"
puts "  • Memberships: #{Membership.count}"
puts "  • Searches: #{Search.count}"

puts "\n✅ Database seeded successfully!"
puts "You can now run 'bin/dev' to start the application."