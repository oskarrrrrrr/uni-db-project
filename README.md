# Political party management system

University databases course final project.

## API
+ open     <database> <login> <password>
+ leader   <password> <member>
+ support  <timestamp> <member> <password> <action> <project> [<authority>]
+ protest  <timestamp> <member> <password> <action> <project> [<authority>]
+ upvote   <timestamp> <member> <password> <action>
+ downvote <timestamp> <member> <password> <action>
+ actions  <timestamp> <member> <password> [<type>] [<project>|<authority>]
+ projects <timestamp> <member> <password> [<authority>]
+ votes    <timestamp> <member> <password> [<action>|<project>]
+ trolls
