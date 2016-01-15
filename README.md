# wielder_of_anor
Checks a user's staged files for "forbidden" words (as determined by the user)
and, if any are found, alerts the user to the locations of said words.

## Longer Description
I am absent-minded. Very absent-minded. Absent-minded to the point that I'll
throw some "puts" or "console.log" commands into my code for debugging purposes
only to completely forget about them and then happily push all my code to
master branch without a care in the world. This...is not okay. Yet despite my
constant reminders to my brain that it most certainly is not okay, it keeps
quite happily forgetting everything about everything when it's time to commit
my code. And since I (apparently) can't magically fix the way my brain works, I
figured I'd make my computer double-check me since, you know, that is the entire
reason we invented computers to begin with. Enter Wielder of Anor.

Wielder of Anor is a quick and easy way to ensure that you aren't pushing your
code to production (or anywhere else it shouldn't be) with "forbidden words" you
don't want there. You yourself determine which words are forbidden, so this app
should be helpful to anyone wanting to prevent certain text from making it past
your dev environment. Maybe you're like me and you can never remember to pull
your debugging commands out of your code before committing. Maybe you're a code
master and commit swaths of code at a time, laughing at the mere mortals around
you who commit smaller chunks of work several times a day, and you can't be
bothered to check through your tens of thousands of lines of code to ensure you
didn't leave some debugging command in there somewhere. Or maybe your code gets
more and more filled with swear words the more frustrating a problem gets and
you just can't let one of those slip to production again because seriously it'd
be like the third or fourth time and you like working here and can't imagine
staying here if you slip up another time or two and...

Ahem. Sorry.

So. If you need to prevent anything in your code from making it past your dev
environment and need a reliable way to do this, use Wielder of Anor.

## Use
To use Wielder of Anor, just run it *from within your code directory* (this is
important). You can pass in a couple of arguments here:

* The first argument is your eventual commit message, if you've chosen to allow
  Wielder of Anor itself to run your commits for you.
* The second argument can only be '1'. If this argument is passed, Wielder of
  Anor will 
  
It'll run a bash command that'll export the result of a `git diff
HEAD` (so all files in your local branch that are different from git HEAD) to a
file. It'll then check every line in every one of those files for any of your
forbidden words and print out the locations of any it finds.

If it found none, you are good to go and can tell the app to then run the git

## Wielder of Anor? Wut.
You know, the thing Gandalf calls himself to the Balrog as he's all "YOU SHALL
NOT PASS!" over and over? When he's, you know, preventing the Balrog from
getting past him? He...he prevents a *forbidden* thing from...

A gatekeeper. This app is a gatekeeper. Gandalf was a Gatekeeper that one
time. It's artistic. Or something.

## License
The MIT License (MIT)

Copyright (c) 2016 Chris Sellek

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.