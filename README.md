# Political party management system

University databases course final project.

## API
+ open     &lt;database&gt; &lt;login&gt; &lt;password&gt;
+ leader   &lt;password&gt; &lt;member&gt;
+ support  &lt;timestamp&gt; &lt;member&gt; &lt;password&gt; &lt;action&gt; &lt;project&gt; [&lt;authority&gt;]
+ protest  &lt;timestamp&gt; &lt;member&gt; &lt;password&gt; &lt;action&gt; &lt;project&gt; [&lt;authority&gt;]
+ upvote   &lt;timestamp&gt; &lt;member&gt; &lt;password&gt; &lt;action&gt;
+ downvote &lt;timestamp&gt; &lt;member&gt; &lt;password&gt; &lt;action&gt;
+ actions  &lt;timestamp&gt; &lt;member&gt; &lt;password&gt; [&lt;type&gt;] [&lt;project&gt;|&lt;authority&gt;]
+ projects &lt;timestamp&gt; &lt;member&gt; &lt;password&gt; [&lt;authority&gt;]
+ votes    &lt;timestamp&gt; &lt;member&gt; &lt;password&gt; [&lt;action&gt;|&lt;project&gt;]
+ trolls
