# print.meetup_user outputs full data correctly

    Code
      print.meetup_user(user)
    Message
      
      -- Meetup User: --
      
      * ID: user123
      * Name: John Doe
      * Email: john@example.com
      
      -- Roles: 
      * Organizer: Yes
      * Leader: No
      * Pro Organizer: Yes
      * Member Plus: No
      * Pro API Access: Yes
      
      -- Location: 
      * City: New York
      * Country: USA

# print.meetup_user handles missing optional fields

    Code
      print.meetup_user(user)
    Message
      
      -- Meetup User: --
      
      * ID: user123
      * Name: John Doe
      
      -- Roles: 
      * Organizer: No
      * Leader: No
      * Pro Organizer: No
      * Member Plus: No
      
      -- Location: 

# print.meetup_user handles partial location data

    Code
      print.meetup_user(user)
    Message
      
      -- Meetup User: --
      
      * ID: user123
      * Name: John Doe
      
      -- Roles: 
      * Organizer: Yes
      * Leader: Yes
      * Pro Organizer: No
      * Member Plus: Yes
      * Pro API Access: No
      
      -- Location: 
      * City: Los Angeles

