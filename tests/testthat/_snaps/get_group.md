# print.meetup_group outputs full data correctly

    Code
      print.meetup_group(group)
    Message
      
      -- Meetup Group: --
      
      * Name: Tech Enthusiasts
      * URL: tech-enthusiasts
      * Link: http://meetup.com/tech-enthusiasts
      * Location: San Francisco, USA
      * Timezone: PST
      * Founded: January 01, 2020
      
      -- Statistics: 
      * Members: 500
      * Total Events: 100
      
      -- Organizer: 
      * Name: Jane Doe
      * Category: Technology
      
      -- Description: 
      A group for tech lovers

# print.meetup_group handles missing optional fields

    Code
      print.meetup_group(group)
    Message
      
      -- Meetup Group: --
      
      * Name: Beginner Coders
      * URL: beginner-coders
      * Link: http://meetup.com/beginner-coders
      * Timezone: EST
      * Founded: June 15, 2021
      
      -- Statistics: 
      * Members: 200
      * Total Events: 20
      
      -- Description: 
      No description available.

# print.meetup_group handles long descriptions

    Code
      print.meetup_group(group)
    Message
      
      -- Meetup Group: --
      
      * Name: History Lovers
      * URL: history-lovers
      * Link: http://meetup.com/history-lovers
      * Location: Boston, USA
      * Timezone: EST
      * Founded: September 20, 2019
      
      -- Statistics: 
      * Members: 1,000
      * Total Events: 50
      
      -- Organizer: 
      * Name: John Smith
      * Category: Education
      
      -- Description: 
      This is a great group for history enthusiasts. This is a great group for
      history enthusiasts. This is a great group for history enthusiasts. This is a
      great group for history enthusiasts. This is a...

# print.meetup_group handles edge case with location parts

    Code
      print.meetup_group(group)
    Message
      
      -- Meetup Group: --
      
      * Name: Science Gurus
      * URL: science-gurus
      * Link: http://meetup.com/science-gurus
      * Location: USA
      * Timezone: CST
      * Founded: March 01, 2018
      
      -- Statistics: 
      * Members: 300
      * Total Events: 30
      
      -- Organizer: 
      * Name: Sarah Lee
      
      -- Description: 
      Discussing science topics

