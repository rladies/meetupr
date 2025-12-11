# print.meetupr_group / prints a nicely formatted group summary

    Code
      print(grp)
    Message
      
      -- Meetup Group: --
      
      * Name: G
      * URL: g
      * Link: http://g
      * Location: City, CT
      * Timezone: UTC
      * Founded: January 01, 2020
      
      -- Statistics: 
      * Members: 12
      * Total Events: 4
      
      -- Organizer: 
      * Name: Org
      * Category: Cat
      
      -- Description: 
      Hello world

# print.meetupr_group / handles missing optional fields gracefully

    Code
      print(grp)
    Message
      
      -- Meetup Group: --
      
      * Name: NoDesc
      * URL: nd
      * Link:
      * Timezone:
      * Founded: NULL
      
      -- Statistics: 
      * Members:
      * Total Events:

